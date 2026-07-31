import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/library/domain/library_opening.dart';
import 'package:meta/meta.dart';

/// Die drei Achsen, auf denen sich ein Eröffnungsgeschmack beschreiben lässt.
enum StyleAxis {
  /// Angriff gegen Solidität.
  aggression,

  /// Taktik gegen Strategie.
  tactics,

  /// Offene gegen geschlossene Stellungen.
  openness,
}

/// Wie ausgeprägt eine Achse ist.
///
/// Der Wert läuft von −1 bis +1: bei [StyleAxis.aggression] steht +1 für
/// Angriff und −1 für Solidität. Null heisst nicht „unentschieden", sondern
/// „aus den Partien nicht ablesbar" — der Unterschied steht in [samples].
@immutable
class StyleScore {
  const StyleScore({
    required this.axis,
    required this.value,
    required this.samples,
  });

  final StyleAxis axis;
  final double value;

  /// Wie viele Partien zu dieser Achse etwas beigetragen haben.
  final int samples;

  /// Ab zehn Partien je Achse wird die Zahl belastbar; darunter ist sie ein
  /// erster Eindruck.
  bool get isReliable => samples >= 10;

  /// 0…1, für die Anzeige als Balken zwischen den beiden Polen.
  double get position => (value + 1) / 2;
}

/// Das Stilbild eines Spielers.
@immutable
class StyleProfile {
  const StyleProfile({required this.scores, required this.gamesAnalysed});

  final Map<StyleAxis, StyleScore> scores;
  final int gamesAnalysed;

  bool get isEmpty => gamesAnalysed == 0;

  double valueOf(StyleAxis axis) => scores[axis]?.value ?? 0;
}

/// Leitet aus den gespielten Eröffnungen ein Stilbild ab.
///
/// Grundlage sind die Merkmale der Bibliothek, nicht eine Zuganalyse: welche
/// Eröffnung jemand freiwillig und mit Erfolg spielt, sagt mehr über seinen
/// Geschmack als die Zahl der Schläge in Partie zwölf. Eine Engine bräuchte
/// es dafür auch nicht.
abstract final class StyleAnalyser {
  /// Wie stark ein Merkmal auf welche Achse schlägt.
  static const _weights = <OpeningTag, Map<StyleAxis, double>>{
    OpeningTag.attacking: {StyleAxis.aggression: 1},
    OpeningTag.gambit: {StyleAxis.aggression: 1, StyleAxis.tactics: 0.5},
    OpeningTag.solid: {StyleAxis.aggression: -1},
    OpeningTag.system: {StyleAxis.aggression: -0.5, StyleAxis.tactics: -0.5},
    OpeningTag.tactical: {StyleAxis.tactics: 1},
    OpeningTag.positional: {StyleAxis.tactics: -1},
    OpeningTag.classical: {StyleAxis.tactics: -0.3},
    OpeningTag.open: {StyleAxis.openness: 1},
    OpeningTag.closed: {StyleAxis.openness: -1},
    OpeningTag.theoryHeavy: {StyleAxis.tactics: 0.3},
  };

  /// Eine Partie, die in die Auswertung eingeht.
  ///
  /// Der Ausgang gewichtet mit: was jemand gewinnt, liegt ihm — was er
  /// regelmäßig verliert, offenbar nicht.
  static StyleProfile analyse({
    required List<({List<OpeningTag> tags, GameOutcome outcome})> games,
  }) {
    final sums = <StyleAxis, double>{};
    final weights = <StyleAxis, double>{};
    final samples = <StyleAxis, int>{};

    for (final game in games) {
      // Eine gewonnene Partie zählt doppelt so viel wie eine verlorene: die
      // Vorliebe zeigt sich in beiden, der Erfolg nur in einer.
      final weight = switch (game.outcome) {
        GameOutcome.win => 1.0,
        GameOutcome.draw => 0.75,
        GameOutcome.loss => 0.5,
      };

      for (final tag in game.tags) {
        final effect = _weights[tag];
        if (effect == null) continue;

        for (final entry in effect.entries) {
          sums[entry.key] = (sums[entry.key] ?? 0) + entry.value * weight;
          weights[entry.key] = (weights[entry.key] ?? 0) + weight;
          samples[entry.key] = (samples[entry.key] ?? 0) + 1;
        }
      }
    }

    return StyleProfile(
      gamesAnalysed: games.length,
      scores: {
        for (final axis in StyleAxis.values)
          axis: StyleScore(
            axis: axis,
            value: (weights[axis] ?? 0) == 0
                ? 0
                : (sums[axis]! / weights[axis]!).clamp(-1.0, 1.0),
            samples: samples[axis] ?? 0,
          ),
      },
    );
  }

  /// Wie gut eine Eröffnung zu einem Stilbild passt — 0 bis 1.
  static double matchFor(StyleProfile profile, List<OpeningTag> tags) {
    if (tags.isEmpty) return 0;

    var total = 0.0;
    var count = 0;

    for (final tag in tags) {
      final effect = _weights[tag];
      if (effect == null) continue;

      for (final entry in effect.entries) {
        // Zwei Werte auf derselben Achse passen zusammen, wenn sie dasselbe
        // Vorzeichen haben; der Abstand misst, wie gut.
        final distance = (profile.valueOf(entry.key) - entry.value).abs() / 2;
        total += 1 - distance;
        count++;
      }
    }

    return count == 0 ? 0 : (total / count).clamp(0.0, 1.0);
  }

  /// Die Eröffnungen, die am besten passen und noch nicht im Repertoire sind.
  static List<({LibraryOpeningSummary opening, double match})> suggest({
    required StyleProfile profile,
    required List<LibraryOpeningSummary> library,
    required Set<String> alreadyInRepertoire,
    int take = 6,
  }) {
    final scored =
        [
          for (final opening in library)
            if (!alreadyInRepertoire.contains(opening.id))
              (opening: opening, match: matchFor(profile, opening.tags)),
        ]..sort((a, b) {
          final byMatch = b.match.compareTo(a.match);
          // Bei gleicher Passung die bekanntere Eröffnung: mehr Material, mehr
          // Partien zum Nachspielen.
          return byMatch != 0
              ? byMatch
              : b.opening.popularity.compareTo(a.opening.popularity);
        });

    return scored.take(take).toList();
  }
}
