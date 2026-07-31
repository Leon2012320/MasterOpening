import 'package:collection/collection.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/features/antiprep/domain/scout_report.dart';
import 'package:meta/meta.dart';

/// Eine Zugfolge des Gegners, wie sie im Vorbereitungsblatt steht.
@immutable
class PrepLine {
  const PrepLine({
    required this.moves,
    required this.games,
    required this.theirScore,
    required this.coveredPly,
  });

  /// Die Züge beider Seiten von der Grundstellung aus.
  final List<ScoutNode> moves;

  /// Wie oft diese Folge in seinen Partien vorkam.
  final int games;

  /// Seine Punkteausbeute in dieser Folge.
  final double theirScore;

  /// Bis zu welchem Halbzug dein Repertoire mitgeht.
  final int coveredPly;

  ScoutNode get last => moves.last;

  bool get isCovered => coveredPly >= moves.length;

  /// Wie viel er in dieser Folge liegen lässt — die Zahl, an der sich
  /// entscheidet, worauf man sich vorbereitet.
  double get pointsHeDrops => games * (1 - theirScore);

  String get sanLine {
    final buffer = StringBuffer();
    for (final node in moves) {
      if (node.ply.isOdd) buffer.write('${(node.ply + 1) ~/ 2}. ');
      buffer
        ..write(node.san)
        ..write(' ');
    }
    return buffer.toString().trimRight();
  }
}

/// Macht aus dem Baum eines Gegners ein lesbares Vorbereitungsblatt.
abstract final class PrepSheet {
  /// Wie tief die Zugfolgen im Blatt reichen. Weiter zu gehen macht die
  /// Zeilen unlesbar, ohne mehr zu sagen.
  static const defaultDepth = 6;

  /// Die Zugfolgen, die am ehesten kommen — nach Häufigkeit.
  ///
  /// Das ist die Vorbereitung im engeren Sinn: worauf muss ich gefasst sein.
  static List<PrepLine> mostLikely(
    ScoutTree tree, {
    RepertoireTree? repertoire,
    int depth = defaultDepth,
    int take = 5,
  }) {
    final lines = _collect(tree, depth: depth, repertoire: repertoire)
      ..sort((a, b) => b.games.compareTo(a.games));
    return lines.take(take).toList();
  }

  /// Die Zugfolgen, in denen er am meisten liegen lässt.
  ///
  /// Sortiert nach abgegebenen Punkten, nicht nach Quote: eine Variante, in
  /// der er einmal verloren hat, ist kein Muster.
  static List<PrepLine> weakest(
    ScoutTree tree, {
    RepertoireTree? repertoire,
    int depth = defaultDepth,
    int minGames = 3,
    int take = 5,
  }) {
    final lines =
        _collect(
            tree,
            depth: depth,
            repertoire: repertoire,
          ).where((line) => line.games >= minGames).toList()
          ..sort((a, b) => b.pointsHeDrops.compareTo(a.pointsHeDrops));
    return lines.take(take).toList();
  }

  /// Die häufigsten Folgen, auf die dein Repertoire keine Antwort hat.
  static List<PrepLine> uncovered(
    ScoutTree tree, {
    required RepertoireTree repertoire,
    int depth = defaultDepth,
    int take = 5,
  }) {
    final lines =
        _collect(
            tree,
            depth: depth,
            repertoire: repertoire,
          ).where((line) => !line.isCovered).toList()
          ..sort((a, b) => b.games.compareTo(a.games));
    return lines.take(take).toList();
  }

  /// Sammelt alle Folgen bis [depth] und misst, wie weit das Repertoire
  /// mitgeht.
  static List<PrepLine> _collect(
    ScoutTree tree, {
    required int depth,
    RepertoireTree? repertoire,
  }) {
    final lines = <PrepLine>[];

    void descend(List<ScoutNode> path, List<ScoutNode> level) {
      for (final node in level) {
        final next = [...path, node];

        // Am Ende der Tiefe oder des Astes wird die Folge abgelegt.
        if (next.length >= depth || node.children.isEmpty) {
          lines.add(
            PrepLine(
              moves: next,
              games: node.games,
              theirScore: node.score,
              coveredPly: _coverage(repertoire, next),
            ),
          );
          continue;
        }

        descend(next, node.children);
      }
    }

    descend(const [], tree.children);
    return lines;
  }

  /// Der Knoten im eigenen Repertoire, an dem diese Folge endet — der
  /// Ansatzpunkt zum Üben. `null`, wenn das Repertoire gar nicht mitgeht.
  static String? drillTarget(RepertoireTree repertoire, PrepLine line) {
    var level = repertoire.children;
    String? deepest;

    for (final node in line.moves) {
      final match = level.firstWhereOrNull((n) => n.uci == node.uci);
      if (match == null) break;
      deepest = match.pathHash;
      level = match.children;
    }

    return deepest;
  }

  /// Bis zu welchem Halbzug das Repertoire die Folge kennt.
  static int _coverage(RepertoireTree? repertoire, List<ScoutNode> path) {
    if (repertoire == null) return 0;

    var level = repertoire.children;
    var covered = 0;

    for (final node in path) {
      final match = level.firstWhereOrNull((n) => n.uci == node.uci);
      if (match == null) break;
      covered++;
      level = match.children;
    }

    return covered;
  }
}
