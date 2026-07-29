import 'dart:math';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';

/// Verbindet die Datenbankzeile eines Repertoires mit seinem Variantenbaum.
///
/// Der Baum steht als PGN in der Zeile; hier wird er einmal je Revision
/// geparst und danach im Speicher gehalten. Ohne diesen Zwischenspeicher würde
/// jeder Bildschirmaufbau denselben Text erneut durchrechnen — inklusive aller
/// Stellungen, die dafür nachgespielt werden müssen.
class RepertoireRepository {
  RepertoireRepository(this._db);

  final AppDatabase _db;

  /// Schlüssel ist die Repertoire-ID, der Wert enthält die Revision, zu der
  /// der Baum gehört.
  final Map<int, ({int revision, RepertoireTree tree})> _cache = {};

  static final _random = Random.secure();

  /// Eine über Geräte hinweg eindeutige Kennung — der Server bekommt sie beim
  /// Abgleich, damit dasselbe Repertoire nicht doppelt entsteht.
  static String newUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    // Version 4, Variante 1 — die üblichen Bits nach RFC 4122.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  /// Der Baum eines Repertoires.
  RepertoireTree treeOf(Repertoire row) {
    final cached = _cache[row.id];
    if (cached != null && cached.revision == row.revision) return cached.tree;

    final tree = PgnIo.parse(row.pgn).tree;
    _cache[row.id] = (revision: row.revision, tree: tree);
    return tree;
  }

  void forget(int repertoireId) => _cache.remove(repertoireId);

  /// Legt ein Repertoire aus einem fertigen Baum an und erzeugt gleich die
  /// Fortschrittszeilen — neue Züge sind sofort fällig.
  Future<int> create({
    required String name,
    required Side side,
    required RepertoireTree tree,
    required RepertoireSource source,
    String? sourceRef,
    String ecoCodes = '',
    Map<String, String> pgnHeaders = const {},
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();

    final id = await _db.repertoireDao.insertRepertoire(
      uuid: newUuid(),
      name: name,
      side: side,
      pgn: PgnIo.write(tree, headers: {'Event': name, ...pgnHeaders}),
      startFen: tree.startFen,
      source: source,
      sourceRef: sourceRef,
      ecoCodes: ecoCodes,
      nodeCount: tree.nodeCount,
      lineCount: tree.lines().length,
      now: timestamp,
    );

    await _syncProgressRows(id, tree, now: timestamp);
    _cache[id] = (revision: 0, tree: tree);
    return id;
  }

  /// Schreibt einen bearbeiteten Baum zurück und hält die Fortschrittszeilen
  /// dazu passend: neue Züge kommen hinzu, entfernte fliegen raus, alle
  /// übrigen behalten ihren Lernstand — dafür ist der `pathHash` da.
  Future<void> saveTree(
    Repertoire row,
    RepertoireTree tree, {
    String? ecoCodes,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();

    await _db.repertoireDao.updateTree(
      row.id,
      pgn: PgnIo.write(tree, headers: {'Event': row.name}),
      nodeCount: tree.nodeCount,
      lineCount: tree.lines().length,
      ecoCodes: ecoCodes,
      now: timestamp,
    );

    await _syncProgressRows(row.id, tree, now: timestamp);
    _cache[row.id] = (revision: row.revision + 1, tree: tree);
  }

  Future<void> delete(int id) async {
    await _db.repertoireDao.softDelete(id);
    forget(id);
  }

  /// Importiert PGN-Text. Gibt das Ergebnis mit Warnungen zurück, damit die
  /// Oberfläche zeigen kann, was übersprungen wurde.
  Future<({int id, PgnImportResult result})> importPgn({
    required String pgn,
    required Side side,
    String? name,
    RepertoireSource source = RepertoireSource.pgnImport,
    String? sourceRef,
    DateTime? now,
  }) async {
    final result = PgnIo.parseStudy(pgn);
    final id = await create(
      name: name ?? result.suggestedName,
      side: side,
      tree: result.tree,
      source: source,
      sourceRef: sourceRef,
      ecoCodes: result.eco ?? '',
      now: now,
    );
    return (id: id, result: result);
  }

  /// Führt einen weiteren Baum in ein bestehendes Repertoire ein.
  Future<void> mergeInto(
    Repertoire row,
    RepertoireTree incoming, {
    DateTime? now,
  }) async {
    final merged = treeOf(row).merge(incoming);
    await saveTree(row, merged, now: now);
  }

  Future<void> _syncProgressRows(
    int repertoireId,
    RepertoireTree tree, {
    required DateTime now,
  }) async {
    final side = await _sideOf(repertoireId);
    // Nur die eigenen Züge werden abgefragt: die Antworten des Gegners gibt
    // die App vor, sie sind nichts zum Auswendiglernen.
    final hashes = tree
        .walk()
        .where((node) => node.movedBy == side)
        .map((node) => node.pathHash)
        .toSet();

    await _db.progressDao.ensureRows(
      repertoireId: repertoireId,
      pathHashes: hashes,
      now: now,
    );
    await _db.progressDao.pruneOrphans(
      repertoireId: repertoireId,
      livingHashes: hashes,
    );
  }

  Future<Side> _sideOf(int repertoireId) async {
    final row = await _db.repertoireDao.getById(repertoireId);
    return row?.side ?? Side.white;
  }
}
