import 'package:drift/drift.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/features/analysis/domain/deviation.dart';
import 'package:masteropening/features/analysis/domain/gap.dart';
import 'package:masteropening/features/repertoire/data/repertoire_repository.dart';
import 'package:meta/meta.dart';

/// Was ein Durchlauf der Analyse ergeben hat.
@immutable
class AnalysisSummary {
  const AnalysisSummary({
    required this.gamesAnalysed,
    required this.gapsFound,
    required this.ownDeviations,
    required this.stayedInBook,
  });

  final int gamesAnalysed;

  /// Stellen, an denen der Gegner etwas spielte, worauf nichts vorbereitet ist.
  final int gapsFound;

  /// Stellen, an denen der Nutzer selbst vom eigenen Repertoire abwich.
  final int ownDeviations;

  /// Partien, die das Repertoire nie verlassen haben.
  final int stayedInBook;

  bool get isEmpty => gamesAnalysed == 0;
}

/// Vergleicht die importierten Partien mit den Repertoires.
///
/// Läuft absichtlich nachträglich und nicht beim Import: die Analyse hängt
/// vom aktuellen Stand der Repertoires ab, und der ändert sich öfter als die
/// Partien.
class AnalysisRepository {
  AnalysisRepository(this._db, this._repertoires);

  final AppDatabase _db;
  final RepertoireRepository _repertoires;

  /// Wertet alle Partien aus, die noch keine Marke tragen.
  ///
  /// [force] wertet auch schon geprüfte erneut aus — nötig, nachdem sich ein
  /// Repertoire geändert hat, denn dann stimmen die alten Marken nicht mehr.
  Future<AnalysisSummary> analyse({
    bool force = false,
    int maxPly = DeviationFinder.defaultMaxPly,
  }) async {
    final rows = await _db.repertoireDao.getAll();
    if (rows.isEmpty) {
      return const AnalysisSummary(
        gamesAnalysed: 0,
        gapsFound: 0,
        ownDeviations: 0,
        stayedInBook: 0,
      );
    }

    final trees = [
      for (final row in rows) (tree: _repertoires.treeOf(row), side: row.side),
    ];

    final query = _db.select(_db.lichessGames);
    if (!force) query.where((g) => g.deviationPly.isNull());
    final games = await query.get();

    final gaps = <String, GapCandidate>{};
    var gapsFound = 0;
    var ownDeviations = 0;
    var stayedInBook = 0;

    for (final game in games) {
      final sanMoves = PgnIo.mainlineSan(game.pgn);
      if (sanMoves.isEmpty) continue;

      final best = DeviationFinder.best(
        repertoires: trees,
        side: game.side,
        sanMoves: sanMoves,
        maxPly: maxPly,
      );

      if (best == null) {
        // Keine Vorbereitung in dieser Farbe — dann gibt es auch nichts,
        // wovon die Partie abweichen könnte.
        await _markGame(game.id, deviationPly: -1, repertoireId: null);
        continue;
      }

      final repertoireId = rows[best.index].id;
      final deviation = best.match.deviation;

      await _markGame(
        game.id,
        deviationPly: deviation?.ply ?? -1,
        repertoireId: repertoireId,
      );

      if (deviation == null) {
        stayedInBook++;
        continue;
      }

      if (deviation.byUser) {
        ownDeviations++;
        continue;
      }

      gapsFound++;
      final candidate = GapCandidate(
        repertoireId: repertoireId,
        parentPathHash: deviation.parentPathHash,
        fen: deviation.fenBefore,
        missingSan: deviation.playedSan,
        missingUci: deviation.playedUci,
        occurrences: 1,
        pointsLost: GapRanking.pointsLostFor(game.outcome),
      );

      gaps[candidate.key] = gaps[candidate.key] == null
          ? candidate
          : gaps[candidate.key]!.plus(
              pointsLost: GapRanking.pointsLostFor(game.outcome),
            );
    }

    await _storeGaps(gaps.values, replace: force);

    return AnalysisSummary(
      gamesAnalysed: games.length,
      gapsFound: gapsFound,
      ownDeviations: ownDeviations,
      stayedInBook: stayedInBook,
    );
  }

