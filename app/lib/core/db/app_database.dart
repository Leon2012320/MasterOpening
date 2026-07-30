// `Side` und die Aufzählungen aus `enums.dart` werden vom erzeugten Teil
// dieser Datei gebraucht — `part`-Dateien nutzen die Importe des Hauptteils.
import 'package:dartchess/dartchess.dart' show Side;
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:masteropening/core/db/daos/activity_dao.dart';
import 'package:masteropening/core/db/daos/key_value_dao.dart';
import 'package:masteropening/core/db/daos/progress_dao.dart';
import 'package:masteropening/core/db/daos/repertoire_dao.dart';
import 'package:masteropening/core/db/daos/training_dao.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/db/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Repertoires,
    NodeProgress,
    TrainingSessions,
    TrainingAttempts,
    LichessGames,
    RepertoireGaps,
    ActivityDays,
    UserProfiles,
    AchievementProgress,
    Challenges,
    OpponentScouts,
    KeyValues,
  ],
  daos: [
    RepertoireDao,
    ProgressDao,
    ActivityDao,
    KeyValueDao,
    TrainingDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Öffnet die Datenbank der laufenden App.
  AppDatabase() : super(openConnection());

  /// Für Tests: `AppDatabase.withExecutor(NativeDatabase.memory())`.
  /// `package:drift/native.dart` wird bewusst nicht hier importiert, sonst
  /// zöge der Web-Build `dart:ffi` mit herein.
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Ohne dieses Pragma ignoriert SQLite Fremdschlüssel — die
      // `onDelete`-Regeln des Schemas wären wirkungslos.
      await customStatement('PRAGMA foreign_keys = ON');

      if (details.wasCreated) {
        await into(userProfiles).insert(
          UserProfilesCompanion.insert(updatedAt: DateTime.now()),
        );
      }
    },
  );

  /// Eine Datei im Dokumentenverzeichnis, geöffnet auf einem eigenen Isolate.
  ///
  /// Für das Web gibt es bewusst keine Konfiguration: `dartchess` rechnet mit
  /// 64-Bit-Bitboards, die JavaScript nicht darstellen kann, und deklariert
  /// entsprechend kein Web als Zielplattform. Ohne Schachlogik gibt es keine
  /// App, die im Browser laufen könnte.
  static QueryExecutor openConnection() {
    return driftDatabase(
      name: 'masteropening',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    );
  }
}
