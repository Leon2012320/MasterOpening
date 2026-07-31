import 'dart:convert';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/antiprep/domain/prep_sheet.dart';
import 'package:masteropening/features/antiprep/domain/scout_builder.dart';
import 'package:masteropening/features/antiprep/domain/scout_report.dart';

ScoutedGame game(
  List<String> moves, {
  Side side = Side.white,
  GameOutcome outcome = GameOutcome.win,
}) {
  return ScoutedGame(side: side, outcome: outcome, sanMoves: moves);
}

void main() {
  group('Eröffnungsbaum eines Gegners', () {
    test('zählt Züge und Ergebnisse aus seiner Sicht', () {
      final tree = ScoutBuilder.buildTree(
        games: [
          game(['e4', 'e5']),
          game(['e4', 'c5'], outcome: GameOutcome.loss),
          game(['e4', 'e6'], outcome: GameOutcome.draw),
          game(['d4', 'd5']),
        ],
        side: Side.white,
        minGames: 1,
      );

      expect(tree.games, 4);

      final e4 = tree.children.first;
      expect(e4.san, 'e4');
      expect(e4.games, 3, reason: 'dreimal 1.e4');
      expect(e4.wins, 1);
      expect(e4.draws, 1);
      expect(e4.losses, 1);
      expect(e4.score, 0.5);
      expect(e4.shareOf(tree.games), closeTo(0.75, 0.001));
    });

    test('häufigstes zuerst', () {
      final tree = ScoutBuilder.buildTree(
        games: [
          game(['d4']),
          game(['e4']),
          game(['e4']),
          game(['e4']),
        ],
        side: Side.white,
        minGames: 1,
      );

      expect([for (final node in tree.children) node.san], ['e4', 'd4']);
    });

    test('Einzelfälle fallen unter die Schwelle', () {
      final tree = ScoutBuilder.buildTree(
        games: [
          game(['e4']),
          game(['e4']),
          game(['b4']),
        ],
        side: Side.white,
      );

      expect([for (final node in tree.children) node.san], ['e4']);
    });

    test('Partien der anderen Farbe zählen nicht mit', () {
      final tree = ScoutBuilder.buildTree(
        games: [
          game(['e4'], side: Side.black),
          game(['e4']),
          game(['e4']),
        ],
        side: Side.white,
        minGames: 1,
      );

      expect(tree.games, 2);
    });

    test('ein unlesbarer Zug beendet nur diese Partie', () {
      final tree = ScoutBuilder.buildTree(
        games: [
          game(['e4', 'Qh9', 'Nf3']),
          game(['e4', 'e5']),
        ],
        side: Side.white,
        minGames: 1,
      );

      expect(tree.children.single.games, 2, reason: '1.e4 zählt zweimal');
      expect(tree.children.single.children.single.san, 'e5');
    });

    test('der Bericht trennt beide Farben', () {
      final report = ScoutBuilder.build(
        username: 'gegner',
        games: [
          game(['e4']),
          game(['e4']),
          game(['e4', 'c5'], side: Side.black),
          game(['e4', 'c5'], side: Side.black),
        ],
        now: DateTime.utc(2026, 7, 31),
      );

      expect(report.gamesAnalysed, 4);
      expect(report.asWhite.games, 2);
      expect(report.asBlack.games, 2);

      // Wer Weiß hat, will wissen, was der Gegner mit Schwarz tut.
      expect(report.against(Side.white).side, Side.black);
    });

    test('übersteht den Weg durch JSON', () {
      final original = ScoutBuilder.build(
        username: 'gegner',
        games: [
          game(['e4', 'c5']),
          game(['e4', 'c5']),
        ],
        now: DateTime.utc(2026, 7, 31),
      );

      final restored = ScoutReport.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.username, 'gegner');
      expect(restored.gamesAnalysed, 2);
      expect(restored.asWhite.children.single.san, 'e4');
      expect(restored.analysedAt, original.analysedAt);
    });
  });

  group('Vorbereitungsblatt', () {
    ScoutTree tree() => ScoutBuilder.buildTree(
      games: [
        // Er spielt fast immer 1.e4, verliert damit aber gegen 1…c5.
        for (var i = 0; i < 6; i++)
          game(['e4', 'c5', 'Nf3'], outcome: GameOutcome.loss),
        for (var i = 0; i < 3; i++) game(['e4', 'e5', 'Nf3']),
        game(['d4', 'd5', 'c4']),
        game(['d4', 'd5', 'c4']),
      ],
      side: Side.white,
      minGames: 1,
    );

    test('die häufigste Folge steht oben', () {
      final lines = PrepSheet.mostLikely(tree(), depth: 3);

      expect(lines.first.moves.map((m) => m.san), ['e4', 'c5', 'Nf3']);
      expect(lines.first.games, 6);
    });

    test('die teuerste Folge steht oben, nicht die schlechteste Quote', () {
      final lines = PrepSheet.weakest(tree(), depth: 3);

      expect(lines.first.moves.map((m) => m.san), ['e4', 'c5', 'Nf3']);
      expect(lines.first.pointsHeDrops, 6.0);
    });

    test('misst, wie weit das eigene Repertoire mitgeht', () {
      final repertoire = const RepertoireTree.empty().withSanLine([
        'e4',
        'c5',
        'Nf3',
        'd6',
      ]);

      final lines = PrepSheet.mostLikely(
        tree(),
        repertoire: repertoire,
        depth: 3,
      );

      final sicilian = lines.firstWhere(
        (line) => line.moves.map((m) => m.san).join(' ') == 'e4 c5 Nf3',
      );
      expect(sicilian.coveredPly, 3);
      expect(sicilian.isCovered, isTrue);
    });

    test('nennt die Folgen, auf die nichts vorbereitet ist', () {
      final repertoire = const RepertoireTree.empty().withSanLine([
        'e4',
        'c5',
        'Nf3',
      ]);

      final uncovered = PrepSheet.uncovered(
        tree(),
        repertoire: repertoire,
        depth: 3,
      );

      final sans = [
        for (final line in uncovered) line.moves.map((m) => m.san).join(' '),
      ];

      expect(sans, isNot(contains('e4 c5 Nf3')));
      expect(sans, contains('e4 e5 Nf3'));
    });

    test('der Ansatzpunkt zum Üben ist der tiefste bekannte Knoten', () {
      final repertoire = const RepertoireTree.empty().withSanLine([
        'e4',
        'c5',
        'Nf3',
      ]);
      final expected = repertoire.nodeAtUciPath(['e2e4', 'c7c5', 'g1f3'])!;

      final line = PrepSheet.mostLikely(
        tree(),
        repertoire: repertoire,
        depth: 3,
      ).first;

      expect(PrepSheet.drillTarget(repertoire, line), expected.pathHash);
    });

    test('ohne Berührung gibt es keinen Ansatzpunkt', () {
      final repertoire = const RepertoireTree.empty().withSanLine(['d4', 'd5']);

      final line = PrepSheet.mostLikely(tree(), depth: 3).first;
      expect(PrepSheet.drillTarget(repertoire, line), isNull);
    });
  });
}