  Future<void> _markGame(
    String id, {
    required int deviationPly,
    required int? repertoireId,
  }) {
    return (_db.update(_db.lichessGames)..where((g) => g.id.equals(id))).write(
      LichessGamesCompanion(
        deviationPly: Value(deviationPly),
        matchedRepertoireId: Value(repertoireId),
      ),
    );
  }

  /// Schreibt die Lücken fort. Bereits bekannte werden hochgezählt statt
  /// verdoppelt — sonst stünde dieselbe Stelle nach jedem Import erneut da.
  Future<void> _storeGaps(
    Iterable<GapCandidate> candidates, {
    required bool replace,
  }) async {
    final now = DateTime.now();

    await _db.transaction(() async {
      if (replace) {
        await (_db.delete(
          _db.repertoireGaps,
        )..where((g) => g.dismissed.equals(false))).go();
      }

      for (final candidate in candidates) {
        final existing =
            await (_db.select(_db.repertoireGaps)..where(
                  (g) =>
                      g.repertoireId.equals(candidate.repertoireId) &
                      g.parentPathHash.equals(candidate.parentPathHash) &
                      g.missingUci.equals(candidate.missingUci),
                ))
                .getSingleOrNull();

        if (existing == null) {
          await _db
              .into(_db.repertoireGaps)
              .insert(
                RepertoireGapsCompanion.insert(
                  repertoireId: candidate.repertoireId,
                  parentPathHash: candidate.parentPathHash,
                  fen: candidate.fen,
                  missingSan: candidate.missingSan,
                  missingUci: candidate.missingUci,
                  occurrences: Value(candidate.occurrences),
                  pointsLost: Value(candidate.pointsLost),
                  source: GapSource.ownGames,
                  detectedAt: now,
                ),
              );
        } else {
          await (_db.update(
            _db.repertoireGaps,
          )..where((g) => g.id.equals(existing.id))).write(
            RepertoireGapsCompanion(
              occurrences: Value(
                existing.occurrences + candidate.occurrences,
              ),
              pointsLost: Value(existing.pointsLost + candidate.pointsLost),
              detectedAt: Value(now),
              resolved: const Value(false),
            ),
          );
        }
      }
    });
  }

