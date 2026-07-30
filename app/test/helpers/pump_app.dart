import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/app.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/settings/app_settings.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/settings/settings_store.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/features/library/data/library_repository.dart';
import 'package:masteropening/features/library/domain/library_opening.dart';
import 'package:masteropening/features/lichess/data/lichess_providers.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Startet die vollständige App mit einem Einstellungsspeicher im Arbeits-
/// speicher — keine Plattformkanäle, kein SharedPreferences-Mock nötig.
///
/// Die Sprache steht standardmäßig fest auf Deutsch: ohne feste Wahl würde die
/// Testumgebung `en_US` melden und Erwartungen an deutsche Beschriftungen
/// scheitern lassen, sobald jemand die Systemsprache des Rechners ändert.
Future<InMemorySettingsStore> pumpApp(
  WidgetTester tester, {
  AppSettings settings = const AppSettings(languageCode: 'de'),
  List<LibraryOpeningSummary> library = const [],
  List<Repertoire> repertoires = const [],
}) async {
  final store = InMemorySettingsStore(settings);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        initialSettingsProvider.overrideWithValue(settings),
        // Bibliothek und Datenbank werden vorgegeben: beide laden echt
        // asynchron, und in einem Widget-Test läuft die Uhr simuliert —
        // `pumpAndSettle` würde sonst am Ladekringel hängen bleiben.
        libraryIndexProvider.overrideWithValue(AsyncValue.data(library)),
        repertoiresProvider.overrideWithValue(AsyncValue.data(repertoires)),
        // Der Lichess-Tab hinge sonst an Schlüsselbund und Datenbank.
        lichessProvider.overrideWith(_StubLichessController.new),
        lichessGamesProvider.overrideWithValue(
          const AsyncValue.data([]),
        ),
      ],
      child: const MasterOpeningApp(),
    ),
  );
  await tester.pumpAndSettle();

  return store;
}

/// Ein Lichess-Tab ohne Konto und ohne Datenzugriff.
class _StubLichessController extends LichessController {
  @override
  Future<LichessState> build() async => const LichessState();
}

/// Rahmen für Einzelwidget-Tests: Theme, Lokalisierung und ein Scaffold, aber
/// ohne Router und ohne die vier Tabs.
Future<void> pumpWidgetInApp(
  WidgetTester tester,
  Widget child, {
  AppTokens tokens = AppTokens.dark,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.build(tokens),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('de'),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );

  // `settle: false` für Widgets mit endloser Animation (Ladespinner) —
  // `pumpAndSettle` würde dort in den Timeout laufen.
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Pumpt in kleinen Schritten, bis [condition] zutrifft.
///
/// Für Bildschirme, die auf eine Datenbankabfrage warten: `pumpAndSettle`
/// kommt dort nie zur Ruhe, weil der Ladespinner endlos weiteranimiert und
/// damit immer den nächsten Frame anfordert.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(reason ?? 'Bedingung wurde innerhalb von $timeout nicht erfüllt.');
    }
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Wartet, bis ein Widget aufgetaucht ist.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) {
  return pumpUntil(
    tester,
    () => finder.evaluate().isNotEmpty,
    timeout: timeout,
    reason: 'Nicht gefunden: ${finder.describeMatch(Plurality.one)}',
  );
}

/// Die Tokens, mit denen der Bildschirm gerade gemalt wird.
AppTokens tokensOf(WidgetTester tester, Finder finder) {
  final context = tester.element(finder);
  return Theme.of(context).extension<AppTokens>()!;
}
