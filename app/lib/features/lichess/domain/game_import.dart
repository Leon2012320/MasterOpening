import 'package:dartchess/dartchess.dart' show Side;
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';

/// Wandelt eine Partie aus der Lichess-API in eine Zeile der Datenbank.
///
/// Bewusst eine reine Funktion ohne Netz und ohne Datenbank: an dieser Stelle
/// stecken die Sonderfälle (abgebrochene Partien, Varianten, fehlende
/// Eröffnungsangabe), und die lassen sich nur prüfen, wenn man sie aufrufen
/// kann, ohne einen Server zu befragen.
abstract final class GameImport {
  /// Partien, die nie richtig begonnen haben, sagen über Eröffnungen nichts.
  static const _skippedStatuses = {'aborted', 'noStart'};

  /// Nur Standardschach: eine Eröffnungsstatistik über Atomschach wäre
  /// bestenfalls verwirrend.
  static const _acceptedVariants = {'standard'};

  /// `null`, wenn die Partie nicht zählt.
  static LichessGame? parse(
    Map<String, dynamic> json, {
    required String ownUserId,
    required DateTime importedAt,
  }) {
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) return null;

    final status = json['status'] as String? ?? '';
    if (_skippedStatuses.contains(status)) return null;

    final variant = json['variant'] as String? ?? 'standard';
    if (!_acceptedVariants.contains(variant)) return null;

    final players = json['players'] as Map<String, dynamic>? ?? const {};
    final white = players['white'] as Map<String, dynamic>? ?? const {};
    final black = players['black'] as Map<String, dynamic>? ?? const {};

    final side = switch (ownUserId.toLowerCase()) {
      final own when _userIdOf(white) == own => Side.white,
      final own when _userIdOf(black) == own => Side.black,
      // Eine Partie ohne den Nutzer darin ist ein Fehler im Aufruf, kein Datum.
      _ => null,
    };
    if (side == null) return null;

    final own = side == Side.white ? white : black;
    final opponent = side == Side.white ? black : white;

    final opening = json['opening'] as Map<String, dynamic>? ?? const {};
    final moves = json['moves'] as String? ?? '';

    return LichessGame(
      id: id,
      pgn: json['pgn'] as String? ?? '',
      side: side,
      outcome: outcomeFor(json['winner'] as String?, side),
      speed: speedFor(json['speed'] as String?),
      eco: opening['eco'] as String?,
      openingName: opening['name'] as String?,
      opponentName: _displayNameOf(opponent),
      opponentRating: (opponent['rating'] as num?)?.toInt(),
      ownRating: (own['rating'] as num?)?.toInt(),
      plyCount: moves.isEmpty ? 0 : moves.split(' ').length,
      rated: json['rated'] as bool? ?? false,
      playedAt: switch (json['createdAt']) {
        final num millis => DateTime.fromMillisecondsSinceEpoch(millis.toInt()),
        _ => importedAt,
      },
      importedAt: importedAt,
    );
  }

  /// Ausgang aus Sicht der eigenen Farbe. Ohne Sieger ist es ein Remis —
  /// dazu zählt auch die Partie, die wegen Zeitüberschreitung ohne
  /// Mattmaterial endet.
  static GameOutcome outcomeFor(String? winner, Side side) {
    if (winner == null) return GameOutcome.draw;
    return winner == side.name ? GameOutcome.win : GameOutcome.loss;
  }

  static GameSpeed speedFor(String? speed) {
    return switch (speed) {
      'ultraBullet' => GameSpeed.ultraBullet,
      'bullet' => GameSpeed.bullet,
      'rapid' => GameSpeed.rapid,
      'classical' => GameSpeed.classical,
      'correspondence' => GameSpeed.correspondence,
      // Blitz ist auf Lichess die häufigste Zeitkontrolle und damit der
      // unschädlichste Rückfall.
      _ => GameSpeed.blitz,
    };
  }

  static String? _userIdOf(Map<String, dynamic> player) {
    final user = player['user'] as Map<String, dynamic>?;
    return (user?['id'] as String?)?.toLowerCase();
  }

  static String? _displayNameOf(Map<String, dynamic> player) {
    final user = player['user'] as Map<String, dynamic>?;
    if (user?['name'] case final String name) return name;

    // Ohne Benutzerkonto ist der Gegner ein Computergegner.
    if (player['aiLevel'] case final num level) {
      return 'Stockfish ${level.toInt()}';
    }
    return null;
  }
}