  /// Die offenen Lücken, dringendste zuerst.
  Future<List<RepertoireGap>> openGaps({int limit = 30}) async {
    final rows =
        await (_db.select(_db.repertoireGaps)
              ..where(
                (g) => g.dismissed.equals(false) & g.resolved.equals(false),
              )
              ..orderBy([
                (g) => OrderingTerm(
                  expression: g.pointsLost,
                  mode: OrderingMode.desc,
                ),
                (g) => OrderingTerm(
                  expression: g.occurrences,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(limit))
            .get();
    return rows;
  }

  Stream<List<RepertoireGap>> watchOpenGaps({int limit = 30}) {
    return (_db.select(_db.repertoireGaps)
          ..where((g) => g.dismissed.equals(false) & g.resolved.equals(false))
          ..orderBy([
            (g) =>
                OrderingTerm(expression: g.pointsLost, mode: OrderingMode.desc),
            (g) => OrderingTerm(
              expression: g.occurrences,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit))
        .watch();
  }

  Future<void> dismissGap(int id) =>
      (_db.update(_db.repertoireGaps)..where((g) => g.id.equals(id))).write(
        const RepertoireGapsCompanion(dismissed: Value(true)),
      );

  /// Trägt den fehlenden Zug ins Repertoire ein.
  ///
  /// Nur den Gegnerzug, nicht die Antwort: welche die richtige ist, weiss die
  /// App nicht. Sie schafft den Platz, der Nutzer füllt ihn im Editor — das
  /// ist ehrlicher als ein geratener Zug im eigenen Repertoire.
  Future<String?> addGapToRepertoire(RepertoireGap gap) async {
    final row = await _db.repertoireDao.getById(gap.repertoireId);
    if (row == null) return null;

    final tree = _repertoires.treeOf(row);
    final prefix = gap.parentPathHash.isEmpty
        ? const <RepertoireNode>[]
        : tree.pathTo(gap.parentPathHash);
    if (prefix == null) return null;

    final sanLine = [for (final node in prefix) node.san, gap.missingSan];

    final RepertoireTree updated;
    try {
      updated = tree.withSanLine(sanLine);
    } on InvalidMoveException {
      return null;
    }

    await _repertoires.saveTree(row, updated);
    await (_db.update(_db.repertoireGaps)..where((g) => g.id.equals(gap.id)))
        .write(const RepertoireGapsCompanion(resolved: Value(true)));

    // Der Hash des neuen Knotens ergibt sich aus dem Zugweg — genau so ist er
    // definiert, ein Nachschlagen im Baum erübrigt sich.
    return RepertoireTree.hashFor(updated.startFen, [
      for (final node in prefix) node.uci,
      gap.missingUci,
    ]);
  }

  /// Die Züge, die im Training am häufigsten danebengehen.
  ///
  /// Gewichtet nach Anzahl der Fehler, nicht nach Fehlerquote: ein Zug, der
  /// einmal geübt und einmal verpatzt wurde, hat 100 % Fehlerquote und sagt
  /// trotzdem nichts.
  Future<List<MoveMistake>> mistakes({
    int? repertoireId,
    int limit = 15,
  }) async {
    final attempts = _db.trainingAttempts;

    final total = attempts.id.count();
    final wrong = attempts.id.count(filter: attempts.correct.equals(false));

    final query = _db.selectOnly(attempts)
      ..addColumns([
        attempts.repertoireId,
        attempts.pathHash,
        attempts.expectedSan,
        total,
        wrong,
      ])
      // Nur Stellen, an denen wirklich etwas danebenging.
      ..groupBy(
        [attempts.repertoireId, attempts.pathHash],
        having: wrong.isBiggerThanValue(0),
      )
      ..orderBy([OrderingTerm(expression: wrong, mode: OrderingMode.desc)])
      ..limit(limit);

    if (repertoireId != null) {
      query.where(attempts.repertoireId.equals(repertoireId));
    }

    final rows = await query.get();
    if (rows.isEmpty) return const [];

    final repertoires = {
      for (final row in await _db.repertoireDao.getAll()) row.id: row,
    };

    final result = <MoveMistake>[];

    for (final row in rows) {
      final id = row.read(attempts.repertoireId)!;
      final hash = row.read(attempts.pathHash)!;
      final repertoire = repertoires[id];
      if (repertoire == null) continue;

      final path = _repertoires.treeOf(repertoire).pathTo(hash);

      result.add(
        MoveMistake(
          repertoireId: id,
          repertoireName: repertoire.name,
          pathHash: hash,
          expectedSan: row.read(attempts.expectedSan) ?? '',
          attempts: row.read(total) ?? 0,
          wrong: row.read(wrong) ?? 0,
          commonWrongSan: await _commonWrongSan(id, hash),
          sanLine: path == null ? '' : RepertoireLine(path).sanLine,
        ),
      );
    }

    return result;
  }

  /// Der Zug, der an dieser Stelle am häufigsten statt des richtigen kommt.
  Future<String?> _commonWrongSan(int repertoireId, String pathHash) async {
    final attempts = _db.trainingAttempts;
    final count = attempts.id.count();

    final rows =
        await (_db.selectOnly(attempts)
              ..addColumns([attempts.playedSan, count])
              ..where(
                attempts.repertoireId.equals(repertoireId) &
                    attempts.pathHash.equals(pathHash) &
                    attempts.correct.equals(false) &
                    attempts.playedSan.isNotNull(),
              )
              ..groupBy([attempts.playedSan])
              ..orderBy([
                OrderingTerm(expression: count, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .get();

    return rows.firstOrNull?.read(attempts.playedSan);
  }
}
