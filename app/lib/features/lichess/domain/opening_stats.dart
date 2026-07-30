import 'package:dartchess/dartchess.dart' show Side;
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:meta/meta.dart';

/// Wie eine Eröffnungsfamilie in den eigenen Partien abgeschnitten hat.
@immutable
class OpeningStat {
  const OpeningStat({
    required this.family,
    required this.side,
    required this.eco,
    required this.wins,
    required this.draws,
    required this.losses,
    this.inRepertoire = false,
  });

  /// Der Name ohne Variantenzusatz — „Sizilianisch" statt „Sizilianisch:
  /// Najdorf, englischer Angriff". Auf Variantenebene hätte man nach fünfzig
  /// Partien fünfzig Zeilen mit je einer Partie.
  final String family;

  /// Die Farbe, mit der gespielt wurde.
  final Side side;

  /// Der häufigste ECO-Code dieser Familie.
  final String eco;

  final int wins;
  final int draws;
  final int losses;

  /// Ob ein Repertoire dieser Farbe diese Familie abdeckt.
  final bool inRepertoire;

  int get games => wins + draws + losses;

  /// Punkte je Partie: Sieg 1, Remis 0,5.
  double get score => games == 0 ? 0 : (wins + draws / 2) / games;

  OpeningStat copyWith({bool? inRepertoire}) => OpeningStat(
    family: family,
    side: side,
    eco: eco,
    wins: wins,
    draws: draws,
    losses: losses,
    inRepertoire: inRepertoire ?? this.inRepertoire,
  );
}

/// Fasst die importierten Partien nach Eröffnungsfamilie zusammen.
abstract final class OpeningStats {
  /// Familien mit weniger Partien als hier landen unter „Sonstige" — eine
  /// einzelne Partie sagt über die Eröffnung nichts.
  static const minGames = 2;

  /// Der Familienname zu einem Lichess-Eröffnungsnamen.
  static String familyOf(String? name) {
    if (name == null || name.isEmpty) return unknownFamily;
    final cut = name.indexOf(':');
    return cut == -1 ? name.trim() : name.substring(0, cut).trim();
  }

  /// Für Partien, die Lichess keiner Eröffnung zuordnet.
  static const unknownFamily = '?';

  /// Auswertung, häufigste Familie zuerst.
  ///
  /// [minGames] lässt sich absenken, solange erst wenige Partien importiert
  /// sind — sonst stünde der Tab lange leer.
  static List<OpeningStat> from(
    List<LichessGame> games, {
    Side? side,
    int threshold = minGames,
  }) {
    final buckets = <String, _Bucket>{};

    for (final game in games) {
      if (side != null && game.side != side) continue;

      final family = familyOf(game.openingName);
      if (family == unknownFamily) continue;

      buckets
          .putIfAbsent(
            '${game.side.name}|$family',
            () => _Bucket(family: family, side: game.side),
          )
          .add(game);
    }

    return [
      for (final bucket in buckets.values)
        if (bucket.games >= threshold) bucket.toStat(),
    ]..sort((a, b) {
      final byGames = b.games.compareTo(a.games);
      return byGames != 0 ? byGames : a.family.compareTo(b.family);
    });
  }

  /// Die Familien, in denen es am schlechtesten läuft — der Ausgangspunkt für
  /// „Repertoire reparieren".
  ///
  /// Sortiert nach Punktverlust in absoluten Punkten, nicht nach Quote: drei
  /// Niederlagen in einer oft gespielten Eröffnung wiegen schwerer als eine
  /// einzelne in einer seltenen.
  static List<OpeningStat> weakest(List<OpeningStat> stats, {int take = 5}) {
    final sorted = [...stats]
      ..sort((a, b) {
        final lostA = a.games * (1 - a.score);
        final lostB = b.games * (1 - b.score);
        return lostB.compareTo(lostA);
      });
    return sorted.take(take).toList();
  }
}

class _Bucket {
  _Bucket({required this.family, required this.side});

  final String family;
  final Side side;

  final Map<String, int> _ecoCounts = {};
  int wins = 0;
  int draws = 0;
  int losses = 0;

  int get games => wins + draws + losses;

  void add(LichessGame game) {
    switch (game.outcome) {
      case GameOutcome.win:
        wins++;
      case GameOutcome.draw:
        draws++;
      case GameOutcome.loss:
        losses++;
    }
    if (game.eco case final eco? when eco.isNotEmpty) {
      _ecoCounts[eco] = (_ecoCounts[eco] ?? 0) + 1;
    }
  }

  OpeningStat toStat() {
    final eco = _ecoCounts.entries.fold<MapEntry<String, int>?>(
      null,
      (best, entry) => best == null || entry.value > best.value ? entry : best,
    );

    return OpeningStat(
      family: family,
      side: side,
      eco: eco?.key ?? '',
      wins: wins,
      draws: draws,
      losses: losses,
    );
  }
}
