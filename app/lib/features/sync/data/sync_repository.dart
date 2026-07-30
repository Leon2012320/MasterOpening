import 'package:dartchess/dartchess.dart' show Side;
import 'package:drift/drift.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/daos/key_value_dao.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/sync/data/session_store.dart';
import 'package:masteropening/features/sync/data/sync_api.dart';
import 'package:masteropening/features/sync/domain/sync_payload.dart';
import 'package:meta/meta.dart';

/// Was ein Abgleich bewegt hat.
@immutable
class SyncOutcome {
  const SyncOutcome({
    required this.pushedRepertoires,
    required this.pushedProgress,
    required this.pulledRepertoires,
    required this.pulledProgress,
    required this.conflicts,
    required this.at,
  });

  final int pushedRepertoires;
  final int pushedProgress;
  final int pulledRepertoires;
  final int pulledProgress;

  /// Repertoires, bei denen der Server die jüngere Fassung hatte. Sie sind
  /// jetzt lokal in der Serverfassung — die eigene Änderung ist weg.
  final int conflicts;

  final DateTime at;

  bool get changedNothing =>
      pushedRepertoires == 0 &&
      pushedProgress == 0 &&
      pulledRepertoires == 0 &&
      pulledProgress == 0;
}

/// Der Abgleich mit dem eigenen Server.
///
/// Die Reihenfolge ist bewusst erst hoch, dann herunter: so sieht der Server
/// die eigenen Änderungen, bevor er antwortet, und die Antwort enthält direkt
/// die aufgelösten Konflikte. Umgekehrt bräuchte es einen zweiten Umlauf.
class SyncRepository {
  SyncRepository({
    required this._db,
    SyncApi? api,
    SyncSessionStore? sessions,
  }) : _api = api ?? SyncApi(),
       _sessions = sessions ?? const SecureSyncSessionStore();

  final AppDatabase _db;
  final SyncApi _api;
  final SyncSessionStore _sessions;

  Future<bool> get isSignedIn async => await _sessions.read() != null;

  /// Meldet sich mit dem Lichess-Token beim eigenen Server an.
  Future<void> signIn(String lichessToken) async {
    await _sessions.write(await _api.signInWithLichess(lichessToken));
  }

  Future<void> signOut() async {
    await _sessions.clear();
    await _db.keyValueDao.remove(KeyValueDao.lastSyncAt);
  }

  /// Löscht das Serverkonto. Die lokalen Daten bleiben — wer sein Konto
  /// aufgibt, verliert damit nicht sein Repertoire auf dem Gerät.
  Future<void> deleteAccount() async {
    final session = await _requireSession();
    await _api.deleteAccount(session.accessToken);
    await signOut();
  }

  Future<SyncOutcome> sync() async {
    final since = await _db.keyValueDao.getDateTime(KeyValueDao.lastSyncAt);
    final payload = await _collectChanges(since: since);

    final push = await _withFreshToken(
      (token) => _api.push(payload, accessToken: token),
    );
    final pull = await _withFreshToken(
      (token) => _api.pull(accessToken: token, since: since),
    );

    final applied = await _applyIncoming(pull);

    await _db.keyValueDao.setDateTime(
      KeyValueDao.lastSyncAt,
      pull.serverTime,
    );

    return SyncOutcome(
      pushedRepertoires: push.appliedRepertoires,
      pushedProgress: push.appliedProgress,
      pulledRepertoires: applied.repertoires,
      pulledProgress: applied.progress,
      conflicts: push.conflictedRepertoires.length,
      at: pull.serverTime,
    );
  }

  // ── Hinauf ────────────────────────────────────────────────────────────────

