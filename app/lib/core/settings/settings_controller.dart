import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/settings/app_settings.dart';
import 'package:masteropening/core/settings/settings_store.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/theme/board_theme.dart';

/// Wird in `main()` überschrieben, nachdem die Einstellungen geladen sind.
/// So steht das Theme schon im ersten Frame fest und die App startet nicht
/// sichtbar im falschen Farbschema.
final settingsStoreProvider = Provider<SettingsStore>((ref) {
  throw StateError('settingsStoreProvider muss in main() gesetzt werden');
});

final initialSettingsProvider = Provider<AppSettings>((ref) {
  throw StateError('initialSettingsProvider muss in main() gesetzt werden');
});

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  /// Schreibt durch: der Zustand wechselt sofort, die Platte folgt. Ein
  /// fehlgeschlagener Schreibvorgang darf die Oberfläche nicht blockieren —
  /// im schlimmsten Fall ist die Einstellung nach einem Neustart wieder alt.
  Future<void> _update(AppSettings next) async {
    if (next == state) return;
    state = next;
    await ref.read(settingsStoreProvider).save(next);
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setBoardStyle(BoardStyle style) =>
      _update(state.copyWith(boardStyle: style));

  Future<void> setPieceSet(String pieceSet) =>
      _update(state.copyWith(pieceSet: pieceSet));

  /// `null` stellt auf die Systemsprache zurück.
  Future<void> setLanguage(String? languageCode) => _update(
    state.copyWith(
      languageCode: languageCode,
      clearLanguage: languageCode == null,
    ),
  );

  Future<void> setShowCoordinates({required bool value}) =>
      _update(state.copyWith(showCoordinates: value));

  Future<void> setBoardAnimations({required bool value}) =>
      _update(state.copyWith(boardAnimations: value));

  Future<void> setHapticFeedback({required bool value}) =>
      _update(state.copyWith(hapticFeedback: value));

  Future<void> setSoundEnabled({required bool value}) =>
      _update(state.copyWith(soundEnabled: value));

  Future<void> setDailyReviewLimit(int limit) =>
      _update(state.copyWith(dailyReviewLimit: limit.clamp(5, 200)));

  Future<void> setAutoPlayOpponentMoves({required bool value}) =>
      _update(state.copyWith(autoPlayOpponentMoves: value));

  Future<void> setShowEngineEval({required bool value}) =>
      _update(state.copyWith(showEngineEval: value));

  Future<void> setBlitzSecondsPerMove(int seconds) =>
      _update(state.copyWith(blitzSecondsPerMove: seconds.clamp(1, 15)));

  Future<void> setEngineElo(int elo) =>
      _update(state.copyWith(engineElo: elo.clamp(800, 2850)));

  Future<void> setDailyReminderEnabled({required bool value}) =>
      _update(state.copyWith(dailyReminderEnabled: value));

  Future<void> setDailyReminderTime(TimeOfDay time) => _update(
    state.copyWith(dailyReminderMinutes: time.hour * 60 + time.minute),
  );

  Future<void> setStreakRiskReminder({required bool value}) =>
      _update(state.copyWith(streakRiskReminder: value));
}

/// Der gewählte Brett-Stil, isoliert beobachtbar: Brett-Widgets sollen nicht
/// bei jeder unbeteiligten Einstellung neu bauen. Die konkreten Farben ergeben
/// sich daraus über `BoardColors.of(style, isDark: …)`.
final boardStyleProvider = Provider<BoardStyle>((ref) {
  return ref.watch(settingsProvider.select((s) => s.boardStyle));
});
