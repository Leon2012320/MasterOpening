import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/db/daos/activity_dao.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/gamification/domain/achievement.dart';
import 'package:masteropening/features/gamification/domain/challenge.dart';
import 'package:masteropening/features/gamification/domain/level_system.dart';
import 'package:masteropening/features/gamification/domain/streak.dart';

final _today = DateTime(2026, 7, 30);

/// Die letzten [count] Tage bis einschliesslich [end].
Set<String> _daysUpTo(DateTime end, int count) => {
  for (var i = 0; i < count; i++)
    ActivityDao.dayKey(end.subtract(Duration(days: i))),
};

void main() {
  group('Levelkurve', () {
    test('beginnt bei Level 1 mit null Punkten', () {
      final progress = LevelSystem.progressFor(0);

      expect(progress.level, 1);
      expect(progress.xpAtLevelStart, 0);
      expect(progress.fraction, 0);
    });

    test('steigt mit den Punkten', () {
      expect(LevelSystem.progressFor(0).level, 1);
      expect(LevelSystem.progressFor(20).level, 2);
      expect(LevelSystem.progressFor(100).level, greaterThan(2));
      expect(
        LevelSystem.progressFor(10000).level,
        greaterThan(LevelSystem.progressFor(1000).level),
      );
    });

    test('braucht für spätere Level immer mehr', () {
      final zweiterSprung = LevelSystem.xpToReach(3) - LevelSystem.xpToReach(2);
      final zehnterSprung =
          LevelSystem.xpToReach(11) - LevelSystem.xpToReach(10);

      expect(zehnterSprung, greaterThan(zweiterSprung * 5));
    });

    test('rechnet den Füllstand der Leiste aus', () {
      final start = LevelSystem.xpToReach(5);
      final next = LevelSystem.xpToReach(6);
      final mitte = LevelSystem.progressFor((start + next) ~/ 2);

      expect(mitte.level, 5);
      expect(mitte.fraction, closeTo(0.5, 0.02));
      expect(mitte.xpRemaining, greaterThan(0));
    });

    test('kennt eine Obergrenze', () {
      final maximum = LevelSystem.progressFor(100000000);

      expect(maximum.level, LevelSystem.maxLevel);
      expect(maximum.isMaxLevel, isTrue);
      expect(maximum.fraction, 1);
      expect(maximum.xpRemaining, 0);
    });

    test('erkennt einen Aufstieg', () {
      final grenze = LevelSystem.xpToReach(4);

      expect(
        LevelSystem.didLevelUp(before: grenze - 1, after: grenze),
        isTrue,
      );
      expect(
        LevelSystem.didLevelUp(before: grenze, after: grenze + 1),
        isFalse,
      );
    });

    test('verträgt einen negativen Punktestand', () {
      expect(LevelSystem.progressFor(-50).level, 1);
    });
  });

  group('Serie', () {
    test('zählt zusammenhängende Tage', () {
      final state = StreakCalculator.evaluate(
        activeDays: _daysUpTo(_today, 5),
        today: _today,
      );

      expect(state.current, 5);
      expect(state.activeToday, isTrue);
      expect(state.atRisk, isFalse);
    });

    test('läuft weiter, solange gestern geübt wurde', () {
      final gestern = _today.subtract(const Duration(days: 1));
      final state = StreakCalculator.evaluate(
        activeDays: _daysUpTo(gestern, 4),
        today: _today,
      );

      // Heute steht noch aus, die Serie zählt aber weiter.
      expect(state.current, 4);
      expect(state.activeToday, isFalse);
      expect(state.atRisk, isTrue);
    });

    test('ist ohne Übung leer', () {
      final state = StreakCalculator.evaluate(
        activeDays: const {},
        today: _today,
      );

      expect(state.current, 0);
      expect(state.atRisk, isFalse);
    });

    test('reisst nach zwei versäumten Tagen', () {
      final vorDreiTagen = _today.subtract(const Duration(days: 3));
      final state = StreakCalculator.evaluate(
        activeDays: _daysUpTo(vorDreiTagen, 10),
        today: _today,
      );

      expect(state.current, 0);
    });

    test('überbrückt einen einzelnen Tag mit einem Schutztag', () {
      // Zehn Tage geübt, dann einer ausgelassen, heute wieder geübt.
      final days = {
        ActivityDao.dayKey(_today),
        ..._daysUpTo(_today.subtract(const Duration(days: 2)), 10),
      };

      final state = StreakCalculator.evaluate(
        activeDays: days,
        today: _today,
      );

      // Elf Übungstage plus der überbrückte — die Serie zählt zusammen-
      // hängende Kalendertage, nicht nur die geübten.
      expect(state.current, 12);
      expect(state.usedFreezeDays, hasLength(1));
    });

    test('schützt nur, wenn die Serie lang genug war', () {
      // Drei Tage geübt, dann eine Lücke — zu kurz für einen Schutztag.
      final days = {
        ActivityDao.dayKey(_today),
        ..._daysUpTo(_today.subtract(const Duration(days: 2)), 3),
      };

      final state = StreakCalculator.evaluate(
        activeDays: days,
        today: _today,
      );

      expect(state.current, 1);
      expect(state.usedFreezeDays, isEmpty);
    });

    test('verbraucht nicht mehr Schutztage als verdient', () {
      // Übung nur an jedem zweiten Tag über einen langen Zeitraum.
      final days = {
        for (var i = 0; i < 40; i += 2)
          ActivityDao.dayKey(_today.subtract(Duration(days: i))),
      };

      final state = StreakCalculator.evaluate(
        activeDays: days,
        today: _today,
      );

      expect(
        state.usedFreezeDays.length,
        lessThanOrEqualTo(StreakCalculator.maxFreezes),
      );
    });

    test('merkt sich den Bestwert', () {
      final state = StreakCalculator.evaluate(
        activeDays: _daysUpTo(_today, 3),
        today: _today,
        bestSoFar: 12,
      );

      expect(state.current, 3);
      expect(state.best, 12);
    });

    test('hebt den Bestwert an, wenn die Serie ihn überholt', () {
      final state = StreakCalculator.evaluate(
        activeDays: _daysUpTo(_today, 20),
        today: _today,
        bestSoFar: 12,
      );

      expect(state.best, 20);
    });
  });

  group('Erfolge', () {
    test('der Katalog ist widerspruchsfrei', () {
      final ids = Achievements.all.map((a) => a.id).toSet();
      expect(ids, hasLength(Achievements.all.length));
      expect(Achievements.all.length, greaterThanOrEqualTo(30));

      for (final achievement in Achievements.all) {
        expect(achievement.threshold, greaterThan(0), reason: achievement.id);
        expect(achievement.xpReward, greaterThan(0), reason: achievement.id);
        expect(achievement.nameDe, isNotEmpty, reason: achievement.id);
        expect(achievement.nameEn, isNotEmpty, reason: achievement.id);
        expect(achievement.hintDe, isNotEmpty, reason: achievement.id);
        expect(achievement.hintEn, isNotEmpty, reason: achievement.id);
      }
    });

    test('jede Gruppe ist besetzt', () {
      for (final category in AchievementCategory.values) {
        expect(
          Achievements.inCategory(category),
          isNotEmpty,
          reason: category.name,
        );
      }
    });

    test('höhere Stufen kosten mehr Punkte', () {
      final stufen =
          Achievements.all
              .where((a) => a.metric == AchievementMetric.movesTrained)
              .toList()
            ..sort((a, b) => a.threshold.compareTo(b.threshold));

      for (var i = 1; i < stufen.length; i++) {
        expect(
          stufen[i].xpReward,
          greaterThanOrEqualTo(stufen[i - 1].xpReward),
          reason: stufen[i].id,
        );
      }
    });

    test('schaltet frei, was die Schwelle erreicht', () {
      final neu = Achievements.newlyUnlocked(
        metrics: {AchievementMetric.movesTrained: 150},
        alreadyUnlocked: const {},
      );

      expect(neu.map((a) => a.id), contains('moves-100'));
      expect(neu.map((a) => a.id), isNot(contains('moves-1000')));
    });

    test('meldet nichts doppelt', () {
      final neu = Achievements.newlyUnlocked(
        metrics: {AchievementMetric.movesTrained: 150},
        alreadyUnlocked: {'moves-100'},
      );

      expect(neu, isEmpty);
    });

    test('behält einen Erfolg, auch wenn die Zahl wieder fällt', () {
      final stand = Achievements.evaluate(
        metrics: {AchievementMetric.repertoires: 0},
        unlocked: {'repertoires-5': DateTime(2026)},
        now: _today,
      );

      final erfolg = stand.firstWhere(
        (s) => s.achievement.id == 'repertoires-5',
      );
      expect(erfolg.isUnlocked, isTrue);
    });

    test('zeigt den Fortschritt bis zur Schwelle', () {
      final stand = Achievements.evaluate(
        metrics: {AchievementMetric.movesTrained: 500},
        unlocked: const {},
        now: _today,
      );

      final erfolg = stand.firstWhere((s) => s.achievement.id == 'moves-1000');
      expect(erfolg.isUnlocked, isFalse);
      expect(erfolg.fraction, closeTo(0.5, 0.001));
    });
  });

  group('Aufgaben', () {
    test('der Katalog ist widerspruchsfrei', () {
      for (final pool in [Challenges.daily, Challenges.weekly]) {
        expect(pool.map((c) => c.type).toSet(), hasLength(pool.length));
        for (final template in pool) {
          expect(template.target, greaterThan(0), reason: template.type);
          expect(template.xpReward, greaterThan(0), reason: template.type);
          expect(template.textDe, contains('{target}'), reason: template.type);
        }
      }
    });

    test('setzt den Zielwert in den Text ein', () {
      final template = Challenges.daily.firstWhere((c) => c.type == 'moves-30');

      expect(template.text('de'), 'Übe heute 30 Züge');
      expect(template.text('en'), 'Train 30 moves today');
    });

    test('wählt je Zeitraum immer dieselben Aufgaben', () {
      final erste = Challenges.pick(
        kind: ChallengeKind.daily,
        periodKey: '2026-07-30',
      );
      final zweite = Challenges.pick(
        kind: ChallengeKind.daily,
        periodKey: '2026-07-30',
      );

      expect(erste.map((c) => c.type), zweite.map((c) => c.type));
    });

    test('wechselt von Tag zu Tag', () {
      final schluessel = [
        '2026-07-30',
        '2026-07-31',
        '2026-08-01',
        '2026-08-02',
        '2026-08-03',
      ];
      final auswahlen = schluessel
          .map(
            (k) => Challenges.pick(
              kind: ChallengeKind.daily,
              periodKey: k,
            ).map((c) => c.type).join(),
          )
          .toSet();

      // Nicht an allen fünf Tagen dieselbe Auswahl.
      expect(auswahlen.length, greaterThan(1));
    });

    test('liefert die vorgesehene Anzahl', () {
      expect(
        Challenges.pick(kind: ChallengeKind.daily, periodKey: '2026-07-30'),
        hasLength(Challenges.perDay),
      );
      expect(
        Challenges.pick(kind: ChallengeKind.weekly, periodKey: '2026-W31'),
        hasLength(Challenges.perWeek),
      );
    });

    test('der Wochenschlüssel folgt ISO 8601', () {
      // Der 30. Juli 2026 ist ein Donnerstag in Kalenderwoche 31.
      expect(Challenges.weekKey(DateTime(2026, 7, 30)), '2026-W31');
      // Montag und Sonntag derselben Woche teilen den Schlüssel.
      expect(
        Challenges.weekKey(DateTime(2026, 7, 27)),
        Challenges.weekKey(DateTime(2026, 8, 2)),
      );
    });

    test('eine Aufgabe ist ab dem Zielwert erledigt', () {
      final template = Challenges.daily.first;
      final offen = ChallengeInstance(
        template: template,
        periodKey: '2026-07-30',
        progress: template.target - 1,
      );
      final fertig = ChallengeInstance(
        template: template,
        periodKey: '2026-07-30',
        progress: template.target,
      );

      expect(offen.isComplete, isFalse);
      expect(offen.fraction, lessThan(1));
      expect(fertig.isComplete, isTrue);
      expect(fertig.fraction, 1);
    });

    test('die Kennung enthält Art, Zeitraum und Typ', () {
      final instance = ChallengeInstance(
        template: Challenges.daily.firstWhere((c) => c.type == 'moves-30'),
        periodKey: '2026-07-30',
        progress: 0,
      );

      expect(instance.id, 'daily:2026-07-30:moves-30');
    });
  });
}
