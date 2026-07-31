import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/features/engine/domain/engine_service.dart';
import 'package:masteropening/features/engine/domain/uci.dart';

/// Eine Engine aus Papier: nimmt Befehle entgegen und antwortet nach Skript.
class _FakeTransport implements UciTransport {
  final _lines = StreamController<String>.broadcast();
  final sent = <String>[];

  bool started = false;
  bool disposed = false;

  /// Was auf `go …` geantwortet wird.
  List<String> searchReply = const [
    'info depth 12 score cp 34 pv e2e4 e7e5',
    'bestmove e2e4 ponder e7e5',
  ];

  @override
  Future<void> start() async => started = true;

  @override
  Stream<String> get lines => _lines.stream;

  @override
  void send(String command) {
    sent.add(command);

    if (command == 'uci') {
      _emit(['id name FakeFish', 'uciok']);
    } else if (command == 'isready') {
      _emit(['readyok']);
    } else if (command.startsWith('go')) {
      _emit(searchReply);
    }
  }

  void _emit(List<String> replies) {
    // Antworten kommen nie im selben Mikrotask wie der Befehl — sonst wäre
    // der Zuhörer noch nicht dran.
    scheduleMicrotask(() {
      for (final line in replies) {
        if (!_lines.isClosed) _lines.add(line);
      }
    });
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _lines.close();
  }
}

void main() {
  group('UCI-Befehle', () {
    test('die Ausgangsstellung heisst startpos', () {
      expect(Uci.position(fen: Uci.startFen), 'position startpos');
      expect(
        Uci.position(fen: Uci.startFen, moves: ['e2e4', 'e7e5']),
        'position startpos moves e2e4 e7e5',
      );
    });

    test('jede andere Stellung geht als FEN hinaus', () {
      const fen =
          'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2';
      expect(Uci.position(fen: fen), 'position fen $fen');
    });

    test('die Spielstärke wird auf den Bereich der Engine begrenzt', () {
      expect(
        Uci.setStrength(500),
        contains('setoption name UCI_Elo value ${Uci.minElo}'),
      );
      expect(
        Uci.setStrength(9000),
        contains('setoption name UCI_Elo value ${Uci.maxElo}'),
      );
      expect(
        Uci.setStrength(1800),
        contains('setoption name UCI_LimitStrength value true'),
      );
    });
  });

  group('UCI-Antworten', () {
    test('liest Tiefe, Bewertung und Hauptvariante', () {
      final info = Uci.parseInfo(
        'info depth 18 seldepth 24 multipv 1 score cp -42 nodes 1000 '
        'pv d2d4 d7d5 c2c4',
      );

      expect(info, isNotNull);
      expect(info!.depth, 18);
      expect(info.centipawns, -42);
      expect(info.pv, ['d2d4', 'd7d5', 'c2c4']);
      expect(info.bestMove, 'd2d4');
    });

    test('erkennt ein Matt', () {
      final info = Uci.parseInfo('info depth 20 score mate 3 pv f3f7');

      expect(info!.isMate, isTrue);
      expect(info.mateIn, 3);
      expect(info.format(), '#3');
    });

    test('Zeilen ohne Bewertung ergeben nichts', () {
      expect(
        Uci.parseInfo('info depth 1 currmove e2e4 currmovenumber 1'),
        isNull,
      );
      expect(Uci.parseInfo('bestmove e2e4'), isNull);
    });

    test('formatiert Bauerneinheiten mit Vorzeichen', () {
      const positive = EngineEvaluation(depth: 10, centipawns: 135);
      const negative = EngineEvaluation(depth: 10, centipawns: -80);

      expect(positive.format(), '+1.35');
      expect(negative.format(), '-0.80');
    });

    test('dreht die Bewertung auf die Sicht von Weiß', () {
      const fromBlack = EngineEvaluation(depth: 10, centipawns: 50);
      final fromWhite = fromBlack.fromWhitePerspective(whiteToMove: false);

      expect(fromWhite.centipawns, -50);
    });

    test('liest den besten Zug', () {
      expect(Uci.parseBestMove('bestmove g1f3 ponder d7d5'), 'g1f3');
    });

    test('in matter Stellung gibt es keinen Zug', () {
      expect(Uci.parseBestMove('bestmove (none)'), isNull);
      expect(Uci.parseBestMove('bestmove 0000'), isNull);
    });
  });

  group('Engine-Dienst', () {
    test('meldet sich an, bevor er sucht', () async {
      final transport = _FakeTransport();
      final engine = UciEngineService(transport);

      final move = await engine.bestMove(
        fen: Uci.startFen,
        elo: 1800,
        moveTime: const Duration(milliseconds: 10),
      );

      expect(move, 'e2e4');
      expect(transport.started, isTrue);
      expect(transport.sent.take(2), ['uci', 'isready']);
      expect(
        transport.sent,
        contains('setoption name UCI_Elo value 1800'),
      );

      await engine.dispose();
    });

    test('liefert die tiefste Bewertung vor dem Zug', () async {
      final transport = _FakeTransport()
        ..searchReply = const [
          'info depth 4 score cp 10 pv e2e4',
          'info depth 12 score cp 34 pv d2d4 d7d5',
          'bestmove d2d4',
        ];
      final engine = UciEngineService(transport);

      final evaluation = await engine.evaluate(
        fen: Uci.startFen,
        moveTime: const Duration(milliseconds: 10),
      );

      expect(evaluation!.depth, 12);
      expect(evaluation.centipawns, 34);

      await engine.dispose();
    });

    test('startet nur einmal, auch bei mehreren Anfragen', () async {
      final transport = _FakeTransport();
      final engine = UciEngineService(transport);

      await engine.bestMove(
        fen: Uci.startFen,
        elo: 1500,
        moveTime: const Duration(milliseconds: 10),
      );
      await engine.bestMove(
        fen: Uci.startFen,
        elo: 1500,
        moveTime: const Duration(milliseconds: 10),
      );

      expect(transport.sent.where((c) => c == 'uci'), hasLength(1));

      await engine.dispose();
    });

    test('die Attrappe verhält sich wie eine fehlende Engine', () async {
      const engine = NoopEngineService();

      expect(engine.isAvailable, isFalse);
      expect(await engine.evaluate(fen: Uci.startFen), isNull);
      expect(await engine.bestMove(fen: Uci.startFen, elo: 1600), isNull);
    });
  });
}
