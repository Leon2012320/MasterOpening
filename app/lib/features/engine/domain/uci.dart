import 'package:meta/meta.dart';

/// Die Bewertung einer Stellung, wie die Engine sie meldet.
@immutable
class EngineEvaluation {
  const EngineEvaluation({
    required this.depth,
    this.centipawns,
    this.mateIn,
    this.pv = const [],
  });

  final int depth;

  /// Hundertstel Bauern aus Sicht der Seite am Zug. `null` bei einem Matt.
  final int? centipawns;

  /// Züge bis zum Matt, negativ, wenn die Seite am Zug matt gesetzt wird.
  final int? mateIn;

  /// Die Hauptvariante in UCI-Zügen.
  final List<String> pv;

  String? get bestMove => pv.firstOrNull;

  bool get isMate => mateIn != null;

  /// Die Bewertung aus Sicht von Weiß — so wird sie üblicherweise angezeigt.
  EngineEvaluation fromWhitePerspective({required bool whiteToMove}) {
    if (whiteToMove) return this;
    return EngineEvaluation(
      depth: depth,
      centipawns: centipawns == null ? null : -centipawns!,
      mateIn: mateIn == null ? null : -mateIn!,
      pv: pv,
    );
  }

  /// Der übliche Text: `+1.35` oder `#3`.
  String format() {
    if (mateIn case final mate?) {
      return '#${mate.abs()}';
    }
    final pawns = (centipawns ?? 0) / 100;
    final sign = pawns >= 0 ? '+' : '';
    return '$sign${pawns.toStringAsFixed(2)}';
  }
}

/// Das UCI-Protokoll: Befehle bauen, Antworten lesen.
///
/// Rein textlich und ohne Prozess — hier stecken die Eigenheiten des
/// Protokolls, und die lassen sich nur prüfen, wenn keine native Engine
/// dazwischensteht.
abstract final class Uci {
  /// Der Befehl, der eine Stellung setzt.
  ///
  /// Die Zugliste hinter der Stellung ist nicht bloß Bequemlichkeit: nur so
  /// kennt die Engine den Verlauf und erkennt Stellungswiederholungen.
  static String position({
    required String fen,
    List<String> moves = const [],
  }) {
    final base = fen == startFen ? 'position startpos' : 'position fen $fen';
    return moves.isEmpty ? base : '$base moves ${moves.join(' ')}';
  }

  static const startFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  static String goMoveTime(Duration time) =>
      'go movetime ${time.inMilliseconds}';

  static String goDepth(int depth) => 'go depth $depth';

  /// Setzt die Spielstärke.
  ///
  /// Stockfish spielt ohne Begrenzung weit über jedem Menschen; erst
  /// `UCI_LimitStrength` macht ihn zu einem Gegner, an dem man etwas lernt.
  /// Unter 1320 tut die Begrenzung nichts mehr — dort ist der Boden.
  static List<String> setStrength(int elo) {
    final clamped = elo.clamp(minElo, maxElo);
    return [
      'setoption name UCI_LimitStrength value true',
      'setoption name UCI_Elo value $clamped',
    ];
  }

  static const minElo = 1320;
  static const maxElo = 3190;

  static const unlimitedStrength =
      'setoption name UCI_LimitStrength value false';

  /// Liest eine `info`-Zeile. `null`, wenn sie keine Bewertung enthält —
  /// Stockfish schickt auch reine Fortschrittsmeldungen.
  static EngineEvaluation? parseInfo(String line) {
    if (!line.startsWith('info ')) return null;

    final tokens = line.split(RegExp(r'\s+'));

    int? depth;
    int? centipawns;
    int? mateIn;
    var pv = const <String>[];

    for (var i = 0; i < tokens.length; i++) {
      switch (tokens[i]) {
        case 'depth':
          depth = _intAt(tokens, i + 1);
        case 'score':
          final kind = _at(tokens, i + 1);
          final value = _intAt(tokens, i + 2);
          if (kind == 'cp') centipawns = value;
          if (kind == 'mate') mateIn = value;
        case 'pv':
          // `pv` steht immer am Ende der Zeile.
          pv = tokens.sublist(i + 1).where((t) => t.isNotEmpty).toList();
          i = tokens.length;
      }
    }

    if (depth == null || (centipawns == null && mateIn == null)) return null;

    return EngineEvaluation(
      depth: depth,
      centipawns: centipawns,
      mateIn: mateIn,
      pv: pv,
    );
  }

  /// Liest den Zug aus einer `bestmove`-Zeile.
  ///
  /// `bestmove (none)` kommt in matten oder patten Stellungen — dort gibt es
  /// keinen Zug, und das ist kein Fehler.
  static String? parseBestMove(String line) {
    if (!line.startsWith('bestmove')) return null;

    final tokens = line.split(RegExp(r'\s+'));
    final move = _at(tokens, 1);

    if (move == null || move == '(none)' || move == '0000') return null;
    return move;
  }

  static bool isReady(String line) => line.trim() == 'readyok';
  static bool isUciOk(String line) => line.trim() == 'uciok';

  static String? _at(List<String> tokens, int index) =>
      index < tokens.length ? tokens[index] : null;

  static int? _intAt(List<String> tokens, int index) {
    final value = _at(tokens, index);
    return value == null ? null : int.tryParse(value);
  }
}