  Future<PushPayload> _collectChanges({DateTime? since}) async {
    final allRepertoires = await _db.select(_db.repertoires).get();
    final uuidById = {for (final row in allRepertoires) row.id: row.uuid};

    final changedRepertoires = allRepertoires.where(
      (row) => since == null || row.updatedAt.isAfter(since),
    );

    final progressQuery = _db.select(_db.nodeProgress);
    if (since != null) {
      progressQuery.where((p) => p.updatedAt.isBiggerThanValue(since));
    }
    final progressRows = await progressQuery.get();

    final profile = await _db.activityDao.profile();

    return PushPayload(
      repertoires: [
        for (final row in changedRepertoires)
          RepertoireDto(
            uuid: row.uuid,
            name: row.name,
            side: row.side.name,
            pgn: row.pgn,
            startFen: row.startFen,
            ecoCodes: row.ecoCodes,
            source: row.source.name,
            sourceRef: row.sourceRef,
            sortOrder: row.sortOrder,
            isArchived: row.isArchived,
            nodeCount: row.nodeCount,
            lineCount: row.lineCount,
            revision: row.revision,
            updatedAt: row.updatedAt,
            deletedAt: row.deletedAt,
          ),
      ],
      progress: [
        for (final row in progressRows)
          // Ein Fortschritt ohne sein Repertoire hat auf dem Server keinen
          // Anker; das kommt nur bei halb aufgeräumten Daten vor.
          if (uuidById[row.repertoireId] case final uuid?)
            ProgressDto(
              repertoireUuid: uuid,
              pathHash: row.pathHash,
              state: row.state.name,
              stability: row.stability,
              difficulty: row.difficulty,
              due: row.due,
              lastReview: row.lastReview,
              reps: row.reps,
              lapses: row.lapses,
              correctCount: row.correctCount,
              wrongCount: row.wrongCount,
              updatedAt: row.updatedAt,
            ),
      ],
      profile: since == null || profile.updatedAt.isAfter(since)
          ? ProfileDto(
              totalXp: profile.totalXp,
              streakCurrent: profile.streakCurrent,
              streakBest: profile.streakBest,
              streakFreezes: profile.streakFreezes,
              lastActiveDay: profile.lastActiveDay,
              updatedAt: profile.updatedAt,
            )
          : null,
    );
  }

  // ── Herunter ──────────────────────────────────────────────────────────────

  Future<({int repertoires, int progress})> _applyIncoming(
    PullResponse pull,
  ) async {
    var repertoires = 0;
    var progress = 0;

    for (final dto in pull.repertoires) {
      if (await _applyRepertoire(dto)) repertoires++;
    }

    // Erst danach die Zuordnung bauen: die Repertoires aus demselben Abgleich
    // sollen für ihren Lernstand schon dastehen.
    final uuidToId = {
      for (final row in await _db.select(_db.repertoires).get())
        row.uuid: row.id,
    };

    for (final dto in pull.progress) {
      final localId = uuidToId[dto.repertoireUuid];
      if (localId == null) continue;
      if (await _applyProgress(dto, localId)) progress++;
    }

    if (pull.profile case final incoming?) {
      await _applyProfile(incoming);
    }

    return (repertoires: repertoires, progress: progress);
  }

  Future<bool> _applyRepertoire(RepertoireDto dto) async {
    final existing = await _db.repertoireDao.getByUuid(dto.uuid);

    if (existing == null) {
      // Ein Grabstein ohne lokale Entsprechung ist nichts zu tun.
      if (dto.deletedAt != null) return false;

      await _db
          .into(_db.repertoires)
          .insert(
            RepertoiresCompanion.insert(
              uuid: dto.uuid,
              createdAt: dto.updatedAt,
              updatedAt: dto.updatedAt,
              name: dto.name,
              side: _sideOf(dto.side),
              pgn: dto.pgn,
              startFen: dto.startFen,
              source: _sourceOf(dto.source),
              sourceRef: Value(dto.sourceRef),
              ecoCodes: Value(dto.ecoCodes),
              sortOrder: Value(dto.sortOrder),
              isArchived: Value(dto.isArchived),
              nodeCount: Value(dto.nodeCount),
              lineCount: Value(dto.lineCount),
              revision: Value(dto.revision),
            ),
          );
      return true;
    }

    if (!_incomingWins(
      incomingAt: dto.updatedAt,
      incomingRevision: dto.revision,
      existingAt: existing.updatedAt,
      existingRevision: existing.revision,
    )) {
      return false;
    }

    await (_db.update(
      _db.repertoires,
    )..where((r) => r.id.equals(existing.id))).write(
      RepertoiresCompanion(
        name: Value(dto.name),
        side: Value(_sideOf(dto.side)),
        pgn: Value(dto.pgn),
        startFen: Value(dto.startFen),
        ecoCodes: Value(dto.ecoCodes),
        source: Value(_sourceOf(dto.source)),
        sourceRef: Value(dto.sourceRef),
        sortOrder: Value(dto.sortOrder),
        isArchived: Value(dto.isArchived),
        nodeCount: Value(dto.nodeCount),
        lineCount: Value(dto.lineCount),
        revision: Value(dto.revision),
        updatedAt: Value(dto.updatedAt),
        deletedAt: Value(dto.deletedAt),
      ),
    );
    return true;
  }

