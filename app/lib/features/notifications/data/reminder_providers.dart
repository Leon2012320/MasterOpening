import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/features/gamification/data/gamification_providers.dart';
import 'package:masteropening/features/notifications/data/notification_service.dart';
import 'package:masteropening/features/notifications/domain/reminder_plan.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => createNotificationService(),
);

/// Welche Erinnerungen nach dem aktuellen Stand stehen sollten.
final reminderPlanProvider = Provider<List<PlannedReminder>>((ref) {
  final settings = ref.watch(settingsProvider);
  final streak = ref.watch(streakProvider).value;

  return ReminderPlanner.plan(
    dailyEnabled: settings.dailyReminderEnabled,
    dailyMinutes: settings.dailyReminderMinutes,
    streakRiskEnabled: settings.streakRiskReminder,
    currentStreak: streak?.current ?? 0,
    practisedToday: streak?.activeToday ?? false,
    now: DateTime.now(),
  );
});
