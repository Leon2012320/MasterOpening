import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/repertoire_tree.dart';

const _spanishPgn = '''
[Event "Spanisch"]
[ECO "C65"]
[Opening "Ruy Lopez, Berlin Defence"]

1. e4 e5 2. Nf3 Nc6 3. Bb5 { Die spanische Partie. } 3... Nf6 (3... a6 4. Ba4
{ Morphy-Verteidigung } ) (3... f5 { Schliemann-Gambit } ) 4. O-O *
''';

void main() {
  group('Import', () {
    test('liest Züge, Varianten und Kommentare', () {
      final result = PgnIo.parse(_spanishPgn);

      expect(result.warnings, isEmpty);
      expect(result.eco, 'C65');
      expect(result.openingName, 'Ruy Lopez, Berlin Defence');

      final bb5 = result.tree.nodeAtUciPath([
        'e2e4',
        'e7e5',
        'g1f3',
        'b8c6',
        'f1b5',
      ]);
      expect(bb5, isNotNull);
      expect(bb5!.comment, 'Die spanische Partie.');
      expect(bb5.children.map((c) => c.san), ['Nf6', 'a6', 'f5']);
    });

    test('berechnet für jeden Knoten die Folgestellung', () {
      final tree = PgnIo.parse(_spanishPgn).tree;
      final e4 = tree.children.single;

      expect(
        e4.fenAfter,
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
      );
    });

    test('überspringt nicht legale Züge und meldet sie', () {
      // `Sf6` ist wohlgeformt, für Weiß im dritten Halbzug aber nicht
      // spielbar. Syntaktischer Unsinn wie `Dh9` verwirft schon der Parser,
      // hier geht es um die Legalitätsprüfung.
      final result = PgnIo.parse('1. e4 e5 2. Nf6 Nc6 *');

      expect(result.warnings, hasLength(1));
      expect(result.warnings.single, contains('Nf6'));
      expect(result.tree.nodeCount, 2);
    });

    test('nimmt eine Grundstellung aus dem Kopf an', () {
      const fen = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
      final result = PgnIo.parse('[SetUp "1"]\n[FEN "$fen"]\n\n1. e4 *');

      expect(result.tree.startFen, fen);
      expect(result.tree.children.single.san, 'e4');
    });

    test(
      'fällt bei kaputter Grundstellung auf die Ausgangsstellung zurück',
      () {
        final result = PgnIo.parse('[FEN "keine gültige Stellung"]\n\n1. e4 *');

        expect(result.tree.startFen, RepertoireTree.initialFen);
        expect(result.warnings, isNotEmpty);
      },
    );

    test('liefert einen leeren Baum für Text ohne Züge', () {
      final result = PgnIo.parse('[Event "leer"]\n\n*');

      expect(result.tree.isEmpty, isTrue);
      expect(result.warnings, isEmpty);
    });
  });

  group('Export', () {
    test('überlebt den Umlauf durch PGN unverändert', () {
      final original = PgnIo.parse(_spanishPgn).tree;
      final roundTrip = PgnIo.parse(PgnIo.write(original)).tree;

      expect(roundTrip, original);
    });

    test('behält Kommentare und NAGs', () {
      final tree = const RepertoireTree.empty()
          .withSanLine(['e4', 'e5'], leafComment: 'offen')
          .withNags(
            RepertoireTree.hashFor(RepertoireTree.initialFen, ['e2e4']),
            [1],
          );

      final pgn = PgnIo.write(tree);
      expect(pgn, contains('offen'));
      expect(pgn, contains(r'$1'));

      final back = PgnIo.parse(pgn).tree;
      expect(back.children.single.nags, [1]);
      expect(back.nodeAtUciPath(['e2e4', 'e7e5'])!.comment, 'offen');
    });

    test('schreibt die Grundstellung nur, wenn sie abweicht', () {
      final standard = PgnIo.write(
        const RepertoireTree.empty().withSanLine(['e4']),
      );
      expect(standard, isNot(contains('SetUp')));

      const fen = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
      final custom = PgnIo.write(
        const RepertoireTree.empty(startFen: fen).withSanLine(['e4']),
      );
      expect(custom, contains('SetUp'));
      expect(custom, contains(fen));
    });

    test('übernimmt zusätzliche Kopfzeilen', () {
      final pgn = PgnIo.write(
        const RepertoireTree.empty().withSanLine(['d4']),
        headers: {'Event': 'Mein Repertoire', 'ECO': 'A40'},
      );

      expect(pgn, contains('[Event "Mein Repertoire"]'));
      expect(pgn, contains('[ECO "A40"]'));
    });
  });

  group('Studie mit mehreren Kapiteln', () {
    const study = '''
[Event "Kapitel 1"]

1. e4 e5 2. Nf3 *

[Event "Kapitel 2"]

1. e4 c5 2. Nf3 d6 *
''';

    test('führt die Kapitel zu einem Baum zusammen', () {
      final result = PgnIo.parseStudy(study);

      expect(result.tree.children.single.san, 'e4');
      expect(result.tree.children.single.children.map((c) => c.san), [
        'e5',
        'c5',
      ]);
      expect(result.warnings, isEmpty);
    });

    test('überspringt Kapitel mit abweichender Grundstellung', () {
      const mixed = '''
[Event "Normal"]

1. e4 *

[Event "Endspiel"]
[SetUp "1"]
[FEN "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1"]

1. e4 *
''';

      final result = PgnIo.parseStudy(mixed);

      expect(result.tree.nodeCount, 1);
      expect(result.warnings.single, contains('Endspiel'));
    });
  });
}
