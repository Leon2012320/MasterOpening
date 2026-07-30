import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:meta/meta.dart';

/// Eine Variante, wie sie im Training abgefragt wird.
///
/// Eine Aufgabe ist bewusst eine ganze Linie und nicht ein einzelner Zug: nur
/// so lassen sich „gelernt" (über 75 % richtig) und „gemeistert" (fehlerfrei)
/// überhaupt bestimmen, und nur so übt man die Zugfolge, auf die es am Brett
/// ankommt.
@immutable
class TrainingLine {
  const TrainingLine({
    required this.repertoireId,
    required this.repertoireName,
    required this.side,
    required this.startFen,
    required this.line,
    required this.weight,
  });

  final int repertoireId;
  final String repertoireName;

  /// Die Farbe, die der Nutzer spielt — ihre Züge werden abgefragt, die des
  /// Gegners spielt die App vor.
  final Side side;

  final String startFen;
  final RepertoireLine line;

  /// Wie dringend diese Variante ist. Der Planer sortiert danach.
  final double weight;

  /// Die Züge, die der Nutzer finden muss.
  List<RepertoireNode> get ownMoves => line.ownMoves(side);

  int get length => line.length;

  String get id => line.id;
}

/// Nach welchem Maßstab der Planer auswählt.
@immutable
class PlannerOptions {
  const PlannerOptions({
    required this.mode,
    this.now,
    this.maxLines = 12,
    this.includeNotDue = true,
    this.random,
  });

  final TrainingMode mode;

  /// Zeitpunkt, gegen den Fälligkeiten gerechnet werden.
  final DateTime? now;

  /// Obergrenze je Einheit. Zwölf Varianten sind rund zehn Minuten — lang
  /// genug, um etwas zu bewirken, kurz genug, um es täglich zu tun.
  final int maxLines;

  /// Ob auch nicht fällige Varianten aufgenommen werden, wenn sonst zu wenig
  /// zusammenkommt. Ohne das stünde man nach dem Aufholen vor einem leeren
  /// Training.
  final bool includeNotDue;

  final Random? random;
}

/// Stellt zusammen, was in einer Einheit geübt wird.
abstract final class TrainingPlanner {
  /// Baut den Plan für ein oder mehrere Repertoires.
  ///
  /// Gewichtet wird nach drei Dingen: wie überfällig eine Variante ist, wie
  /// oft sie in der Vergangenheit danebenging und wie wenig sie überhaupt
  /// schon geübt wurde. Neue Varianten kommen zuerst — was man nie gesehen
  /// hat, kann man auch nicht wiederholen.
  static List<TrainingLine> build({
    required List<TrainingSource> sources,
    required PlannerOptions options,
  }) {
    final now = options.now ?? DateTime.now();
    final candidates = <TrainingLine>[];

    for (final source in sources) {
      for (final line in source.tree.lines()) {
        final own = line.ownMoves(source.side);
        if (own.isEmpty) continue;

        final weight = _weightOf(own, source.progress, now);
        if (weight <= 0 && !options.includeNotDue) continue;

        candidates.add(
          TrainingLine(
            repertoireId: source.repertoireId,
            repertoireName: source.name,
            side: source.side,
            startFen: source.tree.startFen,
            line: line,
            weight: weight,
          ),
        );
      }
    }

    // Fällige zuerst, danach die schwächsten. Bei gleichem Gewicht entscheidet
    // die kürzere Variante — sie ist schneller gefestigt.
    candidates.sort((a, b) {
      final byWeight = b.weight.compareTo(a.weight);
      if (byWeight != 0) return byWeight;
      return a.length.compareTo(b.length);
    });

    if (options.mode == TrainingMode.puzzle) {
      // Im Puzzle-Modus soll die Auswahl nicht jeden Tag dieselbe sein.
      final pool = candidates.take(options.maxLines * 3).toList()
        ..shuffle(options.random ?? Random());
      return pool.take(options.maxLines).toList();
    }

    return candidates.take(options.maxLines).toList();
  }

  /// Das Gewicht einer Variante — 0 heißt „nichts davon ist fällig".
  static double _weightOf(
    List<RepertoireNode> ownMoves,
    Map<String, NodeProgressData> progress,
    DateTime now,
  ) {
    var total = 0.0;

    for (final node in ownMoves) {
      final row = progress[node.pathHash];

      if (row == null || row.state == FsrsState.newCard) {
        // Ungelernte Züge wiegen am schwersten.
        total += 3;
        continue;
      }

      final overdueDays =
          now.difference(row.due).inSeconds / Duration.secondsPerDay;
      if (overdueDays < 0) continue;

      // Überfälligkeit zählt gedämpft: eine Variante, die seit einem halben
      // Jahr liegt, ist nicht hundertmal dringender als eine von gestern.
      final dueScore = 1 + log(1 + overdueDays);

      final attempts = row.correctCount + row.wrongCount;
      final errorRate = attempts == 0 ? 0.0 : row.wrongCount / attempts;

      total += dueScore * (1 + 2 * errorRate);
    }

    return total;
  }
}

/// Ein Repertoire, aus dem der Planer schöpfen darf.
@immutable
class TrainingSource {
  const TrainingSource({
    required this.repertoireId,
    required this.name,
    required this.side,
    required this.tree,
    required this.progress,
  });

  final int repertoireId;
  final String name;
  final Side side;
  final RepertoireTree tree;

  /// Lernstand je `pathHash`.
  final Map<String, NodeProgressData> progress;
}

/// Wie eine einzelne Variante ausgegangen ist.
@immutable
class LineResult {
  const LineResult({
    required this.line,
    required this.correct,
    required this.total,
  });

  final TrainingLine line;
  final int correct;
  final int total;

  double get accuracy => total == 0 ? 0 : correct / total;

  /// Ab drei Vierteln richtiger Züge gilt eine Variante als gelernt.
  bool get isLearned => accuracy > 0.75;

  /// Ohne einen einzigen Fehler gilt sie als gemeistert.
  bool get isMastered => total > 0 && correct == total;
}

/// Das Ergebnis einer Trainingseinheit.
@immutable
class TrainingReport {
  const TrainingReport({
    required this.mode,
    required this.results,
    required this.movesCorrect,
    required this.movesTotal,
    required this.duration,
  });

  final TrainingMode mode;
  final List<LineResult> results;

  /// Die Genauigkeit wird in Zügen gerechnet, nicht in Varianten.
  final int movesCorrect;
  final int movesTotal;

  final Duration duration;

  double get accuracy => movesTotal == 0 ? 0 : movesCorrect / movesTotal;

  int get accuracyPercent => (accuracy * 100).round();

  int get learnedCount => results.where((r) => r.isLearned).length;

  int get masteredCount => results.where((r) => r.isMastered).length;

  /// Die Varianten, die am meisten Ärger gemacht haben — sie stehen im Report
  /// obenan, damit klar ist, wo es beim nächsten Mal weitergeht.
  List<LineResult> get weakest => results
      .where((r) => !r.isMastered)
      .sorted((a, b) => a.accuracy.compareTo(b.accuracy))
      .take(3)
      .toList();

  /// Erfahrungspunkte: zwei je richtigem Zug, zwanzig für die Einheit selbst,
  /// fünfzig für jede fehlerfrei gespielte Variante.
  int get xpEarned {
    if (movesTotal == 0) return 0;
    return movesCorrect * 2 + 20 + masteredCount * 50;
  }
}
