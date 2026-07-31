import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/features/notifications/domain/reminder_plan.dart';

/// 31. Juli 2026, 18:00 Uhr — Nachmittag, beide Erinnerungen noch möglich.
final _afternoon = DateTime(2026, 7, 31, 18);

List<PlannedReminder> plan({
  bool dailyEnabled = true,
  int dailyMinutes = 19 * 60 + 30,
  bool streakRiskEnabled = true,
  int currentStreak = 5,
  bool practisedToday = false,
  DateTime? now,
}) {
  return ReminderPlanner.plan(
    dailyEnabled: dailyEnabled,
    dailyMinutes: dailyMinutes,
    streakRiskEnabled: streakRiskEnabled,
    currentStreak: currentStreak,
    practisedToday: practisedToday,
    now: now ?? _afternoon,
  );
}

void main() {
  group('Nächster Termin', () {
    test('heute, wenn die Uhrzeit noch kommt', () {
      final next = ReminderPlanner.nextOccurrence(
        hour: 19,
        minute: 30,
        now: _afternoon,
      );

      expect(next, DateTime(2026, 7, 31, 19, 30));
    });

    test('morgen, wenn sie vorbei ist', () {
      final next = ReminderPlanner.nextOccurrence(
        hour: 7,
        minute: 0,
        now: _afternoon,
      );

      expect(next, DateTime(2026, 8, 1, 7));
    });
  });

  group('Planung', () {
    test('tägliche Erinnerung wiederholt sich', () {
      final daily = plan(streakRiskEnabled: false).single;

      expect(daily.kind, ReminderKind.daily);
      expect(daily.repeatsDaily, isTrue);
      expect(daily.when, DateTime(2026, 7, 31, 19, 30));
    });

    test('ausgeschaltet heisst kein Termin', () {
      expect(plan(dailyEnabled: false, streakRiskEnabled: false), isEmpty);
    });

    test('die Serienwarnung ist ein einzelner Termin am Abend', () {
      final risk = plan(
        dailyEnabled: false,
      ).single;

      expect(risk.kind, ReminderKind.streakRisk);
      expect(risk.repeatsDaily, isFalse);
      expect(risk.when, DateTime(2026, 7, 31, 20, 30));
    });

    test('wer heute geübt hat, wird nicht gemahnt', () {
      expect(
        plan(dailyEnabled: false, practisedToday: true),
        isEmpty,
      );
    });

    test('ohne Serie gibt es nichts zu verlieren', () {
      expect(plan(dailyEnabled: false, currentStreak: 0), isEmpty);
    });

    test('nach der Warnzeit wird nicht mehr gewarnt', () {
      expect(
        plan(dailyEnabled: false, now: DateTime(2026, 7, 31, 22)),
        isEmpty,
        reason: 'wer um 22 Uhr erinnert wird, ärgert sich nur',
      );
    });

    test('beide Erinnerungen haben verschiedene Kennungen', () {
      final reminders = plan();

      expect(reminders, hasLength(2));
      expect(
        reminders.map((r) => r.id).toSet(),
        hasLength(2),
        reason: 'sonst überschreibt die eine die andere',
      );
    });
  });
}
