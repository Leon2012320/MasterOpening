import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/settings/app_settings.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/widgets/app_bottom_nav.dart';
import 'package:masteropening/features/home/presentation/home_screen.dart';
import 'package:masteropening/features/library/presentation/library_screen.dart';
import 'package:masteropening/features/lichess/presentation/lichess_screen.dart';
import 'package:masteropening/features/settings/presentation/settings_screen.dart';

import '../helpers/pump_app.dart';

/// Tippt eine Kachel der Tab-Leiste an. Über den reinen Text ginge das nicht:
/// „Lichess" und „Einstellungen" stehen auch als Bildschirmtitel auf der Seite.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AppBottomNav),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Tab-Navigation', () {
    testWidgets('startet auf dem Start-Tab', (tester) async {
      await pumpApp(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LibraryScreen), findsNothing);
    });

    testWidgets('zeigt alle vier Tabs in der Leiste', (tester) async {
      await pumpApp(tester);

      for (final label in ['Start', 'Bibliothek', 'Lichess', 'Einstellungen']) {
        expect(
          find.descendant(
            of: find.byType(AppBottomNav),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: 'Tab „$label" fehlt',
        );
      }
    });

    testWidgets('wechselt zwischen den Tabs', (tester) async {
      await pumpApp(tester);

      await tapTab(tester, 'Bibliothek');
      expect(find.byType(LibraryScreen), findsOneWidget);

      await tapTab(tester, 'Lichess');
      expect(find.byType(LichessScreen), findsOneWidget);

      await tapTab(tester, 'Einstellungen');
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tapTab(tester, 'Start');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('behält den Zustand eines Tabs beim Wechsel', (tester) async {
      await pumpApp(tester);

      await tapTab(tester, 'Bibliothek');
      await tester.enterText(find.byType(TextField), 'Sizilianisch');
      await tester.pumpAndSettle();

      await tapTab(tester, 'Start');
      await tapTab(tester, 'Bibliothek');

      expect(find.text('Sizilianisch'), findsOneWidget);
    });
  });

  group('Sprache', () {
    testWidgets('folgt der Einstellung auf Englisch', (tester) async {
      await pumpApp(tester, settings: const AppSettings(languageCode: 'en'));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });

    testWidgets('folgt der Systemsprache, wenn keine gewählt ist', (
      tester,
    ) async {
      tester.platformDispatcher.localeTestValue = const Locale('en');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);

      await pumpApp(tester, settings: const AppSettings());

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });
  });

  group('Themes', () {
    testWidgets('hell liefert die helle Palette', (tester) async {
      await pumpApp(
        tester,
        settings: const AppSettings(
          languageCode: 'de',
          themeMode: AppThemeMode.light,
        ),
      );

      final tokens = tokensOf(tester, find.byType(HomeScreen));
      expect(tokens.isDark, isFalse);
      expect(tokens.bg, const Color(0xFFECEEFA));
    });

    testWidgets('dunkel liefert die dunkle Palette', (tester) async {
      await pumpApp(
        tester,
        settings: const AppSettings(
          languageCode: 'de',
          themeMode: AppThemeMode.dark,
        ),
      );

      final tokens = tokensOf(tester, find.byType(HomeScreen));
      expect(tokens.isDark, isTrue);
      expect(tokens.bg, const Color(0xFF161826));
    });

    testWidgets('Schwarz ist echtes Schwarz, nicht das dunkle Blaugrau', (
      tester,
    ) async {
      await pumpApp(
        tester,
        settings: const AppSettings(
          languageCode: 'de',
          themeMode: AppThemeMode.black,
        ),
      );

      final tokens = tokensOf(tester, find.byType(HomeScreen));
      expect(tokens.bg, const Color(0xFF000000));
      expect(tokens.isDark, isTrue);
    });

    testWidgets('der Umschalter in den Einstellungen wirkt sofort', (
      tester,
    ) async {
      final store = await pumpApp(
        tester,
        settings: const AppSettings(
          languageCode: 'de',
          themeMode: AppThemeMode.dark,
        ),
      );

      await tapTab(tester, 'Einstellungen');
      await tester.tap(find.text('Hell'));
      await tester.pumpAndSettle();

      expect(tokensOf(tester, find.byType(SettingsScreen)).isDark, isFalse);
      expect((await store.load()).themeMode, AppThemeMode.light);
    });
  });
}
