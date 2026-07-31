import 'package:masteropening/core/db/enums.dart';
import 'package:meta/meta.dart';

/// Eine Lücke im Repertoire, wie sie aus einer Partie hervorgeht.
///
/// „Lücke" heisst immer: der Gegner hat etwas gespielt, worauf das Repertoire
/// keine Antwort kennt. Was der Nutzer selbst falsch macht, ist keine Lücke,
/// sondern ein Fehler — dafür gibt es das Training.
@immutable
class GapCandidate {
  const GapCandidate({
    required this.repertoireId,
    required this.parentPathHash,
    required this.fen,
    required this.missingSan,
    required this.missingUci,
    required this.occurrences,
    required this.pointsLost,
  });

  final int repertoireId;

  /// Der Knoten, an dem abgezweigt wird; leer, wenn schon der erste Zug fehlt.
  final String parentPathHash;

  final String fen;
  final String missingSan;
  final String missingUci;

  /// Wie oft die Lücke in den ausgewerteten Partien auftrat.
  final int occurrences;

  /// Punkte, die dabei liegengeblieben sind: 1,0 je Niederlage, 0,5 je Remis.
  final double pointsLost;

  /// Der Schlüssel, unter dem dieselbe Lücke wiedererkannt wird.
  String get key => '$repertoireId|$parentPathHash|$missingUci';

  /// Häufigkeit mal durchschnittlicher Verlust — was rechnerisch genau die
  /// verlorenen Punkte sind. Eine Lücke, durch die man immer gewinnt, hat
  /// keine Dringlichkeit, auch wenn sie oft auftritt.
  double get urgency => pointsLost;

  GapCandidate plus({required double pointsLost}) => GapCandidate(
    repertoireId: repertoireId,
    parentPathHash: parentPathHash,
    fen: fen,
    missingSan: missingSan,
    missingUci: missingUci,
    occurrences: occurrences + 1,
    pointsLost: this.pointsLost + pointsLost,
  );
}

abstract final class GapRanking {
  /// Was eine Partie an Punkten gekostet hat.
  static double pointsLostFor(GameOutcome outcome) => switch (outcome) {
    GameOutcome.loss => 1,
    GameOutcome.draw => 0.5,
    GameOutcome.win => 0,
  };

  /// Dringendste zuerst; bei gleichem Verlust die häufigere Lücke.
  static List<GapCandidate> sorted(Iterable<GapCandidate> gaps) {
    return [...gaps]..sort((a, b) {
      final byUrgency = b.urgency.compareTo(a.urgency);
      if (byUrgency != 0) return byUrgency;
      return b.occurrences.compareTo(a.occurrences);
    });
  }
}

/// Ein Zug, der im Training immer wieder danebengeht.
@immutable
class MoveMistake {
  const MoveMistake({
    required this.repertoireId,
    required this.repertoireName,
    required this.pathHash,
    required this.expectedSan,
    required this.attempts,
    required this.wrong,
    this.commonWrongSan,
    this.sanLine = '',
  });

  final int repertoireId;
  final String repertoireName;
  final String pathHash;

  /// Der richtige Zug.
  final String expectedSan;

  final int attempts;
  final int wrong;

  /// Der am häufigsten stattdessen gespielte Zug — er verrät, welche Idee im
  /// Weg steht.
  final String? commonWrongSan;

  /// Die Zugfolge bis dorthin, für die Anzeige.
  final String sanLine;

  double get errorRate => attempts == 0 ? 0 : wrong / attempts;

  MoveMistake withLine({required String sanLine, required String name}) =>
      MoveMistake(
        repertoireId: repertoireId,
        repertoireName: name,
        pathHash: pathHash,
        expectedSan: expectedSan,
        attempts: attempts,
        wrong: wrong,
        commonWrongSan: commonWrongSan,
        sanLine: sanLine,
      );
}
