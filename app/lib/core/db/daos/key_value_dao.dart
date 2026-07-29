import 'package:drift/drift.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/tables.dart';

part 'key_value_dao.g.dart';

/// Kleiner Schlüssel-Wert-Speicher für Zustände, die kein eigenes Schema
/// verdienen: Sync-Marken, Zeitpunkt des letzten Partie-Imports, Zähler.
@DriftAccessor(tables: [KeyValues])
class KeyValueDao extends DatabaseAccessor<AppDatabase>
    with _$KeyValueDaoMixin {
  KeyValueDao(super.db);

  /// Zeitpunkt, bis zu dem Lichess-Partien bereits importiert sind.
  static const lichessImportedUntil = 'lichess.importedUntil';

  /// Marke des letzten erfolgreichen Abgleichs mit dem Server.
  static const lastSyncAt = 'sync.lastSyncAt';

  /// Tag, für den die Tagesaufgaben zuletzt erzeugt wurden.
  static const challengesGeneratedFor = 'challenges.generatedFor';

  Future<String?> get(String key) async {
    final row = await (select(
      keyValues,
    )..where((k) => k.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<int?> getInt(String key) async {
    final raw = await get(key);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<DateTime?> getDateTime(String key) async {
    final raw = await getInt(key);
    return raw == null ? null : DateTime.fromMillisecondsSinceEpoch(raw);
  }

  Future<void> set(String key, String value) {
    return into(keyValues).insertOnConflictUpdate(
      KeyValue(key: key, value: value, updatedAt: DateTime.now()),
    );
  }

  Future<void> setInt(String key, int value) => set(key, '$value');

  Future<void> setDateTime(String key, DateTime value) =>
      setInt(key, value.millisecondsSinceEpoch);

  Future<void> remove(String key) =>
      (delete(keyValues)..where((k) => k.key.equals(key))).go();
}
