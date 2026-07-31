import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/features/antiprep/domain/scout_builder.dart';
import 'package:masteropening/features/antiprep/domain/scout_report.dart';
import 'package:masteropening/features/lichess/data/lichess_api.dart';
import 'package:masteropening/features/lichess/data/lichess_token_store.dart';
import 'package:masteropening/features/lichess/domain/game_import.dart';
import 'package:masteropening/features/lichess/domain/lichess_oauth.dart';

/// Späht einen Gegner aus: seine öffentlichen Partien holen, daraus seinen
/// Eröffnungsbaum bauen, das Ergebnis aufbewahren.
///
/// Der Bericht wird gespeichert, weil das Holen von hundert Partien dauert
/// und sich das Repertoire eines Menschen nicht über Nacht ändert.
class AntiPrepRepository {
  AntiPrepRepository({
    required this._db,
    LichessApi? api,
    LichessTokenStore? tokens,
  }) : _api = api ?? LichessApi(),
       _tokens = tokens ?? const SecureLichessTokenStore();

  /// Mehr Partien machen den Bericht kaum genauer, dauern aber spürbar.
  static const defaultMaxGames = 120;

  final AppDatabase _db;
  final LichessApi _api;
  final LichessTokenStore _tokens;

  /// Ein früher erstellter Bericht, ohne das Netz zu befragen.
  Future<ScoutReport?> cached(String username) async {
    final row = await (_db.select(
      _db.opponentScouts,
    )..where((s) => s.username.equals(_normalise(username)))).getSingleOrNull();
    if (row == null) return null;

    final decoded = jsonDecode(row.reportJson);
    if (decoded is! Map<String, dynamic>) return null;
    return ScoutReport.fromJson(decoded);
  }

  /// Die zuletzt ausgespähten Gegner, jüngste zuerst.
  Future<List<OpponentScout>> recent({int limit = 10}) {
    return (_db.select(_db.opponentScouts)
          ..orderBy([
            (s) =>
                OrderingTerm(expression: s.analysedAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
  }

  /// Holt die Partien und baut den Bericht neu.
  Future<ScoutReport> scout(
    String username, {
    int maxGames = defaultMaxGames,
    DateTime? now,
  }) async {
    final name = _normalise(username);
    if (name.isEmpty) {
      throw const LichessAuthException('Kein Benutzername angegeben');
    }

    final token = await _tokens.read();
    if (token == null) {
      throw const LichessAuthException('Nicht mit Lichess verbunden');
    }

    final timestamp = now ?? DateTime.now();
    final games = <ScoutedGame>[];

    await for (final json in _api.streamGames(
      token: token,
      username: name,
      max: maxGames,
    )) {
      // Derselbe Weg wie beim eigenen Import — nur steht hier der Gegner an
      // der Stelle, an der sonst der Nutzer steht.
      final game = GameImport.parse(
        json,
        ownUserId: name,
        importedAt: timestamp,
      );
      if (game == null) continue;

      final moves = PgnIo.mainlineSan(game.pgn);
      if (moves.isEmpty) continue;

      games.add(
        ScoutedGame(
          side: game.side,
          outcome: game.outcome,
          sanMoves: moves,
        ),
      );
    }

    final report = ScoutBuilder.build(
      username: name,
      games: games,
      now: timestamp,
    );

    await _db
        .into(_db.opponentScouts)
        .insertOnConflictUpdate(
          OpponentScout(
            username: name,
            reportJson: jsonEncode(report.toJson()),
            gamesAnalysed: report.gamesAnalysed,
            analysedAt: timestamp,
          ),
        );

    return report;
  }

  Future<void> forget(String username) => (_db.delete(
    _db.opponentScouts,
  )..where((s) => s.username.equals(_normalise(username)))).go();

  /// Lichess führt Konten unter dem kleingeschriebenen Namen.
  static String _normalise(String username) => username.trim().toLowerCase();
}
