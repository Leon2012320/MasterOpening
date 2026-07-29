import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/repertoire_tree.dart';

void main() {
  group('pathHash', () {
    test('ist für dieselbe Zugfolge stabil', () {
      final a = RepertoireTree.hashFor(RepertoireTree.initialFen, [
        'e2e4',
        'e7e5',
      ]);
      final b = RepertoireTree.hashFor(RepertoireTree.initialFen, [
        'e2e4',
        'e7e5',
      ]);

      expect(a, b);
      expect(a, hasLength(40));
    });

    test('unterscheidet Zugfolgen, die zur selben Stellung führen', () {
      // 1. Sf3 Sf6 2. Sg1 Sg8 landet wieder in der Grundstellung, ist aber
      // ein anderer Weg — und damit ein anderer Lerninhalt.
      final direct = RepertoireTree.hashFor(RepertoireTree.initialFen, []);
      final roundTrip = RepertoireTree.hashFor(RepertoireTree.initialFen, [
        'g1f3',
        'g8f6',
        'f3g1',
        'f6g8',
      ]);

      expect(direct, isNot(roundTrip));
    });

    test('unterscheidet verschiedene Startstellungen', () {
      const other =
          'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';

      expect(
        RepertoireTree.hashFor(RepertoireTree.initialFen, ['e2e4']),
        isNot(RepertoireTree.hashFor(other, ['e2e4'])),
      );
    });
  });

  group('withSanLine', () {
    test('legt eine Zugfolge an', () {
      final tree = const RepertoireTree.empty().withSanLine([
        'e4',
        'e5',
        'Nf3',
        'Nc6',
        'Bb5',
      ]);

      expect(tree.nodeCount, 5);
      expect(tree.maxDepth, 5);
      expect(tree.children.single.san, 'e4');
      expect(tree.lines().single.sanLine, '1. e4 e5 2. Nf3 Nc6 3. Bb5');
    });

    test('verzweigt an der Stelle, wo sich zwei Linien trennen', () {
      final tree = const RepertoireTree.empty()
          .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'])
          .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bc4']);

      expect(tree.lines(), hasLength(2));
      // Gemeinsames Präfix wird nicht doppelt gespeichert.
      expect(tree.nodeCount, 6);

      final nc6 = tree.nodeAtUciPath(['e2e4', 'e7e5', 'g1f3', 'b8c6']);
      expect(nc6!.children.map((c) => c.san), ['Bb5', 'Bc4']);
    });

    test('ändert nichts, wenn die Linie schon vollständig da ist', () {
      final first = const RepertoireTree.empty().withSanLine([
        'd4',
        'd5',
        'c4',
      ]);
      final second = first.withSanLine(['d4', 'd5', 'c4']);

      expect(second, first);
    });

    test('weist einen nicht legalen Zug zurück', () {
      expect(
        () => const RepertoireTree.empty().withSanLine(['e4', 'e5', 'Qh9']),
        throwsA(isA<InvalidMoveException>()),
      );
    });

    test('rechnet Halbzugnummer und ziehende Seite richtig aus', () {
      final tree = const RepertoireTree.empty().withSanLine([
        'e4',
        'c5',
        'Nf3',
      ]);
      final nodes = tree.walk().toList();

      expect(nodes.map((n) => n.ply), [1, 2, 3]);
      expect(nodes.map((n) => n.moveNumber), [1, 1, 2]);
      expect(nodes.map((n) => n.movedBy), [
        Side.white,
        Side.black,
        Side.white,
      ]);
    });
  });

  group('Bearbeiten', () {
    late RepertoireTree tree;

    setUp(() {
      tree = const RepertoireTree.empty()
          .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'])
          .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bc4'])
          .withSanLine(['e4', 'c5', 'Nf3', 'd6']);
    });

    test('entfernt einen Knoten samt allem darunter', () {
      final sicilian = tree.nodeAtUciPath(['e2e4', 'c7c5'])!;
      final pruned = tree.withoutNode(sicilian.pathHash);

      expect(pruned.nodeAtUciPath(['e2e4', 'c7c5']), isNull);
      expect(pruned.lines(), hasLength(2));
      // Die spanische Linie bleibt unberührt.
      expect(pruned.nodeAtUciPath(['e2e4', 'e7e5', 'g1f3']), isNotNull);
    });

    test('macht eine Nebenvariante zur Hauptvariante', () {
      final italian = tree.nodeAtUciPath([
        'e2e4',
        'e7e5',
        'g1f3',
        'b8c6',
        'f1c4',
      ])!;
      final promoted = tree.withMainline(italian.pathHash);

      final nc6 = promoted.nodeAtUciPath(['e2e4', 'e7e5', 'g1f3', 'b8c6'])!;
      expect(nc6.children.first.san, 'Bc4');

      // Auch weiter oben rückt der Pfad nach vorn.
      expect(promoted.children.first.children.first.san, 'e5');
    });

    test('setzt und löscht Kommentare', () {
      final node = tree.nodeAtUciPath(['e2e4'])!;

      final withComment = tree.withComment(node.pathHash, '  Königsbauer  ');
      expect(
        withComment.nodeAtUciPath(['e2e4'])!.comment,
        'Königsbauer',
      );

      final cleared = withComment.withComment(node.pathHash, '   ');
      expect(cleared.nodeAtUciPath(['e2e4'])!.comment, isNull);
    });

    test('lässt die Kennungen aller anderen Züge unberührt', () {
      // Der Kern der pathHash-Idee: eine Änderung an einer Stelle darf die
      // Kennungen aller anderen Knoten nicht verschieben — sonst verlöre der
      // Lernfortschritt seine Zuordnung.
      final before = tree.walk().map((n) => n.pathHash).toSet();

      final sicilian = tree.nodeAtUciPath(['e2e4', 'c7c5'])!;
      final edited = tree.withComment(sicilian.pathHash, 'scharf');

      expect(edited.walk().map((n) => n.pathHash).toSet(), before);
    });
  });

  group('merge', () {
    test('führt zwei Bäume zusammen, ohne zu doppeln', () {
      final mine = const RepertoireTree.empty().withSanLine([
        'e4',
        'e5',
        'Nf3',
        'Nc6',
        'Bb5',
      ]);
      final theirs = const RepertoireTree.empty()
          .withSanLine(['e4', 'e5', 'Nf3', 'Nc6', 'Bc4'])
          .withSanLine(['e4', 'c5']);

      final merged = mine.merge(theirs);

      expect(merged.lines(), hasLength(3));
      expect(merged.nodeAtUciPath(['e2e4', 'c7c5']), isNotNull);
      expect(
        merged.nodeAtUciPath(['e2e4', 'e7e5', 'g1f3', 'b8c6'])!.children,
        hasLength(2),
      );
    });

    test('behält den eigenen Kommentar', () {
      final mine = const RepertoireTree.empty().withSanLine(['e4']);
      final withComment = mine.withComment(
        mine.children.single.pathHash,
        'meine Notiz',
      );
      final theirs = const RepertoireTree.empty().withSanLine(
        ['e4'],
        leafComment: 'fremde Notiz',
      );

      final merged = withComment.merge(theirs);

      expect(merged.children.single.comment, 'meine Notiz');
    });

    test('weigert sich bei verschiedenen Startstellungen', () {
      const otherFen =
          'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1';

      expect(
        () => const RepertoireTree.empty().merge(
          const RepertoireTree.empty(startFen: otherFen),
        ),
        throwsArgumentError,
      );
    });
  });

  group('Auswertung', () {
    test('listet die Züge der eigenen Farbe', () {
      final tree = const RepertoireTree.empty().withSanLine([
        'e4',
        'e5',
        'Nf3',
        'Nc6',
        'Bb5',
      ]);
      final line = tree.lines().single;

      expect(line.ownMoves(Side.white).map((n) => n.san), [
        'e4',
        'Nf3',
        'Bb5',
      ]);
      expect(line.ownMoves(Side.black).map((n) => n.san), ['e5', 'Nc6']);
    });

    test('sammelt alle Stellungen inklusive der Ausgangsstellung', () {
      final tree = const RepertoireTree.empty().withSanLine(['e4', 'e5']);

      expect(tree.positionFens, hasLength(3));
      expect(tree.positionFens, contains(RepertoireTree.initialFen));
    });
  });
}
