import 'package:drift/drift.dart' show Value;
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/daos/activity_dao.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/gamification/domain/achievement.dart';
import 'package:masteropening/features/gamification/domain/challenge.dart';
import 'package:masteropening/features/gamification/domain/level_system.dart';
import 'package:masteropening/features/gamification/domain/streak.dart';
import 'package:meta/meta.dart';

/// Alles, was nach einer Trainingseinheit an Belohnung anfällt.
@immutable
class GamificationOutcome {
  const GamificationOutcome({
    required this.xpGained,
    required this.levelBefore,
    required this.levelAfter,
    required this.unlockedAchievements,
    required this.completedChallenges,
    required this.streak,
  });

  final int xpGained;
  final int levelBefore;
  final int levelAfter;

  final List<Achievement> unlockedAchievements;
  final List<ChallengeInstance> completedChallenges;
  final StreakState streak;

  bool get didLevelUp => levelAfter > levelBefore;

  bool get hasSomethingToCelebrate =>
      didLevelUp ||
      unlockedAchievements.isNotEmpty ||
      completedChallenges.isNotEmpty;
}

/// Führt XP, Level, Serie, Erfolge und Aufgaben nach.
///
/// Die Rechenregeln stehen im Domänenteil und kennen keine Datenbank; hier
/// werden nur die Kennzahlen zusammengetragen und die Ergebnisse geschrieben.
class GamificationRepository {
  GamificationRepository(this._db);

  final AppDatabase _db;

  /// Die Kennzahlen, gegen die die Erfolge geprüft werden.
  Future<Map<AchievementMetric, int>> metrics({DateTime? now}) async {
    final today = now ?? DateTime.now();

    final days = await _db.select(_db.activityDays).get();
    final sessions = await _db.trainingDao.recentSessions(limit: 100000);
    final repertoires = await _db.repertoireDao.getAll();
    final profile = await _db.activityDao.profile();
    final games = await _db.select(_db.lichessGames).get();

    final streak = StreakCalculator.evaluate(
      activeDays: days.map((d) => d.day).toSet(),
      today: today,
      bestSoFar: profile.streakBest,
    );

    final trapSessions = sessions.where((s) => s.mode == TrainingMode.trap);

    return {
      AchievementMetric.movesTrained: days.fold(
        0,
        (sum, d) => sum + d.movesTrained,
      ),
      AchievementMetric.sessions: sessions.length,
      AchievementMetric.bestStreak: streak.best,
      AchievementMetric.linesMastered: days.fold(
        0,
        (sum, d) => sum + d.linesMastered,
      ),
      AchievementMetric.repertoires: repertoires.length,
      AchievementMetric.perfectSessions: sessions
          .where((s) => s.movesTotal > 0 && s.movesCorrect == s.movesTotal)
          .length,
      AchievementMetric.studyMinutes:
          days.fold(0, (sum, d) => sum + d.secondsStudied) ~/ 60,
      AchievementMetric.level: LevelSystem.progressFor(profile.totalXp).level,
      // Eine widerlegte Falle ist eine fehlerfrei gespielte Variante im
      // Fallen-Modus.
      AchievementMetric.trapsRefuted: trapSessions.fold(
        0,
        (sum, s) => sum + s.linesMastered,
      ),
      AchievementMetric.lichessGames: games.length,
    };
  }

