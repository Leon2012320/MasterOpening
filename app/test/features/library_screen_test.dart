import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masteropening/core/settings/app_settings.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/settings/settings_store.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/features/library/data/library_repository.dart';
import 'package:masteropening/features/library/domain/library_filter.dart';
import 'package:masteropening/features/library/domain/library_opening.dart';
import 'package:masteropening/features/library/presentation/library_screen.dart';
import 'package:masteropening/features/library/presentation/widgets/opening_row.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

import '../helpers/asset_bundle.dart';

const _settings = AppSettings(languageCode: 'de', boardAnimations: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<LibraryOpeningSummary> index;

  setUpAll(() async {
    index = await LibraryRepository(bundle: FileAssetBundle()).index();
  });

  group('LibraryFilter', () {
    test('ohne Einstellung bleibt alles sichtbar', () {
      expect(const LibraryFilter().apply(index), hasLength(index.length));
      expect(const LibraryFilter().isActive, isFalse);
    });

    test('filtert nach Farbe', () {
      final white = const LibraryFilter(side: Side.white).apply(index);

      expect(white, isNotEmpty);
      expect(white.every((o) => o.side == Side.white), isTrue);
      expect(white.length, lessThan(index.length));
    });

    test('sucht in Name, ECO-Code und Zugfolge', () {
      expect(
        const LibraryFilter(query: 'Spanisch').apply(index).single.id,
        'ruy-lopez',
      );
      expect(
        const LibraryFilter(query: 'C65').apply(index).single.id,
        'berlin-defence',
      );
      expect(
        const LibraryFilter(query: '1. d4 f5').apply(index).single.id,
        'dutch-defence',
      );
    });

    test('die Suche ignoriert Gross- und Kleinschreibung', () {
      expect(
        const LibraryFilter(query: 'nAjDoRf').apply(index).single.id,
        'sicilian-najdorf',
      );
    });

    test('mehrere Merkmale verlangen alle gleichzeitig', () {
      final single = const LibraryFilter(
        tags: {OpeningTag.gambit},
      ).apply(index);
      final both = const LibraryFilter(
        tags: {OpeningTag.gambit, OpeningTag.attacking},
      ).apply(index);

      expect(single, isNotEmpty);
      expect(both.length, lessThanOrEqualTo(single.length));
      expect(
        both.every(
          (o) =>
              o.tags.contains(OpeningTag.gambit) &&
              o.tags.contains(OpeningTag.attacking),
        ),
        isTrue,
      );
    });

    test('Merkmale lassen sich an- und wieder abschalten', () {
      const filter = LibraryFilter();
      final on = filter.toggleTag(OpeningTag.solid);
      expect(on.tags, {OpeningTag.solid});
      expect(on.toggleTag(OpeningTag.solid).tags, isEmpty);
    });

    test('Farbe und Suche greifen zusammen', () {
      final result = const LibraryFilter(
        query: 'Sizilianisch',
        side: Side.black,
      ).apply(index);

      expect(result, isNotEmpty);
      expect(result.every((o) => o.side == Side.black), isTrue);
      expect(result.any((o) => o.id == 'alapin-sicilian'), isFalse);
    });
  });

  group('Bibliothek-Tab', () {
    // Der Index wird vorab geladen und als fertiger Wert eingesetzt: in einem
    // Widget-Test läuft die Uhr simuliert, echte Datei-Zugriffe kämen darin
    // nie zum Ende.
    Future<void> pumpLibrary(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryIndexProvider.overrideWithValue(AsyncValue.data(index)),
            // Ohne diese Vorgabe würde der Bildschirm die echte Datenbank
            // öffnen, nur um zu erfahren, was schon im Repertoire steht.
            repertoiresProvider.overrideWithValue(
              const AsyncValue.data([]),
            ),
            settingsStoreProvider.overrideWithValue(
              InMemorySettingsStore(_settings),
            ),
            initialSettingsProvider.overrideWithValue(_settings),
          ],
          child: MaterialApp(
            theme: AppTheme.build(AppTokens.dark),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            locale: const Locale('de'),
            home: const LibraryScreen(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('zeigt Eröffnungen mit Name und ECO-Code', (tester) async {
      await pumpLibrary(tester);

      expect(find.byType(OpeningRow), findsWidgets);
      expect(find.text('Spanische Partie'), findsOneWidget);
      expect(find.text('C60'), findsOneWidget);
    });

    testWidgets('nennt die Zahl der Treffer', (tester) async {
      await pumpLibrary(tester);

      expect(find.text('${index.length} Eröffnungen'), findsOneWidget);
    });

    testWidgets('die Suche schränkt die Liste ein', (tester) async {
      await pumpLibrary(tester);

      await tester.enterText(find.byType(TextField), 'Najdorf');
      await tester.pump();

      expect(find.text('1 Eröffnung'), findsOneWidget);
      expect(find.byType(OpeningRow), findsOneWidget);
    });

    testWidgets('eine Suche ohne Treffer erklärt sich', (tester) async {
      await pumpLibrary(tester);

      await tester.enterText(find.byType(TextField), 'gibt es nicht');
      await tester.pump();

      expect(find.text('Nichts gefunden'), findsOneWidget);
      expect(find.byType(OpeningRow), findsNothing);
    });

    testWidgets('der Farbfilter reduziert die Liste', (tester) async {
      await pumpLibrary(tester);

      await tester.tap(find.text('Schwarz'));
      await tester.pump();

      final black = index.where((o) => o.side == Side.black).length;
      expect(find.text('$black Eröffnungen'), findsOneWidget);
    });

    testWidgets('der Zurücksetzen-Knopf erscheint erst bei aktivem Filter', (
      tester,
    ) async {
      await pumpLibrary(tester);
      expect(find.text('Filter zurücksetzen'), findsNothing);

      await tester.tap(find.text('Weiß'));
      await tester.pump();
      expect(find.text('Filter zurücksetzen'), findsOneWidget);

      await tester.tap(find.text('Filter zurücksetzen'));
      await tester.pump();
      expect(find.text('${index.length} Eröffnungen'), findsOneWidget);
    });

    testWidgets('ein Merkmal filtert die Liste', (tester) async {
      await pumpLibrary(tester);

      await tester.tap(find.text('Angriff'));
      await tester.pump();

      final attacking = index
          .where((o) => o.tags.contains(OpeningTag.attacking))
          .length;
      expect(attacking, greaterThan(0));
      expect(find.text('$attacking Eröffnungen'), findsOneWidget);
    });
  });
}
