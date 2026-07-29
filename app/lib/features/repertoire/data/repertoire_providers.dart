import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:masteropening/features/repertoire/data/repertoire_repository.dart';
import 'package:meta/meta.dart';

/// Repertoire samt geparstem Baum, wie die Bildschirme es brauchen.
typedef LoadedRepertoire = ({Repertoire row, RepertoireTree tree});

final repertoireRepositoryProvider = Provider<RepertoireRepository>(
  (ref) => RepertoireRepository(ref.watch(databaseProvider)),
);

/// Alle nicht archivierten Repertoires, laufend aktuell gehalten.
final repertoiresProvider = StreamProvider<List<Repertoire>>(
  (ref) => ref.watch(repertoireDaoProvider).watchAll(),
);

// Der Rückgabetyp von `StreamProvider.family` heisst `StreamProviderFamily`
// und wird von Riverpod nicht öffentlich exportiert — er lässt sich also nicht
// hinschreiben. Die beiden folgenden Deklarationen bleiben deshalb bei der
// Ableitung; die Typargumente stehen am Aufruf.

/// Ein einzelnes Repertoire. `null`, wenn es (nicht mehr) existiert.
// ignore: specify_nonobvious_property_types
final repertoireProvider = StreamProvider.family<Repertoire?, int>(
  (ref, id) => ref.watch(repertoireDaoProvider).watchById(id),
);

/// Repertoire samt geparstem Variantenbaum.
///
/// Der Baum kommt aus dem Zwischenspeicher des Repositorys und wird nur bei
/// einer neuen Revision erneut aus dem PGN gelesen.
// ignore: specify_nonobvious_property_types
final repertoireTreeProvider = StreamProvider.family<LoadedRepertoire?, int>((
  ref,
  id,
) {
  final repo = ref.watch(repertoireRepositoryProvider);
  return ref
      .watch(repertoireDaoProvider)
      .watchById(id)
      .map(
        (row) => row == null ? null : (row: row, tree: repo.treeOf(row)),
      );
});

/// Wie viele Züge je Repertoire fällig sind.
final dueCountsProvider = StreamProvider<Map<int, int>>(
  (ref) => ref.watch(progressDaoProvider).watchDueCounts(),
);

/// Ein Repertoire mit allem, was die Startseite darüber anzeigt.
@immutable
class RepertoireOverview {
  const RepertoireOverview({
    required this.row,
    required this.tree,
    required this.dueCount,
  });

  final Repertoire row;
  final RepertoireTree tree;

  /// Wie viele eigene Züge jetzt zur Wiederholung anstehen.
  final int dueCount;

  int get id => row.id;
  String get name => row.name;

  /// Die Stellung nach den ersten Zügen der Hauptvariante — die Vorschau auf
  /// der Karte.
  String get previewFen {
    var node = tree.children.firstOrNull;
    var fen = tree.startFen;
    // Sechs Halbzüge reichen, um die Eröffnung erkennbar zu machen.
    for (var ply = 0; ply < 6 && node != null; ply++) {
      fen = node.fenAfter;
      node = node.children.firstOrNull;
    }
    return fen;
  }
}

/// Alle Repertoires samt Baum und Fälligkeiten.
///
/// Fasst drei Quellen zusammen, damit die Startseite nur einen Provider
/// beobachten muss und nicht bei jeder Teiländerung dreimal neu baut.
final repertoireOverviewsProvider =
    Provider<AsyncValue<List<RepertoireOverview>>>((ref) {
      final rows = ref.watch(repertoiresProvider);
      final due = ref.watch(dueCountsProvider);
      final repository = ref.watch(repertoireRepositoryProvider);

      return rows.whenData(
        (list) => [
          for (final row in list)
            RepertoireOverview(
              row: row,
              tree: repository.treeOf(row),
              dueCount: due.value?[row.id] ?? 0,
            ),
        ],
      );
    });

/// Wie viele Züge insgesamt fällig sind — die Zahl auf der „Fällig heute"-Karte.
final totalDueProvider = Provider<int>((ref) {
  final counts = ref.watch(dueCountsProvider).value ?? const <int, int>{};
  return counts.values.fold<int>(0, (sum, value) => sum + value);
});
