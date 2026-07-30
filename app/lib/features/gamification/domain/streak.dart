import 'package:masteropening/core/db/daos/activity_dao.dart';
import 'package:meta/meta.dart';

/// Der Stand der Übungsserie.
@immutable
class StreakState {
  const StreakState({
    required this.current,
    required this.best,
    required this.freezesLeft,
    required this.activeToday,
    required this.usedFreezeDays,
  });

  /// Wie viele Tage die Serie gerade lang ist.
  final int current;

  /// Die längste Serie, die je erreicht wurde.
  final int best;

  /// Wie viele Schutztage noch übrig sind.
  final int freezesLeft;

  /// Ob heute schon geübt wurde.
  final bool activeToday;

  /// Welche Tage durch einen Schutztag überbrückt wurden — die Heatmap
  /// zeichnet sie anders als echte Übungstage.
  final Set<String> usedFreezeDays;

  /// Ob die Serie heute reisst, wenn nichts mehr passiert.
  bool get atRisk => !activeToday && current > 0;
}

/// Rechnet die Serie aus den Tageswerten aus.
///
/// Ein einzelner versäumter Tag kostet die Serie nicht sofort: dafür sind die
/// Schutztage da. Ohne sie verlieren Leute nach einem vollen Monat wegen einer
/// Zugfahrt alles und hören auf — genau der Effekt, den eine Serie verhindern
/// soll. Zwei versäumte Tage hintereinander beenden sie trotzdem.
abstract final class StreakCalculator {
  /// Höchstzahl an Schutztagen, die sich ansammeln können.
  static const maxFreezes = 3;

  /// Nach so vielen Tagen in Folge kommt ein Schutztag dazu.
  static const daysPerFreeze = 7;

  /// [activeDays] sind die Tage mit Übung als `JJJJ-MM-TT`.
  static StreakState evaluate({
    required Set<String> activeDays,
    required DateTime today,
    int bestSoFar = 0,
  }) {
    final todayKey = ActivityDao.dayKey(today);
    final activeToday = activeDays.contains(todayKey);

    // Schutztage sammeln sich über die gesamte Übungsgeschichte an, nicht
    // innerhalb der laufenden Serie: sonst stünde ausgerechnet an der Lücke
    // nie einer bereit, weil die rückwärts gezählte Serie dort noch bei eins
    // steht.
    final budget = (activeDays.length ~/ daysPerFreeze).clamp(0, maxFreezes);

    var streak = 0;
    var freezesUsed = 0;
    final frozen = <String>{};

    // Überbrückte Tage zählen erst, wenn davor wieder geübt wurde. Sonst
    // würde die Serie am Anfang der Übungsgeschichte um die Schutztage ins
    // Leere weiterlaufen.
    final pending = <String>[];

    // Rückwärts laufen. Wurde heute noch nicht geübt, zählt die Serie ab
    // gestern — sonst stünde sie den ganzen Tag über auf null.
    var cursor = activeToday ? today : today.subtract(const Duration(days: 1));

    while (true) {
      final key = ActivityDao.dayKey(cursor);

      if (activeDays.contains(key)) {
        frozen.addAll(pending);
        pending.clear();
        streak++;
      } else {
        if (freezesUsed >= budget) break;
        freezesUsed++;
        pending.add(key);
      }

      cursor = cursor.subtract(const Duration(days: 1));
      // Grenze gegen einen Fehler in den Daten; über zehn Jahre Serie hinaus
      // interessiert die Zahl niemanden mehr.
      if (streak > 3650) break;
    }

    // Was am Ende offen blieb, war kein überbrückter Tag, sondern einfach
    // die Zeit vor der ersten Übung.
    freezesUsed -= pending.length;

    // Die Serie zählt zusammenhängende Kalendertage — ein überbrückter Tag
    // gehört dazu, genau dafür ist er da.
    final total = streak == 0 ? 0 : streak + frozen.length;

    return StreakState(
      current: total,
      best: total > bestSoFar ? total : bestSoFar,
      freezesLeft: budget - freezesUsed,
      activeToday: activeToday,
      usedFreezeDays: frozen,
    );
  }
}
