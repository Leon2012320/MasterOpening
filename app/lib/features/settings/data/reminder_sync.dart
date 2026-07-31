import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/features/notifications/data/reminder_providers.dart';
import 'package:masteropening/features/notifications/domain/reminder_plan.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Schreibt den Erinnerungsplan ins Betriebssystem fort.
///
/// Als Provider und nicht als Aufruf im Schalter: der Plan hängt auch am
/// Serienstand, und der ändert sich nach jeder Trainingseinheit — nicht nur,
/// wenn jemand in den Einstellungen etwas umlegt. Wer den Provider beobachtet,
/// hält die Planung aktuell.
final reminderSyncProvider = Provider<void>((ref) {
  final plan = ref.watch(reminderPlanProvider);
  final service = ref.watch(notificationServiceProvider);

  // Die Texte kommen aus der gewählten Sprache; der Dienst selbst hat keinen
  // `BuildContext`, aus dem er sie holen könnte.
  final language = ref.watch(
    settingsProvider.select((s) => s.languageCode ?? 'de'),
  );
  final l10n = lookupAppL10n(Locale(language));

  // Ein fehlgeschlagener Plan darf die Oberfläche nicht aufhalten: im
  // schlimmsten Fall kommt eben keine Erinnerung.
  service.apply(plan, (kind) => _textFor(l10n, kind)).ignore();
});

({String title, String body}) _textFor(AppL10n l10n, ReminderKind kind) {
  return switch (kind) {
    ReminderKind.daily => (
      title: l10n.reminderDailyTitle,
      body: l10n.reminderDailyBody,
    ),
    ReminderKind.streakRisk => (
      title: l10n.reminderStreakTitle,
      body: l10n.reminderStreakBody,
    ),
  };
}
