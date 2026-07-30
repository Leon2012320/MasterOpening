import 'package:dartchess/dartchess.dart' show Side;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/daos/key_value_dao.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/sync/data/session_store.dart';
import 'package:masteropening/features/sync/data/sync_api.dart';
import 'package:masteropening/features/sync/data/sync_repository.dart';
import 'package:masteropening/features/sync/domain/sync_payload.dart';

/// Ein Server im Arbeitsspeicher, der sich an dieselbe Konfliktregel hält.
class _FakeApi extends SyncApi {
  _FakeApi() : super(baseUrl: 'https://test.invalid');

  final Map<String, RepertoireDto> repertoires = {};
  final Map<String, ProgressDto> progress = {};
  ProfileDto? profile;

  DateTime serverTime = DateTime.utc(2026, 7, 30, 12);

  PushPayload? lastPush;
  DateTime? lastSince;
  int refreshCalls = 0;

  /// Lehnt das erste Zugriffstoken ab — dann muss der Aufrufer erneuern.
  bool rejectFirstCall = false;
  bool _rejected = false;

  void _checkToken() {
    if (rejectFirstCall && !_rejected) {
      _rejected = true;
      throw const SyncException('abgelaufen', isAuthFailure: true);
    }
  }

  @override
  Future<SyncSession> signInWithLichess(String lichessToken) async =>
      const SyncSession(accessToken: 'zugriff', refreshToken: 'erneuerung');

  @override
  Future<SyncSession> refresh(String refreshToken) async {
    refreshCalls++;
    return const SyncSession(
      accessToken: 'zugriff-neu',
      refreshToken: 'erneuerung-neu',
    );
  }

  @override
  Future<PushResponse> push(
    PushPayload payload, {
    required String accessToken,
  }) async {
    _checkToken();
    lastPush = payload;

    var applied = 0;
    final conflicts = <String>[];

    for (final dto in payload.repertoires) {
      final existing = repertoires[dto.uuid];
      final wins =
          existing == null ||
          dto.updatedAt.isAfter(existing.updatedAt) ||
          (dto.updatedAt == existing.updatedAt &&
              dto.revision >= existing.revision);

      if (wins) {
        repertoires[dto.uuid] = dto;
        applied++;
      } else {
        conflicts.add(dto.uuid);
      }
    }

    // Auch hier gilt die Regel des echten Servers: der jüngere Stand bleibt.
    for (final dto in payload.progress) {
      final key = '${dto.repertoireUuid}|${dto.pathHash}';
      final existing = progress[key];
      if (existing == null || dto.updatedAt.isAfter(existing.updatedAt)) {
        progress[key] = dto;
      }
    }

    if (payload.profile case final incoming?) {
      final existing = profile;
      if (existing == null || incoming.updatedAt.isAfter(existing.updatedAt)) {
        profile = incoming;
      }
    }

    return PushResponse(
      serverTime: serverTime,
      appliedRepertoires: applied,
      appliedProgress: payload.progress.length,
      conflictedRepertoires: conflicts,
    );
  }

  @override
  Future<PullResponse> pull({
    required String accessToken,
    DateTime? since,
  }) async {
    _checkToken();
    lastSince = since;

    return PullResponse(
      serverTime: serverTime,
      repertoires: repertoires.values.toList(),
      progress: progress.values.toList(),
      profile: profile,
    );
  }
}

