import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/daos/key_value_dao.dart';
import 'package:masteropening/features/lichess/data/lichess_api.dart';
import 'package:masteropening/features/lichess/data/lichess_repository.dart';
import 'package:masteropening/features/lichess/data/lichess_token_store.dart';
import 'package:masteropening/features/lichess/domain/lichess_account.dart';

import 'lichess_test.dart' show gameJson;

/// Eine API, die nichts über das Netz tut.
class _FakeApi extends LichessApi {
  _FakeApi() : games = const [];

  List<Map<String, dynamic>> games;

  String? exchangedCode;
  String? exchangedVerifier;
  DateTime? lastSince;
  String? revokedToken;
  int accountCalls = 0;

  static final account_ = LichessAccount.fromJson(const {
    'id': 'leon',
    'username': 'Leon',
    'count': {'all': 12},
    'perfs': {
      'blitz': {'games': 12, 'rating': 1700},
    },
  });

  @override
  Future<String> exchangeCode({
    required String code,
    required String verifier,
  }) async {
    exchangedCode = code;
    exchangedVerifier = verifier;
    return 'token-123';
  }

  @override
  Future<LichessAccount> account(String token) async {
    accountCalls++;
    return account_;
  }

  @override
  Stream<Map<String, dynamic>> streamGames({
    required String token,
    required String username,
    DateTime? since,
    int max = 300,
  }) {
    lastSince = since;
    return Stream.fromIterable(games);
  }

  @override
  Future<void> revoke(String token) async => revokedToken = token;
}

void main() {
  late AppDatabase db;
  late _FakeApi api;
  late InMemoryLichessTokenStore tokens;
  late LichessRepository repo;

  /// Spielt den Browser: gibt die Rückleitung zurück, die Lichess schicken
  /// würde — mit demselben Zustandswert, den die App gerade erzeugt hat.
  Future<String> fakeBrowser({
    required Uri url,
    required String callbackScheme,
  }) async {
    final state = url.queryParameters['state'];
    return '$callbackScheme://oauth/lichess?code=auth-code&state=$state';
  }

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    api = _FakeApi();
    tokens = InMemoryLichessTokenStore();
    repo = LichessRepository(
      db: db,
      api: api,
      tokens: tokens,
      browser: fakeBrowser,
    );
  });

  tearDown(() => db.close());

  group('Verbinden', () {
    test('tauscht den Code, merkt sich Token und Profil', () async {
      final account = await repo.connect();

      expect(account.username, 'Leon');
      expect(api.exchangedCode, 'auth-code');
      expect(api.exchangedVerifier, isNotEmpty);
      expect(await tokens.read(), 'token-123');

      // Das Profil liegt lokal — der Tab steht auch ohne Netz.
      final cached = await repo.cachedAccount();
      expect(cached!.username, 'Leon');
      expect((await db.activityDao.profile()).lichessUsername, 'Leon');
    });

    test('ohne Token ist der Import ein Fehler', () async {
      expect(repo.importGames(), throwsA(isA<Exception>()));
    });
  });

  group('Import', () {
    setUp(() async {
      await repo.connect();
    });

    test('speichert Partien und überspringt, was nicht zählt', () async {
      api.games = [
        gameJson(id: 'g1'),
        gameJson(id: 'g2', winner: null, status: 'draw'),
        gameJson(id: 'g3', status: 'aborted'),
        gameJson(id: 'g4', variant: 'atomic'),
      ];

      final result = await repo.importGames();

      expect(result.imported, 2);
      expect(result.skipped, 2);
      expect(result.total, 2);
      expect(await db.lichessDao.count(), 2);
    });

    test('setzt die Marke und fragt beim zweiten Mal nur nach Neuem', () async {
      api.games = [gameJson(id: 'g1')];
      await repo.importGames();

      final mark = await db.keyValueDao.getDateTime(
        KeyValueDao.lichessImportedUntil,
      );
      expect(mark, DateTime(2026, 7, 20));

      await repo.importGames();
      expect(api.lastSince, isNotNull);
      expect(api.lastSince!.isBefore(DateTime(2026, 7, 20)), isTrue);
    });

    test('dieselbe Partie zweimal bleibt eine Zeile', () async {
      api.games = [gameJson(id: 'g1')];

      await repo.importGames();
      await repo.importGames();

      expect(await db.lichessDao.count(), 1);
    });

    test(
      'holt das Profil nicht erneut, solange es zwischengespeichert ist',
      () async {
        final before = api.accountCalls;
        await repo.importGames();

        expect(api.accountCalls, before);
      },
    );
  });

  group('Trennen', () {
    test('zieht das Token zurück und räumt lokal auf', () async {
      await repo.connect();
      api.games = [gameJson(id: 'g1')];
      await repo.importGames();

      await repo.disconnect();

      expect(api.revokedToken, 'token-123');
      expect(await tokens.read(), isNull);
      expect(await repo.cachedAccount(), isNull);
      expect(await db.lichessDao.count(), 0);
      expect((await db.activityDao.profile()).lichessUsername, isNull);
      expect(
        await db.keyValueDao.getDateTime(KeyValueDao.lichessImportedUntil),
        isNull,
      );
    });
  });
}
