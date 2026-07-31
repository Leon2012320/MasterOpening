import 'package:meta/meta.dart';

/// Wofür eine Erinnerung steht.
enum ReminderKind {
  /// Täglich zur eingestellten Uhrzeit.
  daily,

  /// Am Abend, wenn die Serie sonst reisst.
  streakRisk,
}

/// Eine geplante Benachrichtigung.
@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.kind,
    required this.when,
    required this.repeatsDaily,
  });

  final ReminderKind kind;

  /// Der nächste Zeitpunkt in Ortszeit.
  final DateTime when;

  /// Ob sie sich täglich wiederholt oder ein einzelner Termin ist.
  final bool repeatsDaily;

  /// Feste Kennung je Art — so ersetzt eine neue Planung die alte, statt sich
  /// daneben zu stapeln.
  int get id => kind.index + 1;
}

/// Entscheidet, welche Erinnerungen stehen sollen.
///
/// Rein rechnend und ohne Plattform: wann eine Benachrichtigung fällig ist,
/// ist eine Frage von Uhrzeit und Serienstand, und genau daran gehen solche
/// Funktionen üblicherweise kaputt.
abstract final class ReminderPlanner {
  /// Wann abends an die gefährdete Serie erinnert wird.
  ///
  /// Nicht kurz vor Mitternacht: wer um 23:50 erinnert wird, übt nicht mehr,
  /// sondern ärgert sich nur.
  static const streakRiskHour = 20;
  static const streakRiskMinute = 30;

  static List<PlannedReminder> plan({
    required bool dailyEnabled,
    required int dailyMinutes,
    required bool streakRiskEnabled,
    required int currentStreak,
    required bool practisedToday,
    required DateTime now,
  }) {
    final reminders = <PlannedReminder>[];

    if (dailyEnabled) {
      reminders.add(
        PlannedReminder(
          kind: ReminderKind.daily,
          when: nextOccurrence(
            hour: dailyMinutes ~/ 60,
            minute: dailyMinutes % 60,
            now: now,
          ),
          repeatsDaily: true,
        ),
      );
    }

    // Eine Serie, die es nicht gibt, kann nicht reissen; und wer heute schon
    // geübt hat, braucht keine Mahnung mehr.
    if (streakRiskEnabled && currentStreak > 0 && !practisedToday) {
      final when = DateTime(
        now.year,
        now.month,
        now.day,
        streakRiskHour,
        streakRiskMinute,
      );

      // Nur, solange der Abend noch nicht vorbei ist.
      if (when.isAfter(now)) {
        reminders.add(
          PlannedReminder(
            kind: ReminderKind.streakRisk,
            when: when,
            repeatsDaily: false,
          ),
        );
      }
    }

    return reminders;
  }

  /// Der nächste Zeitpunkt mit dieser Uhrzeit — heute, sonst morgen.
  static DateTime nextOccurrence({
    required int hour,
    required int minute,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }
}
