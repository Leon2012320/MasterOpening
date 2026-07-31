import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:share_plus/share_plus.dart';

final repertoireExportProvider = Provider<RepertoireExport>(
  (ref) => RepertoireExport(ref.watch(databaseProvider)),
);

/// Gibt die Repertoires als PGN heraus.
///
/// Kein eigenes Sicherungsformat: PGN ist das Austauschformat des Schachs,
/// lässt sich in jedem anderen Programm öffnen und ist in zehn Jahren noch
/// lesbar. Ein proprietäres Archiv wäre bequemer zu schreiben und für den
/// Nutzer weniger wert.
class RepertoireExport {
  const RepertoireExport(this._db);

  final AppDatabase _db;

  /// Alle Repertoires in einer Sammel-PGN.
  Future<String> asPgn() async {
    final rows = await _db.repertoireDao.getAll(includeArchived: true);
    return rows.map((row) => row.pgn.trim()).join('\n\n');
  }

  /// Öffnet den Teilen-Dialog. `false`, wenn es nichts zu teilen gibt.
  Future<bool> share() async {
    final pgn = await asPgn();
    if (pgn.isEmpty) return false;

    await SharePlus.instance.share(
      ShareParams(
        text: pgn,
        fileNameOverrides: const ['masteropening.pgn'],
        subject: 'MasterOpening',
      ),
    );
    return true;
  }
}
