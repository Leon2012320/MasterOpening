import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:meta/meta.dart';

/// Ein Element in der Zugliste.
@immutable
sealed class MoveSpan {
  const MoveSpan();
}

/// Die Zugnummer vor einem Zug: „4." oder „4…".
final class MoveNumberSpan extends MoveSpan {
  const MoveNumberSpan(this.label);
  final String label;
}

/// Ein anklickbarer Zug.
final class MoveNodeSpan extends MoveSpan {
  const MoveNodeSpan(this.node);
  final RepertoireNode node;
}

/// Ein Kommentar aus dem PGN.
final class CommentSpan extends MoveSpan {
  const CommentSpan(this.text);
  final String text;
}

/// Eine Zeile der Zugliste. [depth] 0 ist die Hauptvariante, alles darüber
/// sind Nebenvarianten und werden eingerückt.
@immutable
class MoveRow {
  MoveRow({required this.depth, required List<MoveSpan> spans})
    : spans = List.unmodifiable(spans);

  final int depth;
  final List<MoveSpan> spans;

  bool get isEmpty => spans.isEmpty;
}

/// Bringt den Variantenbaum in die Form, in der Lichess-Studien ihn zeigen:
/// die Hauptvariante läuft durch, Nebenvarianten stehen eingerückt direkt
/// hinter dem Zug, von dem sie abzweigen.
abstract final class MoveListLayout {
  /// Ab dieser Tiefe wird nicht weiter eingerückt — sonst wird eine tief
  /// verschachtelte Eröffnung auf dem Telefon unlesbar schmal.
  static const maxIndentDepth = 4;

  static List<MoveRow> build(RepertoireTree tree) {
    final rows = <MoveRow>[];
    _renderLine(tree.children, 0, rows);
    return rows.where((r) => !r.isEmpty).toList();
  }

  /// Läuft eine Linie entlang und sammelt unterwegs die Abzweigungen ein.
  static void _renderLine(
    List<RepertoireNode> start,
    int depth,
    List<MoveRow> rows,
  ) {
    var spans = <MoveSpan>[];
    var level = start;

    // Nach einer eingeschobenen Nebenvariante braucht der nächste schwarze
    // Zug wieder „4…", sonst ist nicht erkennbar, wo er hingehört.
    var needsEllipsis = depth > 0;

    void flush() {
      if (spans.isNotEmpty) {
        rows.add(MoveRow(depth: depth, spans: spans));
        spans = <MoveSpan>[];
      }
    }

    while (level.isNotEmpty) {
      final node = level.first;

      if (node.ply.isOdd) {
        spans.add(MoveNumberSpan('${node.moveNumber}.'));
      } else if (needsEllipsis) {
        spans.add(MoveNumberSpan('${node.moveNumber}…'));
      }
      needsEllipsis = false;

      spans.add(MoveNodeSpan(node));

      if (node.comment != null) {
        spans.add(CommentSpan(node.comment!));
      }

      // Nebenvarianten dieser Ebene: alles ausser der Hauptvariante.
      if (level.length > 1) {
        flush();
        for (final sibling in level.skip(1)) {
          _renderLine(
            [sibling],
            depth + 1 > maxIndentDepth ? maxIndentDepth : depth + 1,
            rows,
          );
        }
        needsEllipsis = true;
      }

      level = node.children;
    }

    flush();
  }
}
