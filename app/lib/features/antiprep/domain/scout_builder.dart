import 'package:dartchess/dartchess.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/antiprep/domain/scout_report.dart';

/// Baut aus den Partien eines Gegners seinen Eröffnungsbaum.
///
/// Rein rechnend: die Partien kommen von aussen, hier wird nur gezählt. Das
/// ist der Teil, an dem sich prüfen lässt, ob „er spielt zu 80 % 1.e4" auch
/// wirklich stimmt.
abstract final class ScoutBuilder {
  /// Tiefer als in den Eröffnungsbereich zu zählen bringt nichts: ab dem
  /// zwölften Halbzug hat fast jede Partie ihren eigenen Weg, und der Baum
  /// zerfiele in lauter Äste mit je einer Partie.
  static const defaultMaxPly = 12;

  /// Ein Zug, den er einmal gespielt hat, sagt nichts über seine Gewohnheit —
  /// er soll den Bericht nicht zumüllen.
  static const defaultMinGames = 2;

  static ScoutReport build({
    required String username,
    required List<ScoutedGame> games,
    DateTime? now,
    int maxPly = defaultMaxPly,
    int minGames = defaultMinGames,
  }) {
    return ScoutReport(
      username: username,
      gamesAnalysed: games.length,
      analysedAt: now ?? DateTime.now(),
      asWhite: buildTree(
        games: games,
        side: Side.white,
        maxPly: maxPly,
        minGames: minGames,
      ),
      asBlack: buildTree(
        games: games,
        side: Side.black,
        maxPly: maxPly,
        minGames: minGames,
      ),
    );
  }

  static ScoutTree buildTree({
    required List<ScoutedGame> games,
    required Side side,
    int maxPly = defaultMaxPly,
    int minGames = defaultMinGames,
  }) {
    final relevant = games.where((g) => g.side == side).toList();
    if (relevant.isEmpty) {
      return ScoutTree(side: side, games: 0);
    }

    final root = _Counter(san: '', uci: '', ply: 0);

    for (final game in relevant) {
      Position position = Chess.initial;
      var node = root;

      final limit = game.sanMoves.length < maxPly
          ? game.sanMoves.length
          : maxPly;

      for (var i = 0; i < limit; i++) {
        final move = _parse(position, game.sanMoves[i]);
        // Ein unlesbarer Zug beendet diese Partie, nicht die Auswertung.
        if (move == null) break;

        node = node.child(san: game.sanMoves[i], uci: move.uci, ply: i + 1)
          ..add(game.outcome);

        position = position.play(move);
      }
    }

    return ScoutTree(
      side: side,
      games: relevant.length,
      children: root.toNodes(minGames),
    );
  }

  static Move? _parse(Position position, String san) {
    try {
      return position.parseSan(san);
    } on Object {
      return null;
    }
  }
}

/// Zähler beim Aufbau; der fertige Baum ist unveränderlich.
class _Counter {
  _Counter({required this.san, required this.uci, required this.ply});

  final String san;
  final String uci;
  final int ply;

  int games = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;

  final Map<String, _Counter> _children = {};

  _Counter child({
    required String san,
    required String uci,
    required int ply,
  }) {
    return _children.putIfAbsent(
      uci,
      () => _Counter(san: san, uci: uci, ply: ply),
    );
  }

  void add(GameOutcome outcome) {
    games++;
    switch (outcome) {
      case GameOutcome.win:
        wins++;
      case GameOutcome.draw:
        draws++;
      case GameOutcome.loss:
        losses++;
    }
  }

  List<ScoutNode> toNodes(int minGames) {
    final result = <ScoutNode>[];

    for (final counter in _children.values) {
      if (counter.games < minGames) continue;
      result.add(
        ScoutNode(
          san: counter.san,
          uci: counter.uci,
          ply: counter.ply,
          games: counter.games,
          wins: counter.wins,
          draws: counter.draws,
          losses: counter.losses,
          children: counter.toNodes(minGames),
        ),
      );
    }

    // Häufigstes zuerst — so liest sich der Bericht von oben nach unten wie
    // eine Wahrscheinlichkeit.
    result.sort((a, b) => b.games.compareTo(a.games));
    return result;
  }
}
