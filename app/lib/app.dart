import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/router/app_router.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

class MasterOpeningApp extends ConsumerWidget {
  const MasterOpeningApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    final lightTheme = AppTheme.build(AppTokens.light);

    // Material kennt nur zwei Theme-Steckplätze, wir haben drei Paletten.
    // „Schwarz" reist deshalb im Dunkel-Steckplatz mit; welche Palette dort
    // landet, entscheidet die Nutzerwahl.
    final (dark, mode) = switch (settings.themeMode) {
      AppThemeMode.system => (
        AppTheme.build(AppTokens.dark),
        ThemeMode.system,
      ),
      AppThemeMode.light => (lightTheme, ThemeMode.light),
      AppThemeMode.dark => (AppTheme.build(AppTokens.dark), ThemeMode.dark),
      AppThemeMode.black => (AppTheme.build(AppTokens.black), ThemeMode.dark),
    };

    return MaterialApp.router(
      title: 'MasterOpening',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: lightTheme,
      darkTheme: dark,
      themeMode: mode,
      locale: settings.languageCode == null
          ? null
          : Locale(settings.languageCode!),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) {
        // Systemleisten an das gerade geltende Theme angleichen. Muss hier
        // stehen, nicht in `main()`: bei `ThemeMode.system` ändert sich das
        // Ergebnis, ohne dass die App etwas tut.
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.overlayStyle(context.tokens),
          child: MediaQuery.withClampedTextScaling(
            // Sehr große Systemschrift bricht das Brett-plus-Zugliste-Layout;
            // 1.3 ist die Grenze, bis zu der alles lesbar bleibt.
            maxScaleFactor: 1.3,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