  Future<StreakState> streak({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final days = await _db.select(_db.activityDays).get();
    final profile = await _db.activityDao.profile();

    return StreakCalculator.evaluate(
      activeDays: days.map((d) => d.day).toSet(),
      today: today,
      bestSoFar: profile.streakBest,
    );
  }

  /// Schreibt Punkte, Level, Serie, neue Erfolge und Aufgabenfortschritt fort.
  ///
  /// Wird nach jeder Trainingseinheit aufgerufen. Die Punkte der Einheit sind
  /// zu diesem Zeitpunkt schon im Tageswert; hier kommen die Boni für neu
  /// freigeschaltete Erfolge und erledigte Aufgaben dazu.
  Future<GamificationOutcome> applySession({
    required int xpFromSession,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();

    return _db.transaction(() async {
      final profile = await _db.activityDao.profile();
      final levelBefore = LevelSystem.progressFor(profile.totalXp).level;

      final streakState = await streak(now: today);
      final challenges = await _refreshChallenges(now: today);
      final justCompleted = challenges
          .where((c) => c.isComplete && c.completedAt == null)
          .toList();

      final unlockedRows = await _db.select(_db.achievementProgress).get();
      final alreadyUnlocked = unlockedRows
          .where((r) => r.unlockedAt != null)
          .map((r) => r.achievementId)
          .toSet();

      // Der Levelstand für die Erfolgsprüfung berücksichtigt die Punkte der
      // Einheit schon, sonst hinkte „Level 10 erreicht" eine Einheit hinterher.
      final xpWithSession = profile.totalXp + xpFromSession;
      final currentMetrics = await metrics(now: today);
      currentMetrics[AchievementMetric.level] = LevelSystem.progressFor(
        xpWithSession,
      ).level;

      final unlocked = Achievements.newlyUnlocked(
        metrics: currentMetrics,
        alreadyUnlocked: alreadyUnlocked,
      );

      final bonusXp =
          unlocked.fold<int>(0, (sum, a) => sum + a.xpReward) +
          justCompleted.fold<int>(0, (sum, c) => sum + c.template.xpReward);

      final totalXp = xpWithSession + bonusXp;

      await _db.activityDao.updateProfile(
        UserProfilesCompanion(
          totalXp: Value(totalXp),
          streakCurrent: Value(streakState.current),
          streakBest: Value(streakState.best),
          streakFreezes: Value(streakState.freezesLeft),
          lastActiveDay: Value(ActivityDao.dayKey(today)),
        ),
      );

      for (final achievement in unlocked) {
        await _db
            .into(_db.achievementProgress)
            .insertOnConflictUpdate(
              AchievementProgressData(
                achievementId: achievement.id,
                progress: achievement.threshold,
                unlockedAt: today,
                seen: false,
                updatedAt: today,
              ),
            );
      }

      for (final challenge in justCompleted) {
        await _db
            .into(_db.challenges)
            .insertOnConflictUpdate(
              Challenge(
                id: challenge.id,
                kind: challenge.template.kind,
                type: challenge.template.type,
                periodKey: challenge.periodKey,
                target: challenge.template.target,
                progress: challenge.progress,
                xpReward: challenge.template.xpReward,
                completedAt: today,
                claimed: true,
              ),
            );
      }

      return GamificationOutcome(
        xpGained: xpFromSession + bonusXp,
        levelBefore: levelBefore,
        levelAfter: LevelSystem.progressFor(totalXp).level,
        unlockedAchievements: unlocked,
        completedChallenges: justCompleted,
        streak: streakState,
      );
    });
  }

  /// Legt die Aufgaben des Tages und der Woche an, falls nötig, und bringt
  /// ihren Fortschritt auf den Stand.
  Future<List<ChallengeInstance>> _refreshChallenges({
    required DateTime now,
  }) async {
    final dayKey = Challenges.dayKey(now);
    final weekKey = Challenges.weekKey(now);

    final days = await _db.select(_db.activityDays).get();
    final today = days.where((d) => d.day == dayKey).firstOrNull;
    final weekDays = days
        .where((d) => Challenges.weekKey(DateTime.parse(d.day)) == weekKey)
        .toList();

    final existing = {
      for (final row in await _db.select(_db.challenges).get()) row.id: row,
    };

    final result = <ChallengeInstance>[];

    for (final (kind, periodKey) in [
      (ChallengeKind.daily, dayKey),
      (ChallengeKind.weekly, weekKey),
    ]) {
      for (final template in Challenges.pick(
        kind: kind,
        periodKey: periodKey,
      )) {
        final progress = _progressFor(
          metric: template.metric,
          today: today,
          week: weekDays,
          kind: kind,
        );

        final instance = ChallengeInstance(
          template: template,
          periodKey: periodKey,
          progress: progress,
          completedAt:
              existing['${kind.name}:$periodKey:${template.type}']?.completedAt,
        );
        result.add(instance);

        await _db
            .into(_db.challenges)
            .insertOnConflictUpdate(
              Challenge(
                id: instance.id,
                kind: kind,
                type: template.type,
                periodKey: periodKey,
                target: template.target,
                progress: progress,
                xpReward: template.xpReward,
                completedAt: instance.completedAt,
                claimed: instance.completedAt != null,
              ),
            );
      }
    }

    return result;
  }

  static int _progressFor({
    required ChallengeMetric metric,
    required ActivityDay? today,
    required List<ActivityDay> week,
    required ChallengeKind kind,
  }) {
    final rows = kind == ChallengeKind.daily ? [?today] : week;

    return switch (metric) {
      ChallengeMetric.moves => rows.fold(0, (s, d) => s + d.movesTrained),
      ChallengeMetric.correctMoves => rows.fold(
        0,
        (s, d) => s + d.movesCorrect,
      ),
      ChallengeMetric.sessions => rows.fold(0, (s, d) => s + d.sessions),
      ChallengeMetric.masteredLines => rows.fold(
        0,
        (s, d) => s + d.linesMastered,
      ),
      ChallengeMetric.minutes =>
        rows.fold(0, (s, d) => s + d.secondsStudied) ~/ 60,
      ChallengeMetric.activeDays => rows.where((d) => d.sessions > 0).length,
    };
  }

  /// Die Aufgaben für die Anzeige — ohne etwas zu verbuchen.
  Future<List<ChallengeInstance>> currentChallenges({DateTime? now}) =>
      _refreshChallenges(now: now ?? DateTime.now());

  /// Der Stand aller Erfolge.
  Future<List<AchievementStatus>> achievements({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final rows = await _db.select(_db.achievementProgress).get();

    return Achievements.evaluate(
      metrics: await metrics(now: today),
      unlocked: {
        for (final row in rows)
          if (row.unlockedAt != null) row.achievementId: row.unlockedAt!,
      },
      now: today,
    );
  }

  /// Markiert die Freischalt-Animation als gezeigt.
  Future<void> markSeen(Iterable<String> achievementIds) async {
    for (final id in achievementIds) {
      await (_db.update(_db.achievementProgress)
            ..where((a) => a.achievementId.equals(id)))
          .write(const AchievementProgressCompanion(seen: Value(true)));
    }
  }
}
