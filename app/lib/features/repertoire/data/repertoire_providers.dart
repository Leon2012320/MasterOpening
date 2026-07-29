import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:masteropening/features/repertoire/data/repertoire_repository.dart';

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
