import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/features/learn/domain/move_list_layout.dart';

/// Gibt eine Zeile so wieder, wie sie auf dem Bildschirm zu lesen wäre.
String _render(MoveRow row) {
  return row.spans
      .map(
        (span) => switch (span) {
          MoveNumberSpan(:final label) => label,
          MoveNodeSpan(:final node) => node.san,
          CommentSpan(:final text) => '{$text}',
        },
      )
      .join(' ');
}

void main() {
  test('eine gerade Linie ergibt eine einzige Zeile', () {
    final tree = const RepertoireTree.empty().withSanLine([
      'e4',
      'e5',
      'Nf3',
      'Nc6',
      'Bb5',
    ]);

    final rows = MoveListLayout.build(tree);

    expect(rows, hasLength(1));
    expect(rows.single.depth, 0);
    expect(_render(rows.single), '1. e4 e5 2. Nf3 Nc6 3. Bb5');
  });

  test('Nebenvarianten stehen eingerückt hinter dem Abzweig', () {
    final tree = PgnIo.parse(
      '1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6 (3... a6 4. Ba4) (3... f5) 4. O-O *',
    ).tree;

    final rows = MoveListLayout.build(tree);

    expect(rows.map((r) => r.depth), [0, 1, 1, 0]);
    expect(_render(rows[0]), '1. e4 e5 2. Nf3 Nc6 3. Bb5 Nf6');
    expect(_render(rows[1]), '3… a6 4. Ba4');
    expect(_render(rows[2]), '3… f5');
    // Nach der Einschaltung beginnt die Hauptvariante wieder mit Nummer.
    expect(_render(rows[3]), '4. O-O');
  });

  test('eine Nebenvariante, die mit einem weissen Zug beginnt', () {
    final tree = PgnIo.parse('1. e4 e5 2. Nf3 (2. Bc4 Nf6) 2... Nc6 *').tree;

    final rows = MoveListLayout.build(tree);

    expect(_render(rows[0]), '1. e4 e5 2. Nf3');
    expect(rows[1].depth, 1);
    expect(_render(rows[1]), '2. Bc4 Nf6');
    expect(_render(rows[2]), '2… Nc6');
  });

  test('Kommentare stehen hinter ihrem Zug', () {
    final tree = PgnIo.parse('1. e4 { Königsbauer } e5 2. Nf3 *').tree;

    final rows = MoveListLayout.build(tree);

    expect(_render(rows.single), '1. e4 {Königsbauer} e5 2. Nf3');
  });

  test('verschachtelte Varianten rücken weiter ein', () {
    final tree = PgnIo.parse(
      '1. e4 e5 (1... c5 2. Nf3 (2. Nc3) ) 2. Nf3 *',
    ).tree;

    final rows = MoveListLayout.build(tree);
    final depths = rows.map((r) => r.depth).toList();

    expect(depths, containsAllInOrder([0, 1, 2]));
  });

  test('die Einrückung wird gedeckelt', () {
    // Sechs geschachtelte Abzweigungen; ab der fünften Ebene darf nicht
    // weiter eingerückt werden, sonst bleibt am Telefon keine Breite übrig.
    var tree = const RepertoireTree.empty().withSanLine([
      'e4',
      'e5',
      'Nf3',
      'Nc6',
      'Bb5',
      'a6',
      'Ba4',
      'Nf6',
      'O-O',
      'Be7',
      'Re1',
      'b5',
    ]);
    for (final alternative in [
      ['e4', 'c5'],
      ['e4', 'e5', 'Nc3'],
      ['e4', 'e5', 'Nf3', 'd6'],
      ['e4', 'e5', 'Nf3', 'Nc6', 'Bc4'],
      ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'Nf6'],
      ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6', 'Bxc6'],
    ]) {
      tree = tree.withSanLine(alternative);
    }

    final rows = MoveListLayout.build(tree);

    expect(
      rows.map((r) => r.depth).reduce((a, b) => a > b ? a : b),
      lessThanOrEqualTo(MoveListLayout.maxIndentDepth),
    );
  });

  test('ein leerer Baum ergibt keine Zeilen', () {
    expect(MoveListLayout.build(const RepertoireTree.empty()), isEmpty);
  });
}
