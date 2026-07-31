import 'dart:async';

import 'package:masteropening/features/engine/domain/uci.dart';

/// Die Verbindung zu einem UCI-Prozess: Zeilen hinein, Zeilen heraus.
///
/// Diese Trennung ist der Grund, warum sich das Protokoll prüfen lässt, ohne
/// eine native Engine zu starten — im Test steht hier ein Stück Dart, das
/// Antworten nachspielt.
abstract interface class UciTransport {
  /// Wird erst bei Bedarf gestartet: eine Engine, die niemand braucht, soll
  /// keinen Speicher belegen.
  Future<void> start();

  /// Die Ausgabe der Engine, Zeile für Zeile.
  Stream<String> get lines;

  void send(String command);

  Future<void> dispose();
}

/// Was die App von einer Engine will.
abstract interface class EngineService {
  /// Ob überhaupt eine Engine zur Verfügung steht.
  bool get isAvailable;

  /// Bewertet eine Stellung.
  Future<EngineEvaluation?> evaluate({
    required String fen,
    List<String> moves = const [],
    Duration moveTime = const Duration(milliseconds: 500),
  });

  /// Sucht einen Zug in der eingestellten Spielstärke.
  Future<String?> bestMove({
    required String fen,
    required int elo,
    List<String> moves = const [],
    Duration moveTime = const Duration(milliseconds: 500),
  });

  Future<void> dispose();
}

/// Eine Engine, die es nicht gibt.
///
/// Damit baut und läuft der Rest der App unabhängig davon, ob auf dieser
/// Plattform eine native Engine liegt. Jede Stelle, die eine Bewertung
/// anzeigt, muss ohnehin mit „keine Angabe" umgehen können — hier ist das
/// immer der Fall.
class NoopEngineService implements EngineService {
  const NoopEngineService();

  @override
  bool get isAvailable => false;

  @override
  Future<EngineEvaluation?> evaluate({
    required String fen,
    List<String> moves = const [],
    Duration moveTime = const Duration(milliseconds: 500),
  }) async => null;

  @override
  Future<String?> bestMove({
    required String fen,
    required int elo,
    List<String> moves = const [],
    Duration moveTime = const Duration(milliseconds: 500),
  }) async => null;

  @override
  Future<void> dispose() async {}
}

/// Spricht UCI mit einem [UciTransport].
///
/// Die Anfragen laufen der Reihe nach: eine Engine hat genau einen
/// Suchvorgang, und zwei gleichzeitige Anfragen würden sich die Antworten
/// gegenseitig wegnehmen.
class UciEngineService implements EngineService {
  UciEngineService(this._transport);

  final UciTransport _transport;

  Future<void>? _startup;
  Future<void> _queue = Future.value();
  StreamSubscription<String>? _subscription;

  final _lines = StreamController<String>.broadcast();

  @override
  bool get isAvailable => true;

  Future<void> _ensureStarted() {
    return _startup ??= () async {
      await _transport.start();
      _subscription = _transport.lines.listen(_lines.add);

      _transport.send('uci');
      await _waitFor(Uci.isUciOk, timeout: const Duration(seconds: 10));

      _transport.send('isready');
      await _waitFor(Uci.isReady, timeout: const Duration(seconds: 10));
    }();
  }

  @override
  Future<EngineEvaluation?> evaluate({
    required String fen,
    List<String> moves = const [],
    Duration moveTime = const Duration(milliseconds: 500),
  }) {
    return _run(() async {
      _transport
        ..send(Uci.unlimitedStrength)
        ..send('ucinewgame')
        ..send(Uci.position(fen: fen, moves: moves))
        ..send(Uci.goMoveTime(moveTime));

      // Die letzte `info`-Zeile vor `bestmove` trägt die tiefste Suche.
      EngineEvaluation? best;
      await for (final line in _lines.stream.timeout(
        moveTime + const Duration(seconds: 5),
        onTimeout: (sink) => sink.close(),
      )) {
        final info = Uci.parseInfo(line);
        if (info != null) best = info;
        if (line.startsWith('bestmove')) break;
      }
      return best;
    });
  }

  @override
  Future<String?> bestMove({
    required String fen,
    required int elo,
    List<String> moves = const [],
    Duration moveTime = const Duration(milliseconds: 500),
  }) {
    return _run(() async {
      Uci.setStrength(elo).forEach(_transport.send);
      _transport
        ..send(Uci.position(fen: fen, moves: moves))
        ..send(Uci.goMoveTime(moveTime));

      await for (final line in _lines.stream.timeout(
        moveTime + const Duration(seconds: 5),
        onTimeout: (sink) => sink.close(),
      )) {
        if (line.startsWith('bestmove')) return Uci.parseBestMove(line);
      }
      return null;
    });
  }

  /// Reiht eine Anfrage hinter die laufende.
  Future<T> _run<T>(Future<T> Function() body) {
    final result = _queue.then((_) async {
      await _ensureStarted();
      return body();
    });

    // Die Warteschlange darf nicht an einem Fehler hängenbleiben.
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _waitFor(
    bool Function(String line) predicate, {
    required Duration timeout,
  }) async {
    await _lines.stream
        .firstWhere(predicate)
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('Engine antwortet nicht', timeout),
        );
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _lines.close();
    await _transport.dispose();
  }
}
