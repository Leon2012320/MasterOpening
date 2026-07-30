import 'package:dartchess/dartchess.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/training/domain/training_plan.dart';
import 'package:meta/meta.dart';

/// Woran die Einheit gerade ist.
enum TrainingPhase {
  /// Der Nutzer ist am Zug und soll den richtigen Zug finden.
  awaitingMove,

  /// Der Zug war richtig — kurze Bestätigung, dann geht es weiter.
  correct,

  /// Der Zug war falsch; die Oberfläche zeigt den richtigen.
  wrong,

  /// Die Variante ist durch.
  lineComplete,

  /// Alle Varianten sind durch.
  finished,
}

/// Ein einzelner Zugversuch, wie er in der Datenbank landet.
@immutable
class TrainingAttempt {
  const TrainingAttempt({
    required this.repertoireId,
    required this.pathHash,
    required this.expectedSan,
    required this.correct,
    required this.millis,
    this.playedSan,
  });

  final int repertoireId;
  final String pathHash;
  final String expectedSan;
  final String? playedSan;
  final bool correct;
  final int millis;
}

/// Der Zustand einer Trainingseinheit.
///
/// Unveränderlich und ohne Widgets: der gesamte Ablauf — vorspielen, abfragen,
/// korrigieren, weiterrücken — ist damit ohne Oberfläche prüfbar. Die
/// Zeitmessung kommt von aussen herein, sonst wäre nichts davon reproduzierbar.
@immutable
class TrainingSessionState {
  const TrainingSessionState._({
    required this.mode,
    required this.lines,
    required this.lineIndex,
    required this.ply,
    required this.phase,
    required this.attempts,
    required this.lineCorrect,
    required this.lineTotal,
    required this.results,
    required this.startedAt,
    this.lastPlayedSan,
  });

  factory TrainingSessionState.start({
    required TrainingMode mode,
    required List<TrainingLine> lines,
    required DateTime now,
  }) {
    final state = TrainingSessionState._(
      mode: mode,
      lines: List.unmodifiable(lines),
      lineIndex: 0,
      ply: 0,
      phase: lines.isEmpty
          ? TrainingPhase.finished
          : TrainingPhase.awaitingMove,
      attempts: const [],
      lineCorrect: 0,
      lineTotal: 0,
      results: const [],
      startedAt: now,
    );
    // Beginnt der Gegner, spielt die App seine Züge sofort vor.
    return state._skipOpponentMoves();
  }

  final TrainingMode mode;
  final List<TrainingLine> lines;

  /// Welche Variante gerade dran ist.
  final int lineIndex;

  /// Wie viele Halbzüge der aktuellen Variante schon auf dem Brett stehen.
  final int ply;

  final TrainingPhase phase;
  final List<TrainingAttempt> attempts;

  /// Zähler der laufenden Variante.
  final int lineCorrect;
  final int lineTotal;

  final List<LineResult> results;
  final DateTime startedAt;

  /// Der zuletzt gespielte falsche Zug — die Oberfläche zeigt ihn neben dem
  /// richtigen.
  final String? lastPlayedSan;

  // ── Ableitungen ───────────────────────────────────────────────────────────

  bool get isFinished => phase == TrainingPhase.finished;

  TrainingLine? get currentLine =>
      lineIndex < lines.length ? lines[lineIndex] : null;

  /// Die Züge der aktuellen Variante, die schon gespielt sind.
  List<RepertoireNode> get playedNodes =>
      currentLine == null ? const [] : currentLine!.line.nodes.sublist(0, ply);

  /// Der Zug, der jetzt gefunden werden soll.
  RepertoireNode? get expectedNode {
    final line = currentLine;
    if (line == null || ply >= line.length) return null;
    return line.line.nodes[ply];
  }

  String get fen {
    final line = currentLine;
    if (line == null) return RepertoireTree.initialFen;
    if (ply == 0) return line.startFen;
    return line.line.nodes[ply - 1].fenAfter;
  }

  Position get position => fen == RepertoireTree.initialFen
      ? Chess.initial
      : Chess.fromSetup(Setup.parseFen(fen));

  Move? get lastMove {
    if (ply == 0) return null;
    return Move.parse(currentLine!.line.nodes[ply - 1].uci);
  }

  /// Fortschritt über die ganze Einheit, für den Balken oben.
  double get progress {
    if (lines.isEmpty) return 1;
    final line = currentLine;
    if (line == null) return 1;

    final inLine = line.length == 0 ? 0.0 : ply / line.length;
    return ((results.length + inLine) / lines.length).clamp(0.0, 1.0);
  }

  int get movesCorrect => attempts.where((a) => a.correct).length;
  int get movesTotal => attempts.length;

  // ── Ablauf ────────────────────────────────────────────────────────────────

