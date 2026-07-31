import 'package:dartchess/dartchess.dart' show Side;
import 'package:masteropening/core/db/enums.dart';
import 'package:meta/meta.dart';

/// Ein Zug im Eröffnungsbaum eines ausgespähten Gegners.
///
/// Alle Zahlen stehen aus **seiner** Sicht: `wins` sind seine Siege. Beim
/// Lesen ist das der häufigste Stolperstein — deshalb steht es hier.
@immutable
class ScoutNode {
  const ScoutNode({
    required this.san,
    required this.uci,
    required this.ply,
    required this.games,
    required this.wins,
    required this.draws,
    required this.losses,
    this.children = const [],
  });

  factory ScoutNode.fromJson(Map<String, dynamic> json) => ScoutNode(
    san: json['san'] as String,
    uci: json['uci'] as String,
    ply: (json['ply'] as num).toInt(),
    games: (json['games'] as num).toInt(),
    wins: (json['wins'] as num).toInt(),
    draws: (json['draws'] as num).toInt(),
    losses: (json['losses'] as num).toInt(),
    children: [
      for (final child in (json['children'] as List? ?? const []))
        ScoutNode.fromJson(child as Map<String, dynamic>),
    ],
  );

  final String san;
  final String uci;
  final int ply;

  final int games;
  final int wins;
  final int draws;
  final int losses;

  final List<ScoutNode> children;

  /// Seine Punkteausbeute in dieser Stellung.
  double get score => games == 0 ? 0 : (wins + draws / 2) / games;

  /// Wie oft er diesen Zug wählt, gemessen an den Partien der Elternstellung.
  double shareOf(int parentGames) => parentGames == 0 ? 0 : games / parentGames;

  Map<String, dynamic> toJson() => {
    'san': san,
    'uci': uci,
    'ply': ply,
    'games': games,
    'wins': wins,
    'draws': draws,
    'losses': losses,
    if (children.isNotEmpty)
      'children': [for (final child in children) child.toJson()],
  };
}

/// Der Eröffnungsbaum einer Farbe.
@immutable
class ScoutTree {
  const ScoutTree({
    required this.side,
    required this.games,
    this.children = const [],
  });

  factory ScoutTree.fromJson(Map<String, dynamic> json) => ScoutTree(
    side: json['side'] == 'black' ? Side.black : Side.white,
    games: (json['games'] as num).toInt(),
    children: [
      for (final child in (json['children'] as List? ?? const []))
        ScoutNode.fromJson(child as Map<String, dynamic>),
    ],
  );

  /// Die Farbe, die der Gegner in diesen Partien hatte.
  final Side side;

  /// Wie viele Partien in den Baum eingegangen sind.
  final int games;

  final List<ScoutNode> children;

  bool get isEmpty => children.isEmpty;

  Map<String, dynamic> toJson() => {
    'side': side.name,
    'games': games,
    'children': [for (final child in children) child.toJson()],
  };
}

/// Alles, was über einen Gegner zusammengetragen wurde.
@immutable
class ScoutReport {
  const ScoutReport({
    required this.username,
    required this.gamesAnalysed,
    required this.analysedAt,
    required this.asWhite,
    required this.asBlack,
  });

  factory ScoutReport.fromJson(Map<String, dynamic> json) => ScoutReport(
    username: json['username'] as String,
    gamesAnalysed: (json['gamesAnalysed'] as num).toInt(),
    analysedAt: DateTime.parse(json['analysedAt'] as String),
    asWhite: ScoutTree.fromJson(json['asWhite'] as Map<String, dynamic>),
    asBlack: ScoutTree.fromJson(json['asBlack'] as Map<String, dynamic>),
  );

  final String username;
  final int gamesAnalysed;
  final DateTime analysedAt;

  final ScoutTree asWhite;
  final ScoutTree asBlack;

  /// Der Baum der Farbe, die er gegen dich hat.
  ///
  /// Wer sich mit Weiß vorbereitet, will wissen, was der Gegner mit Schwarz
  /// tut — nicht umgekehrt.
  ScoutTree against(Side ownSide) => ownSide == Side.white ? asBlack : asWhite;

  Map<String, dynamic> toJson() => {
    'username': username,
    'gamesAnalysed': gamesAnalysed,
    'analysedAt': analysedAt.toUtc().toIso8601String(),
    'asWhite': asWhite.toJson(),
    'asBlack': asBlack.toJson(),
  };
}

/// Eine Partie, wie sie in die Auswertung eingeht.
@immutable
class ScoutedGame {
  const ScoutedGame({
    required this.side,
    required this.outcome,
    required this.sanMoves,
  });

  /// Die Farbe des ausgespähten Spielers.
  final Side side;

  /// Der Ausgang aus **seiner** Sicht.
  final GameOutcome outcome;

  final List<String> sanMoves;
}
