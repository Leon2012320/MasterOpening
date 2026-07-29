import 'dart:io';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/features/library/data/library_repository.dart';
import 'package:masteropening/features/library/domain/library_opening.dart';

import '../helpers/asset_bundle.dart';

/// Prüft die erzeugten Bibliotheksdaten.
///
/// Die Bäume entstehen in `tools/build-openings.mjs` aus der ECO-Datenbank —
/// dort gibt es keinen Schachmotor, der die Legalität prüfen könnte. Genau
/// das passiert hier: jede Zugfolge wird nachgespielt, und jeder Zug, der
/// nicht geht, lässt den Test scheitern.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryRepository repository;
  late List<LibraryOpeningSummary> index;

  setUpAll(() async {
    repository = LibraryRepository(bundle: FileAssetBundle());
    index = await repository.index();
  });

  group('Index', () {
    test('enthält rund 50 Eröffnungen, ausgewogen über beide Farben', () {
      expect(index.length, greaterThanOrEqualTo(50));

      final white = index.where((o) => o.side == Side.white).length;
      final black = index.length - white;
      expect(white, greaterThanOrEqualTo(20));
      expect(black, greaterThanOrEqualTo(20));
    });

    test('vergibt jede Kennung nur einmal', () {
      final ids = index.map((o) => o.id).toSet();
      expect(ids, hasLength(index.length));
    });

    test('ist nach Verbreitung sortiert', () {
      final popularity = index.map((o) => o.popularity).toList();
      expect(
        popularity,
        orderedEquals(popularity.toList()..sort((a, b) => b - a)),
      );
    });

    test('hat überall Name, Beschreibung, ECO-Code und Merkmale', () {
      for (final opening in index) {
        expect(opening.nameDe, isNotEmpty, reason: opening.id);
        expect(opening.nameEn, isNotEmpty, reason: opening.id);
        expect(opening.summaryDe.length, greaterThan(40), reason: opening.id);
        expect(opening.summaryEn.length, greaterThan(40), reason: opening.id);
        expect(
          opening.eco,
          matches(RegExp(r'^[A-E]\d\d$')),
          reason: opening.id,
        );
        expect(opening.tags, isNotEmpty, reason: opening.id);
        expect(opening.difficulty, inInclusiveRange(1, 5), reason: opening.id);
        expect(
          opening.popularity,
          inInclusiveRange(0, 100),
          reason: opening.id,
        );
      }
    });

    test('jede Eröffnung bringt genug Substanz mit', () {
      for (final opening in index) {
        expect(
          opening.nodeCount,
          greaterThanOrEqualTo(25),
          reason: '${opening.id} hat zu wenige Züge',
        );
        expect(
          opening.lineCount,
          greaterThanOrEqualTo(2),
          reason: '${opening.id} hat zu wenige Varianten',
        );
      }
    });
  });

  group('Variantenbäume', () {
    test('jede PGN ist vollständig legal spielbar', () async {
      final broken = <String>[];

      for (final summary in index) {
        final opening = await repository.opening(summary.id);
        final result = PgnIo.parse(opening.pgn);
        if (result.warnings.isNotEmpty) {
          broken.add('${summary.id}: ${result.warnings.join(' | ')}');
        }
      }

      expect(broken, isEmpty, reason: broken.join('\n'));
    });

    test('der Baum beginnt an der Grundstellung', () async {
      for (final summary in index.take(8)) {
        final tree = await repository.tree(summary.id);
        expect(tree.startFen, RepertoireTree.initialFen, reason: summary.id);
      }
    });

    test('die gemeldete Zahl der Züge stimmt mit dem Baum überein', () async {
      for (final summary in index) {
        final tree = await repository.tree(summary.id);
        expect(tree.nodeCount, summary.nodeCount, reason: summary.id);
        expect(tree.lines(), hasLength(summary.lineCount), reason: summary.id);
      }
    });

    test('die Startfolge steht am Anfang des Baums', () async {
      for (final summary in index) {
        final tree = await repository.tree(summary.id);
        final seed = PgnIo.parse(summary.seedPgn).tree;

        var expected = seed.children.firstOrNull;
        var actual = tree.children.firstOrNull;
        while (expected != null) {
          expect(actual, isNotNull, reason: summary.id);
          expect(actual!.san, expected.san, reason: summary.id);
          expected = expected.children.firstOrNull;
          actual = actual.children.firstOrNull;
        }
      }
    });

    test('benannte Linien tragen ihren Namen als Kommentar', () async {
      final tree = await repository.tree('ruy-lopez');
      final comments = tree
          .walk()
          .map((node) => node.comment)
          .nonNulls
          .toList();

      expect(comments, isNotEmpty);
      expect(comments.any((c) => c.contains('Berlin')), isTrue);
    });
  });

  group('Pläne und typische Fehler', () {
    test('jede Eröffnung nennt Pläne in beiden Sprachen', () async {
      for (final summary in index) {
        final opening = await repository.opening(summary.id);
        expect(opening.plansDe, isNotEmpty, reason: summary.id);
        expect(
          opening.plansEn,
          hasLength(opening.plansDe.length),
          reason: summary.id,
        );
      }
    });

    test('jede Fehler-Linie ist legal und endet mit dem Fehler', () async {
      final broken = <String>[];

      for (final summary in index) {
        final opening = await repository.opening(summary.id);
        expect(opening.mistakes, isNotEmpty, reason: summary.id);

        for (final mistake in opening.mistakes) {
          final result = PgnIo.parse(mistake.pgn);
          if (result.warnings.isNotEmpty) {
            broken.add('${summary.id}: ${result.warnings.join(' | ')}');
          }
          expect(mistake.whyDe, isNotEmpty, reason: summary.id);
          expect(mistake.whyEn, isNotEmpty, reason: summary.id);
          // Eine Fehlerlinie ohne Verzweigung — der letzte Zug ist der Fehler.
          expect(result.tree.lines(), hasLength(1), reason: summary.id);
        }
      }

      expect(broken, isEmpty, reason: broken.join('\n'));
    });
  });

  test('das Symbolfeld liefert die Stellung nach der Startfolge', () async {
    final italian = index.firstWhere((o) => o.id == 'italian-game');
    final fen = await repository.iconFen(italian);

    // Nach 1. e4 e5 2. Sf3 Sc6 3. Lc4 steht der Läufer auf c4.
    expect(fen, startsWith('r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP'));
  });

  test('alle Dateien im Asset-Ordner gehören zum Index', () {
    final dir = Directory('assets/data/openings');
    final files = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.json'))
        .toSet();

    final expected = {'index.json', for (final o in index) '${o.id}.json'};
    expect(files, expected);
  });
}
