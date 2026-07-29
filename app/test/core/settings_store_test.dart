import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/settings/app_settings.dart';
import 'package:masteropening/core/settings/settings_store.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/theme/board_theme.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('SharedPreferencesSettingsStore', () {
    test(
      'liefert die Standardwerte, wenn nie etwas gespeichert wurde',
      () async {
        final store = SharedPreferencesSettingsStore();

        expect(await store.load(), const AppSettings());
      },
    );

    test('übersteht einen Speicher-Lade-Umlauf unverändert', () async {
      final store = SharedPreferencesSettingsStore();
      const settings = AppSettings(
        themeMode: AppThemeMode.dark,
        boardStyle: BoardStyle.wood,
        pieceSet: 'merida',
        languageCode: 'en',
        showCoordinates: false,
        boardAnimations: false,
        hapticFeedback: false,
        soundEnabled: false,
        dailyReviewLimit: 75,
        autoPlayOpponentMoves: false,
        showEngineEval: true,
        blitzSecondsPerMove: 5,
        engineElo: 2100,
        dailyReminderEnabled: true,
        dailyReminderMinutes: 7 * 60 + 45,
        streakRiskReminder: false,
      );

      await store.save(settings);

      expect(await store.load(), settings);
    });

    test('speichert die Systemsprache als „keine Sprache gewählt"', () async {
      final store = SharedPreferencesSettingsStore();

      await store.save(const AppSettings(languageCode: 'de'));
      expect((await store.load()).languageCode, 'de');

      await store.save(const AppSettings());
      expect((await store.load()).languageCode, isNull);
    });

    test('fällt bei unbekanntem Theme-Schlüssel auf System zurück', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'settings.themeMode': 'neon',
            'settings.boardStyle': 'marmor',
          });

      final settings = await SharedPreferencesSettingsStore().load();

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.boardStyle, BoardStyle.nocturne);
    });
  });
}
