import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:masteropening/features/gamification/data/gamification_repository.dart';
import 'package:masteropening/features/gamification/domain/achievement.dart';
import 'package:masteropening/features/gamification/domain/challenge.dart';
import 'package:masteropening/features/gamification/domain/streak.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => GamificationRepository(ref.watch(databaseProvider)),
);

/// Der Stand der Serie.
final streakProvider = FutureProvider<StreakState>(
  (ref) => ref.watch(gamificationRepositoryProvider).streak(),
);

/// Alle Erfolge mit ihrem Fortschritt.
final achievementsProvider = FutureProvider<List<AchievementStatus>>(
  (ref) => ref.watch(gamificationRepositoryProvider).achievements(),
);

/// Die Aufgaben des Tages und der Woche.
final challengesProvider = FutureProvider<List<ChallengeInstance>>(
  (ref) => ref.watch(gamificationRepositoryProvider).currentChallenges(),
);

/// Die Tageswerte der letzten Wochen — Grundlage für Heatmap und Lernzeit.
final activityDaysProvider = StreamProvider<List<ActivityDay>>(
  (ref) => ref.watch(activityDaoProvider).watchRecent(140),
);

/// Die letzten Einheiten für den Genauigkeitsgraphen.
final recentSessionsProvider = StreamProvider<List<TrainingSession>>(
  (ref) => ref.watch(databaseProvider).trainingDao.watchRecentSessions(),
);
