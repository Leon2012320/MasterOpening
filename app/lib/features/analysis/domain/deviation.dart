import 'package:collection/collection.dart';
import 'package:dartchess/dartchess.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:meta/meta.dart';

/// Die Stelle, an der eine echte Partie das Repertoire verlassen hat.
@immutable
class Deviation {
  const Deviation({
    required this.ply,
    required this.byUser,
    required this.playedSan,
    required this.playedUci,
    required this.fenBefore,
    required this.parentPathHash,
    this.expectedSan,
  });

  /// Der Halbzug, in dem abgewichen wurde — eins-basiert wie im PGN.
  final int ply;

  /// Ob der Nutzer selbst abgewichen ist.
  ///
  /// Das ist der entscheidende Unterschied: weicht der Nutzer ab, kannte er
  /// seine eigene Vorbereitung nicht — ein Fehler. Weicht der Gegner ab, fehlt
  /// dem Repertoire eine Antwort — eine Lücke.
  final bool byUser;

  final String playedSan;
  final String playedUci;

  /// Die Stellung vor dem abweichenden Zug.
  final String fenBefore;

  /// Der Knoten, an dem abgezweigt wurde; leer, wenn schon der erste Zug
  /// nicht im Repertoire stand.
  final String parentPathHash;

  /// Was das Repertoire an dieser Stelle vorsieht — die Hauptvariante.
  /// `null`, wenn dort gar nichts steht.
  final String? expectedSan;
}

/// Wie weit eine Partie dem Repertoire gefolgt ist.
@immutable
class GameMatch {
  const GameMatch({required this.matchedPly, this.deviation});

  /// Wie viele Halbzüge im Repertoire standen.
  final int matchedPly;

  /// `null`, wenn die Partie das Repertoire nie verlassen hat — entweder weil
  /// sie ihm bis zum Ende folgte oder weil das Repertoire vorher aufhörte.
  final Deviation? deviation;

  bool get stayedInBook => deviation == null;
}

/// Vergleicht eine gespielte Partie mit einem Repertoire.
///
/// Rein rechnend, ohne Datenbank: hier steckt die Schachlogik, und die soll
/// sich prüfen lassen, ohne dass jemand Partien importieren muss.
abstract final class DeviationFinder {
  /// Weiter als in den Eröffnungsbereich zu schauen bringt nichts — ein
  /// Repertoire endet spätestens dort, und was danach kommt, ist Mittelspiel.
  static const defaultMaxPly = 40;

  static GameMatch match({
    required RepertoireTree tree,
    required Side side,
    required List<String> sanMoves,
    int maxPly = defaultMaxPly,
  }) {
    var position = tree.startPosition;
    var level = tree.children;
    var parentHash = '';

    final limit = sanMoves.length < maxPly ? sanMoves.length : maxPly;

    for (var i = 0; i < limit; i++) {
      // Das Repertoire ist zu Ende — das ist keine Abweichung, sondern
      // schlicht das Ende der Vorbereitung.
      if (level.isEmpty) return GameMatch(matchedPly: i);

      final move = _parse(position, sanMoves[i]);
      if (move == null) return GameMatch(matchedPly: i);

      final uci = move.uci;
      final node = level.firstWhereOrNull((n) => n.uci == uci);

      if (node == null) {
        return GameMatch(
          matchedPly: i,
          deviation: Deviation(
            ply: i + 1,
            byUser: position.turn == side,
            playedSan: sanMoves[i],
            playedUci: uci,
            fenBefore: position.fen,
            parentPathHash: parentHash,
            expectedSan: level.first.san,
          ),
        );
      }

      position = position.play(move);
      parentHash = node.pathHash;
      level = node.children;
    }

    return GameMatch(matchedPly: limit);
  }

  /// Das beste Repertoire zu einer Partie: dasjenige, dem sie am längsten
  /// gefolgt ist. Wer zwei Repertoires derselben Farbe pflegt, soll die
  /// Partie beim passenden wiederfinden.
  static ({int index, GameMatch match})? best({
    required List<({RepertoireTree tree, Side side})> repertoires,
    required Side side,
    required List<String> sanMoves,
    int maxPly = defaultMaxPly,
  }) {
    ({int index, GameMatch match})? winner;

    for (var i = 0; i < repertoires.length; i++) {
      if (repertoires[i].side != side) continue;

      final result = match(
        tree: repertoires[i].tree,
        side: side,
        sanMoves: sanMoves,
        maxPly: maxPly,
      );

      if (winner == null || result.matchedPly > winner.match.matchedPly) {
        winner = (index: i, match: result);
      }
    }

    return winner;
  }

  /// Ein unlesbarer oder illegaler Zug beendet den Vergleich, statt ihn
  /// scheitern zu lassen: importierte Partien enthalten gelegentlich Unfug,
  /// und der darf die Auswertung der übrigen nicht verhindern.
  static Move? _parse(Position position, String san) {
    try {
      return position.parseSan(san);
    } on Object {
      return null;
    }
  }
}