  /// Nimmt einen Zug entgegen. [millis] ist die Zeit, die der Nutzer gebraucht
  /// hat; sie geht in die Bewertung ein.
  TrainingSessionState submitMove(Move move, {required int millis}) {
    final expected = expectedNode;
    if (expected == null || phase != TrainingPhase.awaitingMove) return this;

    final position = this.position;
    final correct = move.uci == expected.uci;
    final playedSan = position.isLegal(move)
        ? position.makeSan(move).$2
        : move.uci;

    return _record(
      correct: correct,
      millis: millis,
      playedSan: correct ? expected.san : playedSan,
    );
  }

  /// Die Zeit ist abgelaufen, ohne dass gezogen wurde — im Blitz-Modus zählt
  /// das wie ein Fehler.
  TrainingSessionState timeOut({required int millis}) {
    if (phase != TrainingPhase.awaitingMove || expectedNode == null) {
      return this;
    }
    return _record(correct: false, millis: millis, playedSan: null);
  }

  TrainingSessionState _record({
    required bool correct,
    required int millis,
    required String? playedSan,
  }) {
    final expected = expectedNode!;
    final line = currentLine!;

    return _copyWith(
      phase: correct ? TrainingPhase.correct : TrainingPhase.wrong,
      lastPlayedSan: correct ? null : playedSan,
      lineCorrect: lineCorrect + (correct ? 1 : 0),
      lineTotal: lineTotal + 1,
      attempts: [
        ...attempts,
        TrainingAttempt(
          repertoireId: line.repertoireId,
          pathHash: expected.pathHash,
          expectedSan: expected.san,
          playedSan: playedSan,
          correct: correct,
          millis: millis,
        ),
      ],
    );
  }

  /// Nach der Rückmeldung weiter — der richtige Zug kommt aufs Brett, danach
  /// die Antwort des Gegners.
  TrainingSessionState advance() {
    if (phase != TrainingPhase.correct && phase != TrainingPhase.wrong) {
      return this;
    }

    final next = _copyWith(
      ply: ply + 1,
      phase: TrainingPhase.awaitingMove,
      clearLastPlayed: true,
    );
    return next._skipOpponentMoves();
  }

  /// Zur nächsten Variante.
  TrainingSessionState nextLine() {
    if (phase != TrainingPhase.lineComplete) return this;

    final finished = [
      ...results,
      LineResult(line: currentLine!, correct: lineCorrect, total: lineTotal),
    ];

    if (lineIndex + 1 >= lines.length) {
      return _copyWith(
        results: finished,
        phase: TrainingPhase.finished,
        lineIndex: lineIndex + 1,
      );
    }

    final next = _copyWith(
      results: finished,
      lineIndex: lineIndex + 1,
      ply: 0,
      lineCorrect: 0,
      lineTotal: 0,
      phase: TrainingPhase.awaitingMove,
      clearLastPlayed: true,
    );
    return next._skipOpponentMoves();
  }

  /// Spielt die Züge des Gegners vor und erkennt, wenn die Variante zu Ende
  /// ist. Die Antworten des Gegners gibt das Repertoire vor — sie abzufragen
  /// hätte keinen Sinn.
  TrainingSessionState _skipOpponentMoves() {
    var cursor = this;

    while (true) {
      final line = cursor.currentLine;
      if (line == null) {
        return cursor._copyWith(phase: TrainingPhase.finished);
      }
      if (cursor.ply >= line.length) {
        return cursor._copyWith(phase: TrainingPhase.lineComplete);
      }
      if (line.line.nodes[cursor.ply].movedBy == line.side) {
        return cursor._copyWith(phase: TrainingPhase.awaitingMove);
      }
      cursor = cursor._copyWith(ply: cursor.ply + 1);
    }
  }

  TrainingReport report(DateTime now) {
    return TrainingReport(
      mode: mode,
      results: results,
      movesCorrect: movesCorrect,
      movesTotal: movesTotal,
      duration: now.difference(startedAt),
    );
  }

  TrainingSessionState _copyWith({
    int? lineIndex,
    int? ply,
    TrainingPhase? phase,
    List<TrainingAttempt>? attempts,
    int? lineCorrect,
    int? lineTotal,
    List<LineResult>? results,
    String? lastPlayedSan,
    bool clearLastPlayed = false,
  }) {
    return TrainingSessionState._(
      mode: mode,
      lines: lines,
      lineIndex: lineIndex ?? this.lineIndex,
      ply: ply ?? this.ply,
      phase: phase ?? this.phase,
      attempts: attempts ?? this.attempts,
      lineCorrect: lineCorrect ?? this.lineCorrect,
      lineTotal: lineTotal ?? this.lineTotal,
      results: results ?? this.results,
      startedAt: startedAt,
      lastPlayedSan: clearLastPlayed
          ? null
          : (lastPlayedSan ?? this.lastPlayedSan),
    );
  }
}
