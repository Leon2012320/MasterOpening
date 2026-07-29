import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/daos/activity_dao.dart';
import 'package:masteropening/core/db/daos/key_value_dao.dart';
import 'package:masteropening/core/db/daos/progress_dao.dart';
import 'package:masteropening/core/db/daos/repertoire_dao.dart';

/// Die Datenbank der App. In Tests wird dieser Provider durch eine Instanz im
/// Arbeitsspeicher ersetzt.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repertoireDaoProvider = Provider<RepertoireDao>(
  (ref) => ref.watch(databaseProvider).repertoireDao,
);

final progressDaoProvider = Provider<ProgressDao>(
  (ref) => ref.watch(databaseProvider).progressDao,
);

final activityDaoProvider = Provider<ActivityDao>(
  (ref) => ref.watch(databaseProvider).activityDao,
);

final keyValueDaoProvider = Provider<KeyValueDao>(
  (ref) => ref.watch(databaseProvider).keyValueDao,
);
