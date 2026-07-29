import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/app_typography.dart';

/// Die vier wählbaren Erscheinungsbilder. `black` ist die AMOLED-Variante:
/// echtes Schwarz statt des dunklen Blaugrau.
enum AppThemeMode {
  system,
  light,
  dark,
  black;

  String get storageKey => name;

  static AppThemeMode fromStorage(String? value) {
    return AppThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  /// Welche Tokens gelten, wenn das Betriebssystem [platformDark] meldet.
  AppTokens resolveTokens({required bool platformDark}) {
    return switch (this) {
      AppThemeMode.light => AppTokens.light,
      AppThemeMode.dark => AppTokens.dark,
      AppThemeMode.black => AppTokens.black,
      AppThemeMode.system => platformDark ? AppTokens.dark : AppTokens.light,
    };
  }
}

abstract final class AppTheme {
  static ThemeData build(AppTokens tokens) {
    final textTheme = AppTypography.build(tokens.text);
    final brightness = tokens.isDark ? Brightness.dark : Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.accent,
      onPrimary: tokens.isDark
          ? const Color(0xFF161826)
          : const Color(0xFFF5F4FF),
      secondary: tokens.accentMuted,
      onSecondary: tokens.isDark
          ? const Color(0xFF161826)
          : const Color(0xFFF5F4FF),
      error: tokens.danger,
      onError: tokens.isDark
          ? const Color(0xFF161826)
          : const Color(0xFFFFF5F5),
      surface: tokens.surface,
      onSurface: tokens.text,
      surfaceContainerLowest: tokens.bg,
      surfaceContainerLow: tokens.surfaceSunken,
      surfaceContainer: tokens.surface,
      outline: tokens.divider,
      outlineVariant: tokens.hairline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.bg,
      canvasColor: tokens.bg,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      extensions: [tokens],

      // Nocturne kennt keine Material-Wellen: Rückmeldung kommt über Farbe
      // und Bewegung, nicht über einen aufsteigenden Kreis.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: tokens.textAlpha(0.05),

      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: tokens.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: tokens.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: tokens.surface,
        showDragHandle: true,
        dragHandleColor: tokens.textAlpha(0.25),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.allXxl,
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.textAlpha(0.85),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.surface,
        contentTextStyle: textTheme.bodyMedium,
        actionTextColor: tokens.accent,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        elevation: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.textAlpha(0.45),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: tokens.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: tokens.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: tokens.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: tokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: tokens.danger),
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: tokens.accent,
        selectionColor: tokens.accentAlpha(0.3),
        selectionHandleColor: tokens.accent,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.accent,
        linearTrackColor: tokens.textAlpha(0.12),
        circularTrackColor: tokens.textAlpha(0.12),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: tokens.accent,
        inactiveTrackColor: tokens.textAlpha(0.12),
        thumbColor: tokens.accent,
        overlayColor: tokens.accentAlpha(0.15),
        trackHeight: 4,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: tokens.textAlpha(0.6),
        textColor: tokens.text,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.labelMedium?.copyWith(
          color: tokens.textAlpha(0.5),
        ),
      ),

      iconTheme: IconThemeData(color: tokens.text, size: 20),

      // Überall derselbe Übergang: Nocturne blendet und schiebt leicht, statt
      // je Plattform eine andere Bewegung zu zeigen.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Status- und Navigationsleiste an das Theme angleichen. Wird bei jedem
  /// Theme-Wechsel gesetzt, damit die Systemleisten nicht zurückbleiben.
  static SystemUiOverlayStyle overlayStyle(AppTokens tokens) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: tokens.isDark
          ? Brightness.light
          : Brightness.dark,
      statusBarBrightness: tokens.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: tokens.bg,
      systemNavigationBarIconBrightness: tokens.isDark
          ? Brightness.light
          : Brightness.dark,
    );
  }
}
