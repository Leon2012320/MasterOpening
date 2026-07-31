import 'dart:async';
import 'dart:io' show Platform;

import 'package:masteropening/features/engine/domain/engine_service.dart';
import 'package:stockfish/stockfish.dart';

/// Stockfish als UCI-Prozess.
///
/// Das Paket liefert die Engine als native Bibliothek mit und spricht über
/// zwei Ströme mit ihr — dieselbe Schnittstelle, die auch ein echter Prozess
/// hätte, weshalb hier nichts weiter zu tun ist als durchzureichen.
class StockfishTransport implements UciTransport {
  Stockfish? _engine;
  final _lines = StreamController<String>.broadcast();
  StreamSubscription<String>? _subscription;

  /// Auf welchen Plattformen die mitgelieferte Bibliothek vorliegt.
  ///
  /// Das Paket bringt nur für Android und iOS eine native Bibliothek mit.
  /// Auf Windows und Linux gibt es keine — und ein Absturz beim Laden wäre
  /// schlimmer als eine App ohne Engine.
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> start() async {
    if (_engine != null) return;

    // `stockfishAsync` liefert die Instanz erst, wenn sie bereit ist; vorher
    // wirft jeder Befehl. Das erspart eigenes Warten auf den Zustand.
    final engine = await stockfishAsync().timeout(_startTimeout);

    _engine = engine;
    _subscription = engine.stdout.listen(_lines.add);
  }

  static const _startTimeout = Duration(seconds: 20);

  @override
  Stream<String> get lines => _lines.stream;

  @override
  void send(String command) {
    final engine = _engine;
    if (engine == null) return;
    if (engine.state.value != StockfishState.ready) return;

    engine.stdin = command;
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    if (!_lines.isClosed) await _lines.close();

    // `dispose` schreibt `quit` in die Engine und wirft, wenn sie nicht
    // bereit ist — beim Aufräumen ist das kein Grund für eine Ausnahme.
    final engine = _engine;
    _engine = null;
    if (engine != null && engine.state.value == StockfishState.ready) {
      engine.dispose();
    }
  }
}

/// Die Engine dieser Plattform — oder eine, die es nicht gibt.
EngineService createEngineService() {
  if (!StockfishTransport.isSupported) return const NoopEngineService();
  return UciEngineService(StockfishTransport());
}