void main() {
  late AppDatabase db;
  late _FakeApi api;
  late InMemorySyncSessionStore sessions;
  late SyncRepository repo;

  setUp(() async {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    api = _FakeApi();
    sessions = InMemorySyncSessionStore();
    repo = SyncRepository(db: db, api: api, sessions: sessions);

    await repo.signIn('lichess-token');
  });

  tearDown(() => db.close());

  Future<int> addRepertoire({
    String uuid = 'repertoire-0001',
    String name = 'Sizilianisch',
    DateTime? at,
  }) {
    return db.repertoireDao.insertRepertoire(
      uuid: uuid,
      name: name,
      side: Side.black,
      pgn: '[Event "?"]\n\n1. e4 c5 *',
      startFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      source: RepertoireSource.manual,
      nodeCount: 2,
      lineCount: 1,
      now: at ?? DateTime.utc(2026, 7, 29),
    );
  }

  group('Anmeldung', () {
    test('legt die Sitzung ab', () async {
      expect(await repo.isSignedIn, isTrue);
      expect((await sessions.read())!.accessToken, 'zugriff');
    });

    test('Abmelden räumt Sitzung und Marke weg', () async {
      await addRepertoire();
      await repo.sync();

      await repo.signOut();

      expect(await repo.isSignedIn, isFalse);
      expect(
        await db.keyValueDao.getDateTime(KeyValueDao.lastSyncAt),
        isNull,
      );
    });

    test('ohne Sitzung ist der Abgleich ein Fehler', () async {
      await repo.signOut();
      expect(repo.sync(), throwsA(isA<SyncException>()));
    });
  });

  group('Hinauf', () {
    test('schickt Repertoire, Lernstand und Spielerstand', () async {
      final id = await addRepertoire();
      await db.progressDao.ensureRows(
        repertoireId: id,
        pathHashes: ['a' * 40],
        now: DateTime.utc(2026, 7, 29),
      );

      final outcome = await repo.sync();

      expect(outcome.pushedRepertoires, 1);
      expect(outcome.pushedProgress, 1);
      expect(api.repertoires.keys, contains('repertoire-0001'));

      // Der Lernstand reist über die uuid, nicht über die lokale Zeilen-ID.
      final sent = api.lastPush!.progress.single;
      expect(sent.repertoireUuid, 'repertoire-0001');
      expect(sent.pathHash, 'a' * 40);
    });

    test('beim zweiten Mal geht nur Neues hinaus', () async {
      await addRepertoire();
      await repo.sync();

      final second = await repo.sync();

      expect(second.pushedRepertoires, 0);
      expect(api.lastPush!.repertoires, isEmpty);
      expect(api.lastSince, isNotNull);
    });

    test('eine Änderung danach geht wieder mit', () async {
      final id = await addRepertoire();
      await repo.sync();

      await db.repertoireDao.rename(id, 'Sizilianisch Najdorf');
      final outcome = await repo.sync();

      expect(outcome.pushedRepertoires, 1);
      expect(api.repertoires['repertoire-0001']!.name, 'Sizilianisch Najdorf');
    });

    test('ein gelöschtes Repertoire reist als Grabstein', () async {
      final id = await addRepertoire();
      await repo.sync();

      await db.repertoireDao.softDelete(id);
      await repo.sync();

      expect(api.repertoires['repertoire-0001']!.deletedAt, isNotNull);
    });
  });

  group('Herunter', () {
    test('legt ein fremdes Repertoire lokal an', () async {
      api.repertoires['vom-anderen-geraet'] = RepertoireDto(
        uuid: 'vom-anderen-geraet',
        name: 'Englisch',
        side: 'white',
        pgn: '[Event "?"]\n\n1. c4 *',
        startFen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        source: 'manual',
        revision: 1,
        updatedAt: DateTime.utc(2026, 7, 30),
      );

      final outcome = await repo.sync();

      expect(outcome.pulledRepertoires, 1);
      final local = await db.repertoireDao.getByUuid('vom-anderen-geraet');
      expect(local!.name, 'Englisch');
      expect(local.side, Side.white);
    });

    test('ein älterer Serverstand überschreibt nichts', () async {
      final id = await addRepertoire(at: DateTime.utc(2026, 7, 31));
      final local = (await db.repertoireDao.getById(id))!;

      api.repertoires['repertoire-0001'] = RepertoireDto(
        uuid: local.uuid,
        name: 'alte Fassung',
        side: 'black',
        pgn: local.pgn,
        startFen: local.startFen,
        source: 'manual',
        updatedAt: DateTime.utc(2026, 7),
      );

      await repo.sync();

      expect((await db.repertoireDao.getById(id))!.name, 'Sizilianisch');
    });

    test('der Lernstand landet am richtigen Repertoire', () async {
      await addRepertoire();

      api.progress['repertoire-0001|${'b' * 40}'] = ProgressDto(
        repertoireUuid: 'repertoire-0001',
        pathHash: 'b' * 40,
        state: 'review',
        stability: 7.5,
        difficulty: 5,
        due: DateTime.utc(2026, 8, 5),
        reps: 4,
        lapses: 1,
        correctCount: 4,
        wrongCount: 1,
        updatedAt: DateTime.utc(2026, 7, 30),
      );

      final outcome = await repo.sync();
      expect(outcome.pulledProgress, 1);

      final id = (await db.repertoireDao.getByUuid('repertoire-0001'))!.id;
      final row = await db.progressDao.getOne(id, 'b' * 40);
      expect(row!.stability, 7.5);
      expect(row.state, FsrsState.review);
    });

    test('Lernstand ohne bekanntes Repertoire wird übergangen', () async {
      api.progress['fremd|${'c' * 40}'] = ProgressDto(
        repertoireUuid: 'gibt-es-nicht',
        pathHash: 'c' * 40,
        state: 'review',
        stability: 1,
        difficulty: 5,
        due: DateTime.utc(2026, 8, 5),
        reps: 1,
        lapses: 0,
        correctCount: 1,
        wrongCount: 0,
        updatedAt: DateTime.utc(2026, 7, 30),
      );

      final outcome = await repo.sync();
      expect(outcome.pulledProgress, 0);
    });

    test('übernimmt einen jüngeren Spielerstand', () async {
      api.profile = ProfileDto(
        totalXp: 5000,
        streakCurrent: 9,
        streakBest: 14,
        streakFreezes: 2,
        lastActiveDay: '2026-07-30',
        updatedAt: DateTime.utc(2027),
      );

      await repo.sync();

      final profile = await db.activityDao.profile();
      expect(profile.totalXp, 5000);
      expect(profile.streakBest, 14);
    });

    test('ein älterer Spielerstand bleibt liegen', () async {
      await db.activityDao.updateProfile(
        const UserProfilesCompanion(totalXp: Value(999)),
      );

      api.profile = ProfileDto(
        totalXp: 1,
        streakCurrent: 0,
        streakBest: 0,
        streakFreezes: 2,
        updatedAt: DateTime.utc(2020),
      );

      await repo.sync();

      expect((await db.activityDao.profile()).totalXp, 999);
    });
  });

  group('Abgelaufenes Token', () {
    test('wird einmal erneuert, danach läuft der Abgleich durch', () async {
      await addRepertoire();
      api.rejectFirstCall = true;

      final outcome = await repo.sync();

      expect(api.refreshCalls, 1);
      expect(outcome.pushedRepertoires, 1);
      expect((await sessions.read())!.accessToken, 'zugriff-neu');
    });
  });
}
