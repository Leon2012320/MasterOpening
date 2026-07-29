import 'package:drift/drift.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/tables.dart';

part 'activity_dao.g.dart';

/// Tageswerte und Spielerstand: Serie, Heatmap, Lernzeit, XP.
@DriftAccessor(tables: [ActivityDays, UserProfiles])
class ActivityDao extends DatabaseAccessor<AppDatabase>
    with _$ActivityDaoMixin {
  ActivityDao(super.db);

  /// Der Kalendertag in Ortszeit als `JJJJ-MM-TT`.
  ///
  /// Die Serie richtet sich nach dem Tag, an dem der Nutzer sitzt — ein
  /// Zeitstempel in UTC würde sie je nach Zeitzone einen halben Tag früher
  /// oder später reißen lassen.
  static String dayKey(DateTime local) {
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Future<UserProfile> profile() async {
    final existing = await (select(
      userProfiles,
    )..where((p) => p.id.equals(1))).getSingleOrNull();
    if (existing != null) return existing;

    // Die Zeile entsteht normalerweise beim Anlegen der Datenbank; hier nur
    // als Netz, falls jemand sie gelöscht hat.
    await into(userProfiles).insert(
      UserProfilesCompanion.insert(updatedAt: DateTime.now()),
    );
    return (select(userProfiles)..where((p) => p.id.equals(1))).getSingle();
  }

  Stream<UserProfile> watchProfile() =>
      (select(userProfiles)..where((p) => p.id.equals(1))).watchSingle();

  Future<void> updateProfile(UserProfilesCompanion patch) async {
    await (update(userProfiles)..where((p) => p.id.equals(1))).write(
      patch.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  Future<ActivityDay?> forDay(String day) =>
      (select(activityDays)..where((d) => d.day.equals(day))).getSingleOrNull();

  /// Die letzten [days] Tage, aufsteigend — Grundlage der Heatmap.
  Future<List<ActivityDay>> recent(int days, {DateTime? today}) {
    final end = today ?? DateTime.now();
    final start = DateTime(end.year, end.month, end.day - days + 1);
    return (select(activityDays)
          ..where((d) => d.day.isBiggerOrEqualValue(dayKey(start)))
          ..orderBy([(d) => OrderingTerm(expression: d.day)]))
        .get();
  }

  Stream<List<ActivityDay>> watchRecent(int days, {DateTime? today}) {
    final end = today ?? DateTime.now();
    final start = DateTime(end.year, end.month, end.day - days + 1);
    return (select(activityDays)
          ..where((d) => d.day.isBiggerOrEqualValue(dayKey(start)))
          ..orderBy([(d) => OrderingTerm(expression: d.day)]))
        .watch();
  }

  /// Rechnet die Werte einer Trainingseinheit auf den Tag drauf.
  Future<ActivityDay> addToDay({
    required String day,
    int xp = 0,
    int movesTrained = 0,
    int movesCorrect = 0,
    int secondsStudied = 0,
    int sessions = 0,
    int linesMastered = 0,
  }) async {
    return transaction(() async {
      final existing = await forDay(day);

      if (existing == null) {
        final row = ActivityDay(
          day: day,
          xp: xp,
          movesTrained: movesTrained,
          movesCorrect: movesCorrect,
          secondsStudied: secondsStudied,
          sessions: sessions,
          linesMastered: linesMastered,
        );
        await into(activityDays).insert(row);
        return row;
      }

      final updated = existing.copyWith(
        xp: existing.xp + xp,
        movesTrained: existing.movesTrained + movesTrained,
        movesCorrect: existing.movesCorrect + movesCorrect,
        secondsStudied: existing.secondsStudied + secondsStudied,
        sessions: existing.sessions + sessions,
        linesMastered: existing.linesMastered + linesMastered,
      );
      await update(activityDays).replace(updated);
      return updated;
    });
  }
}
