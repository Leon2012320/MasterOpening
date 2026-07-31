import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/library/domain/library_opening.dart';
import 'package:masteropening/features/style/domain/style_profile.dart';

({List<OpeningTag> tags, GameOutcome outcome}) played(
  List<OpeningTag> tags, {
  GameOutcome outcome = GameOutcome.win,
}) => (tags: tags, outcome: outcome);

LibraryOpeningSummary opening(
  String id,
  List<OpeningTag> tags, {
  int popularity = 50,
}) {
  return LibraryOpeningSummary(
    id: id,
    eco: 'B00',
    side: Side.white,
    seedPgn: '1. e4 *',
    tags: tags,
    difficulty: 3,
    popularity: popularity,
    nodeCount: 10,
    lineCount: 2,
    nameDe: id,
    nameEn: id,
    summaryDe: '',
    summaryEn: '',
  );
}

void main() {
  group('Stilbild', () {
    test('Angriffseröffnungen schlagen auf die Angriffsachse', () {
      final profile = StyleAnalyser.analyse(
        games: [
          for (var i = 0; i < 12; i++)
            played([OpeningTag.attacking, OpeningTag.gambit]),
        ],
      );

      expect(profile.valueOf(StyleAxis.aggression), greaterThan(0.8));
      expect(profile.scores[StyleAxis.aggression]!.isReliable, isTrue);
    });

    test('solide Eröffnungen schlagen in die andere Richtung', () {
      final profile = StyleAnalyser.analyse(
        games: [
          for (var i = 0; i < 12; i++) played([OpeningTag.solid]),
        ],
      );

      expect(profile.valueOf(StyleAxis.aggression), lessThan(-0.8));
    });

    test('ohne Partien bleibt alles bei null', () {
      final profile = StyleAnalyser.analyse(games: const []);

      expect(profile.isEmpty, isTrue);
      expect(profile.valueOf(StyleAxis.tactics), 0);
    });

    test('wenige Partien ergeben einen unsicheren Wert', () {
      final profile = StyleAnalyser.analyse(
        games: [
          played([OpeningTag.tactical]),
        ],
      );

      expect(profile.scores[StyleAxis.tactics]!.isReliable, isFalse);
    });

    test('Gewonnenes zählt mehr als Verlorenes', () {
      final mostlyWon = StyleAnalyser.analyse(
        games: [
          for (var i = 0; i < 5; i++) played([OpeningTag.attacking]),
          played([OpeningTag.solid], outcome: GameOutcome.loss),
        ],
      );
      final mostlyLost = StyleAnalyser.analyse(
        games: [
          for (var i = 0; i < 5; i++)
            played([OpeningTag.attacking], outcome: GameOutcome.loss),
          played([OpeningTag.solid]),
        ],
      );

      expect(
        mostlyWon.valueOf(StyleAxis.aggression),
        greaterThan(mostlyLost.valueOf(StyleAxis.aggression)),
      );
    });

    test('der Balkenstand liegt zwischen 0 und 1', () {
      const extreme = StyleScore(
        axis: StyleAxis.openness,
        value: 1,
        samples: 20,
      );
      const middle = StyleScore(
        axis: StyleAxis.openness,
        value: 0,
        samples: 20,
      );

      expect(extreme.position, 1.0);
      expect(middle.position, 0.5);
    });
  });

  group('Empfehlung', () {
    test('passendes bekommt eine höhere Übereinstimmung', () {
      final profile = StyleAnalyser.analyse(
        games: [
          for (var i = 0; i < 12; i++) played([OpeningTag.attacking]),
        ],
      );

      final matchingScore = StyleAnalyser.matchFor(profile, [
        OpeningTag.attacking,
      ]);
      final opposedScore = StyleAnalyser.matchFor(profile, [OpeningTag.solid]);

      expect(matchingScore, greaterThan(opposedScore));
    });

    test('ohne Merkmale gibt es keine Übereinstimmung', () {
      final profile = StyleAnalyser.analyse(
        games: [
          played([OpeningTag.attacking]),
        ],
      );

      expect(StyleAnalyser.matchFor(profile, const []), 0);
    });

    test('schlägt vor, was noch nicht im Repertoire steht', () {
      final profile = StyleAnalyser.analyse(
        games: [
          for (var i = 0; i < 12; i++) played([OpeningTag.attacking]),
        ],
      );

      final suggestions = StyleAnalyser.suggest(
        profile: profile,
        library: [
          opening('koenigsgambit', [OpeningTag.attacking, OpeningTag.gambit]),
          opening('londoner', [OpeningTag.solid, OpeningTag.system]),
          opening('schon-drin', [OpeningTag.attacking]),
        ],
        alreadyInRepertoire: {'schon-drin'},
      );

      final ids = [for (final s in suggestions) s.opening.id];
      expect(ids, isNot(contains('schon-drin')));
      expect(ids.first, 'koenigsgambit');
    });

    test('bei gleicher Passung gewinnt die bekanntere Eröffnung', () {
      final profile = StyleAnalyser.analyse(
        games: [
          for (var i = 0; i < 12; i++) played([OpeningTag.open]),
        ],
      );

      final suggestions = StyleAnalyser.suggest(
        profile: profile,
        library: [
          opening('selten', [OpeningTag.open], popularity: 10),
          opening('bekannt', [OpeningTag.open], popularity: 90),
        ],
        alreadyInRepertoire: const {},
      );

      expect(suggestions.first.opening.id, 'bekannt');
    });
  });
}
