import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/daos/activity_dao.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/gamification/data/gamification_repository.dart';
import 'package:masteropening/features/gamification/domain/achievement.dart';
import 'package:masteropening/features/gamification/domain/challenge.dart';
import 'package:masteropening/features/gamification/domain/level_system.dart';
import 'package:masteropening/features/gamification/domain/streak.dart';
import 'package:masteropening/features/gamification/presentation/achievements_screen.dart';
import 'package:masteropening/features/gamification/presentation/stats_screen.dart';
import 'package:masteropening/features/gamification/presentation/widgets/celebration_overlay.dart';
import 'package:masteropening/features/gamification/presentation/widgets/challenge_card.dart';

import '../helpers/pump_app.dart';

/// Ein Tageswert, wie ihn das Training hinterlässt.
ActivityDay _day(DateTime date, {int moves = 20, int seconds = 600}) {
  return ActivityDay(
    day: ActivityDao.dayKey(date),
    xp: moves * 2,
    movesTrained: moves,
    movesCorrect: moves,
    secondsStudied: seconds,
    sessions: 1,
    linesMastered: 1,
  );
}

TrainingSession _session({required int total, required int correct}) {
  final now = DateTime(2026, 7, 30, 18);
  return TrainingSession(
    id: total,
    uuid: 'session-$total-$correct',
    createdAt: now,
    updatedAt: now,
    revision: 0,
    mode: TrainingMode.smart,
    startedAt: now,
    endedAt: now.add(const Duration(minutes: 6)),
    movesTotal: total,
    movesCorrect: correct,
    linesLearned: 2,
    linesMastered: 1,
    xpEarned: 60,
    durationSeconds: 360,
  );
}

void main() {
  const today = 20;

  group('Statistik-Bildschirm', () {
    testWidgets('zeigt Level, Serie und Lernzeit', (tester) async {
      final now = DateTime(2026, 7, 30);

      await pumpWidgetInApp(
        tester,
        StatsView(
          totalXp: LevelSystem.xpToReach(5) + 10,
          days: [
            for (var i = 0; i < 3; i++)
              _day(now.subtract(Duration(days: i)), seconds: 3600),
          ],
          sessions: [_session(total: 20, correct: 18)],
          challenges: const [],
          streak: const StreakState(
            current: 3,
            best: 12,
            freezesLeft: 1,
            activeToday: true,
            usedFreezeDays: {},
          ),
        ),
      );

      expect(find.text('Level 5'), findsOneWidget);
      expect(find.text('12'), findsOneWidget, reason: 'Bestwert der Serie');
      expect(find.text('3 h 0 min'), findsOneWidget);
    });

    testWidgets('erklärt sich, solange nichts trainiert wurde', (tester) async {
      await pumpWidgetInApp(
        tester,
        const StatsView(
          totalXp: 0,
          days: [],
          sessions: [],
          challenges: [],
        ),
      );

      expect(find.text('Noch keine Zahlen'), findsOneWidget);
    });

    testWidgets('listet Tages- und Wochenaufgaben', (tester) async {
      // Ein hohes Fenster: die Aufgaben stehen unter Levelkarte, Kacheln und
      // Heatmap, und eine ListView baut nur, was sichtbar ist.
      await tester.binding.setSurfaceSize(const Size(600, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final challenges = [
        ChallengeInstance(
          template: Challenges.daily.first,
          periodKey: '2026-07-30',
          progress: 12,
        ),
        ChallengeInstance(
          template: Challenges.weekly.first,
          periodKey: '2026-W31',
          progress: 120,
        ),
      ];

      await pumpWidgetInApp(
        tester,
        StatsView(
          totalXp: 100,
          days: [_day(DateTime(2026, 7, 30))],
          sessions: const [],
          challenges: challenges,
        ),
      );

      expect(find.text('Heute'), findsOneWidget);
      expect(find.text('Diese Woche'), findsOneWidget);
      expect(find.byType(ChallengeCard), findsNWidgets(2));
    });
  });

  group('Erfolge-Bildschirm', () {
    testWidgets('zählt freigeschaltete Erfolge und zeigt auch die offenen', (
      tester,
    ) async {
      final unlockedAt = DateTime(2026, 7, 29);
      final statuses = [
        AchievementStatus(
          achievement: Achievements.all.first,
          value: Achievements.all.first.threshold,
          unlockedAt: unlockedAt,
        ),
        AchievementStatus(achievement: Achievements.all[1], value: today),
      ];

      await pumpWidgetInApp(tester, AchievementsView(statuses: statuses));

      expect(find.text('1 von 2 freigeschaltet'), findsOneWidget);
      expect(find.text(Achievements.all.first.nameDe), findsOneWidget);
      expect(
        find.text(Achievements.all[1].nameDe),
        findsOneWidget,
        reason:
            'Ein verschlossener Erfolg bleibt sichtbar, sonst weiß '
            'niemand, worauf er hinarbeitet.',
      );
      expect(
        find.text('$today / ${Achievements.all[1].threshold}'),
        findsOneWidget,
      );
    });
  });

  group('Feier', () {
    testWidgets('nennt Aufstieg, Erfolg und erledigte Aufgabe', (tester) async {
      final outcome = GamificationOutcome(
        xpGained: 240,
        levelBefore: 3,
        levelAfter: 4,
        unlockedAchievements: [Achievements.all.first],
        completedChallenges: [
          ChallengeInstance(
            template: Challenges.daily.first,
            periodKey: '2026-07-30',
            progress: Challenges.daily.first.target,
            completedAt: DateTime(2026, 7, 30),
          ),
        ],
        streak: const StreakState(
          current: 4,
          best: 4,
          freezesLeft: 0,
          activeToday: true,
          usedFreezeDays: {},
        ),
      );

      await pumpWidgetInApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showCelebration(context, outcome),
            child: const Text('feiern'),
          ),
        ),
      );

      await tester.tap(find.text('feiern'));
      await tester.pumpAndSettle();

      expect(find.text('Level 4 erreicht'), findsOneWidget);
      expect(find.text(Achievements.all.first.nameDe), findsOneWidget);
      expect(find.text('ERFOLG FREIGESCHALTET'), findsOneWidget);
      expect(find.text('AUFGABE ERLEDIGT'), findsOneWidget);
    });

    testWidgets('bleibt aus, wenn es nichts zu feiern gibt', (tester) async {
      const outcome = GamificationOutcome(
        xpGained: 40,
        levelBefore: 2,
        levelAfter: 2,
        unlockedAchievements: [],
        completedChallenges: [],
        streak: StreakState(
          current: 1,
          best: 1,
          freezesLeft: 0,
          activeToday: true,
          usedFreezeDays: {},
        ),
      );

      await pumpWidgetInApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showCelebration(context, outcome),
            child: const Text('feiern'),
          ),
        ),
      );

      await tester.tap(find.text('feiern'));
      await tester.pumpAndSettle();

      expect(find.text('Gut gemacht'), findsNothing);
    });
  });
}
