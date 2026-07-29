import 'package:dartchess/dartchess.dart' show Move, Side;
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/features/learn/domain/study_state.dart';

/// 1. e4 e5 2. Sf3 Sc6 3. Lb5 (3. Lc4) und daneben 1. e4 c5 2. Sf3.
RepertoireTree _tree() => const RepertoireTree.empty()
    .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'], leafComment: 'Spanisch')
    .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bc4'])
    .withSanLine(['e4', 'c5', 'Nf3']);

void main() {
  late RepertoireTree tree;
  late StudyState start;

  setUp(() {
    tree = _tree();
    start = StudyState.atStart(tree);
  });

  group('Grundstellung', () {
    test('beginnt ohne Zug an der Ausgangsstellung', () {
      expect(start.isAtStart, isTrue);
      expect(start.ply, 0);
      expect(start.current, isNull);
      expect(start.fen, RepertoireTree.initialFen);
      expect(start.lastMove, isNull);
      expect(start.canGoBack, isFalse);
      expect(start.canGoForward, isTrue);
    });

    test('bietet die ersten Züge des Baums an', () {
      expect(start.continuations.map((n) => n.san), ['e4']);
    });
  });

  group('Vorwärts und zurück', () {
    test('folgt der Hauptvariante', () {
      final after = start.forward().forward().forward();

      expect(after.sanPath, ['e4', 'e5', 'Nf3']);
      expect(after.ply, 3);
      expect(after.lastMove, Move.parse('g1f3'));
    });

    test('geht zurück, ohne unter die Wurzel zu rutschen', () {
      expect(start.back(), start);
      expect(start.forward().back(), start);
    });

    test('springt an den Anfang und ans Ende der Hauptvariante', () {
      final end = start.toEnd();

      expect(end.sanPath, ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5']);
      expect(end.canGoForward, isFalse);
      expect(end.toStart(), start);
    });

    test('ändert nichts, wenn es nicht weitergeht', () {
      final end = start.toEnd();
      expect(end.forward(), end);
    });
  });

  group('Verzweigungen', () {
    test('erkennt eine Verzweigung', () {
      final afterE4 = start.forward();
      expect(afterE4.isBranchPoint, isTrue);
      expect(afterE4.continuations.map((n) => n.san), ['e5', 'c5']);

      expect(start.isBranchPoint, isFalse);
    });

    test('spielt einen bestimmten Zug der Verzweigung', () {
      final afterE4 = start.forward();
      final sicilian = afterE4.continuations.last;

      expect(afterE4.playNode(sicilian).sanPath, ['e4', 'c5']);
    });

    test('ignoriert einen Knoten, der hier nicht drankommt', () {
      final bb5 = tree.nodeAtUciPath([
        'e2e4',
        'e7e5',
        'g1f3',
        'b8c6',
        'f1b5',
      ])!;

      expect(start.playNode(bb5), start);
    });

    test('wechselt zur nächsten Geschwistervariante und wieder zurück', () {
      final berlin = start.goTo(
        tree.nodeAtUciPath(['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5'])!.pathHash,
      );

      final italian = berlin.nextSibling();
      expect(italian.sanPath.last, 'Bc4');

      // Zwei Geschwister — der übernächste ist wieder der erste.
      expect(italian.nextSibling().sanPath.last, 'Bb5');
    });

    test('lässt nextSibling in Ruhe, wo es keine Alternative gibt', () {
      final afterE4 = start.forward();
      expect(afterE4.nextSibling(), afterE4);
    });
  });

  group('Züge auf dem Brett', () {
    test('nimmt einen Zug an, der im Repertoire steht', () {
      final next = start.playMove(Move.parse('e2e4')!);

      expect(next, isNotNull);
      expect(next!.sanPath, ['e4']);
    });

    test('lehnt einen Zug ab, der nicht vorgesehen ist', () {
      expect(start.playMove(Move.parse('d2d4')!), isNull);
    });

    test('nimmt an einer Verzweigung beide Wege an', () {
      final afterE4 = start.forward();

      expect(afterE4.playMove(Move.parse('e7e5')!)!.sanPath, ['e4', 'e5']);
      expect(afterE4.playMove(Move.parse('c7c5')!)!.sanPath, ['e4', 'c5']);
    });
  });

  group('Springen', () {
    test('geht direkt zu einem Knoten', () {
      final target = tree.nodeAtUciPath(['e2e4', 'c7c5', 'g1f3'])!;
      final jumped = start.goTo(target.pathHash);

      expect(jumped.sanPath, ['e4', 'c5', 'Nf3']);
      expect(jumped.current!.pathHash, target.pathHash);
    });

    test('bleibt stehen, wenn der Knoten nicht existiert', () {
      expect(start.goTo('gibt es nicht'), start);
    });
  });

  test('Brett drehen wechselt nur die Blickrichtung', () {
    final flipped = start.forward().flipped();

    expect(flipped.orientation, Side.black);
    expect(flipped.sanPath, ['e4']);
    expect(flipped.flipped().orientation, Side.white);
  });

  test('Kommentar des aktuellen Zugs', () {
    expect(start.comment, isNull);
    expect(start.toEnd().comment, 'Spanisch');
  });

  group('withTree nach einer Bearbeitung', () {
    test('behält die Position, wenn der Weg noch existiert', () {
      final at = start.forward().forward().forward();

      final extended = tree.withSanLine(['d4', 'd5']);
      final moved = at.withTree(extended);

      expect(moved.sanPath, ['e4', 'e5', 'Nf3']);
      expect(moved.tree, extended);
    });

    test('geht so weit zurück, wie der Weg noch trägt', () {
      final at = start.toEnd();
      expect(at.sanPath, ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5']);

      final nc6 = tree.nodeAtUciPath(['e2e4', 'e7e5', 'g1f3', 'b8c6'])!;
      final pruned = tree.withoutNode(nc6.pathHash);

      final moved = at.withTree(pruned);
      expect(moved.sanPath, ['e4', 'e5', 'Nf3']);
    });

    test('landet an der Grundstellung, wenn nichts mehr passt', () {
      final at = start.forward();
      final moved = at.withTree(
        const RepertoireTree.empty().withSanLine(['d4']),
      );

      expect(moved.isAtStart, isTrue);
    });
  });
}
