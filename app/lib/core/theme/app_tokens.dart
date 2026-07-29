import 'package:flutter/material.dart';

/// Die Design-Tokens des Nocturne-Systems, wie sie im Entwurf festgelegt sind.
///
/// Kein Widget darf Farben, Radien oder Schatten selbst literalisieren — alles
/// kommt über `Theme.of(context).tokens` aus dieser Erweiterung. Dadurch bleibt
/// das Erscheinungsbild beider Paletten an einer Stelle definiert.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.surfaceSunken,
    required this.text,
    required this.accent,
    required this.accentMuted,
    required this.divider,
    required this.hairline,
    required this.shadowAmbient,
    required this.success,
    required this.danger,
    required this.warning,
    required this.tagAccentBg,
    required this.tagAccentFg,
    required this.tagNeutralBg,
    required this.tagNeutralFg,
    required this.heatScale,
    required this.isDark,
  });

  /// Bildschirmgrund.
  final Color bg;

  /// Karten und erhabene Flächen.
  final Color surface;

  /// Vertiefte Flächen: Fortschrittsbalken-Spuren, Eingabefelder auf Karten.
  final Color surfaceSunken;

  /// Primäre Textfarbe. Abstufungen entstehen über [textAlpha].
  final Color text;

  /// Akzent. Erscheint als Linie und Kontur, fast nie als Fläche.
  final Color accent;

  /// Akzent auf Flächen, wo voller Akzent zu laut wäre (Chart-Sekundärlinien).
  final Color accentMuted;

  /// Trennlinien. Freistehende Linien laufen an den Enden aus, siehe
  /// `FadingDivider`.
  final Color divider;

  /// Der 1-px-Rand, der bei Nocturne die Rolle des Schattens übernimmt.
  final Color hairline;

  /// Der weiche Schatten unter dem Haarrand.
  final Color shadowAmbient;

  final Color success;
  final Color danger;
  final Color warning;

  final Color tagAccentBg;
  final Color tagAccentFg;
  final Color tagNeutralBg;
  final Color tagNeutralFg;

  /// Fünf Stufen für die Aktivitäts-Heatmap, von „nichts getan" bis „viel".
  final List<Color> heatScale;

  final bool isDark;

  /// Text mit reduzierter Deckkraft — die Art, wie der Entwurf Hierarchie
  /// erzeugt (`opacity:.55`, `.45`, …), statt über zusätzliche Grautöne.
  Color textAlpha(double opacity) => text.withValues(alpha: opacity);

  /// Akzentfläche mit niedriger Deckkraft, z. B. hinter Eröffnungs-Icons.
  Color accentAlpha(double opacity) => accent.withValues(alpha: opacity);

  /// Haarrand ohne Weichzeichnung — das `0 0 0 1px` aus dem CSS.
  List<BoxShadow> get shadowSm => [
    BoxShadow(color: hairline, spreadRadius: 1),
  ];

  List<BoxShadow> get shadowMd => [
    BoxShadow(color: hairline, spreadRadius: 1),
    BoxShadow(
      color: shadowAmbient,
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  List<BoxShadow> get shadowLg => [
    BoxShadow(color: hairline, spreadRadius: 1),
    BoxShadow(
      color: shadowAmbient,
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  @override
  AppTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceSunken,
    Color? text,
    Color? accent,
    Color? accentMuted,
    Color? divider,
    Color? hairline,
    Color? shadowAmbient,
    Color? success,
    Color? danger,
    Color? warning,
    Color? tagAccentBg,
    Color? tagAccentFg,
    Color? tagNeutralBg,
    Color? tagNeutralFg,
    List<Color>? heatScale,
    bool? isDark,
  }) {
    return AppTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      divider: divider ?? this.divider,
      hairline: hairline ?? this.hairline,
      shadowAmbient: shadowAmbient ?? this.shadowAmbient,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      tagAccentBg: tagAccentBg ?? this.tagAccentBg,
      tagAccentFg: tagAccentFg ?? this.tagAccentFg,
      tagNeutralBg: tagNeutralBg ?? this.tagNeutralBg,
      tagNeutralFg: tagNeutralFg ?? this.tagNeutralFg,
      heatScale: heatScale ?? this.heatScale,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      text: Color.lerp(text, other.text, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      shadowAmbient: Color.lerp(shadowAmbient, other.shadowAmbient, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      tagAccentBg: Color.lerp(tagAccentBg, other.tagAccentBg, t)!,
      tagAccentFg: Color.lerp(tagAccentFg, other.tagAccentFg, t)!,
      tagNeutralBg: Color.lerp(tagNeutralBg, other.tagNeutralBg, t)!,
      tagNeutralFg: Color.lerp(tagNeutralFg, other.tagNeutralFg, t)!,
      heatScale: [
        for (var i = 0; i < heatScale.length; i++)
          Color.lerp(heatScale[i], other.heatScale[i], t)!,
      ],
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }

  // ── Die beiden ausgelieferten Paletten ────────────────────────────────────

  static const dark = AppTokens(
    bg: Color(0xFF161826),
    surface: Color(0xFF232532),
    surfaceSunken: Color(0xFF1B1D2A),
    text: Color(0xFFE9E9ED),
    accent: Color(0xFF968AE0),
    accentMuted: Color(0xFF796CBF),
    divider: Color(0x29E9E9ED), // text @ 16 %
    hairline: Color(0xFF3F424D),
    shadowAmbient: Color(0x8C000000),
    success: Color(0xFF5FBF87),
    danger: Color(0xFFE07A76),
    warning: Color(0xFFDCAE63),
    tagAccentBg: Color(0xFF423A6A),
    tagAccentFg: Color(0xFFF5F4FF),
    tagNeutralBg: Color(0xFF3F424D),
    tagNeutralFg: Color(0xFFF3F5FE),
    heatScale: [
      Color(0xFF222431),
      Color(0xFF2B2741),
      Color(0xFF423A6A),
      Color(0xFF5D5294),
      Color(0xFF968AE0),
    ],
    isDark: true,
  );

  static const light = AppTokens(
    bg: Color(0xFFECEEFA),
    surface: Color(0xFFF9FAFE),
    surfaceSunken: Color(0xFFE3E6F4),
    text: Color(0xFF23252F),
    accent: Color(0xFF5D5294),
    accentMuted: Color(0xFF796CBF),
    divider: Color(0x2423252F), // text @ 14 %
    hairline: Color(0xFFD3D6E8),
    shadowAmbient: Color(0x1423252F),
    success: Color(0xFF2E7D54),
    danger: Color(0xFFB33F3B),
    warning: Color(0xFF8F6420),
    tagAccentBg: Color(0xFFD2CEFD),
    tagAccentFg: Color(0xFF2B2741),
    tagNeutralBg: Color(0xFFDFE2F0),
    tagNeutralFg: Color(0xFF3F424D),
    heatScale: [
      Color(0xFFE0E3F2),
      Color(0xFFD2CEFD),
      Color(0xFFB5ABFC),
      Color(0xFF8A7ED6),
      Color(0xFF5D5294),
    ],
    isDark: false,
  );
}

/// Bequemer Zugriff: `context.tokens.accent` statt
/// `Theme.of(context).extension<AppTokens>()!`.
extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.dark;
}