  Future<bool> _applyProgress(ProgressDto dto, int repertoireId) async {
    final existing = await _db.progressDao.getOne(repertoireId, dto.pathHash);

    if (existing != null && !dto.updatedAt.isAfter(existing.updatedAt)) {
      return false;
    }

    await _db.progressDao.upsert(
      NodeProgressData(
        repertoireId: repertoireId,
        pathHash: dto.pathHash,
        state: _stateOf(dto.state),
        stability: dto.stability,
        difficulty: dto.difficulty,
        due: dto.due,
        lastReview: dto.lastReview,
        reps: dto.reps,
        lapses: dto.lapses,
        correctCount: dto.correctCount,
        wrongCount: dto.wrongCount,
        updatedAt: dto.updatedAt,
      ),
    );
    return true;
  }

  Future<void> _applyProfile(ProfileDto dto) async {
    final existing = await _db.activityDao.profile();
    if (!dto.updatedAt.isAfter(existing.updatedAt)) return;

    await _db.activityDao.updateProfile(
      UserProfilesCompanion(
        totalXp: Value(dto.totalXp),
        streakCurrent: Value(dto.streakCurrent),
        streakBest: Value(dto.streakBest),
        streakFreezes: Value(dto.streakFreezes),
        lastActiveDay: Value(dto.lastActiveDay),
      ),
    );
  }

  // ── Kleinkram ─────────────────────────────────────────────────────────────

  /// Dieselbe Regel wie auf dem Server: der jüngere Stand gewinnt, bei
  /// gleicher Zeit die höhere Revision. Sie steht an beiden Enden, damit
  /// nicht je nach Richtung etwas anderes herauskommt.
  static bool _incomingWins({
    required DateTime incomingAt,
    required int incomingRevision,
    required DateTime existingAt,
    required int existingRevision,
  }) {
    final delta = incomingAt.difference(existingAt);
    if (delta != Duration.zero) return delta > Duration.zero;
    return incomingRevision > existingRevision;
  }

  /// Führt eine Anfrage aus und erneuert bei abgelehntem Token einmal.
  Future<T> _withFreshToken<T>(
    Future<T> Function(String accessToken) request,
  ) async {
    final session = await _requireSession();

    try {
      return await request(session.accessToken);
    } on SyncException catch (error) {
      if (!error.isAuthFailure) rethrow;

      final renewed = await _api.refresh(session.refreshToken);
      await _sessions.write(renewed);
      return request(renewed.accessToken);
    }
  }

  Future<SyncSession> _requireSession() async {
    final session = await _sessions.read();
    if (session == null) {
      throw const SyncException(
        'Nicht angemeldet',
        isAuthFailure: true,
      );
    }
    return session;
  }

  /// Unbekannte Werte vom Server dürfen den Abgleich nicht sprengen: lieber
  /// ein plausibler Rückfall als eine Ausnahme mitten im Schreiben.
  static Side _sideOf(String name) =>
      Side.values.firstWhere((s) => s.name == name, orElse: () => Side.white);

  static RepertoireSource _sourceOf(String name) =>
      RepertoireSource.values.firstWhere(
        (s) => s.name == name,
        orElse: () => RepertoireSource.manual,
      );

  static FsrsState _stateOf(String name) => FsrsState.values.firstWhere(
    (s) => s.name == name,
    orElse: () => FsrsState.newCard,
  );
}
