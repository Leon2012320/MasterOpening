import 'package:flutter/material.dart';

/// Inter mit den Größen und Laufweiten aus dem Entwurf.
///
/// Nocturne setzt Überschriften auf Gewicht 500 (nicht 600/700) und zieht sie
/// mit `letter-spacing: -0.015em` leicht zusammen; Fließtext bleibt bei 400 mit
/// Zeilenhöhe 1.55. Die CSS-`em`-Werte sind hier in logische Pixel umgerechnet.
abstract final class AppTypography {
  static const fontFamily = 'Inter';

  static const FontWeight _headingWeight = FontWeight.w500;
  static const FontWeight _bodyWeight = FontWeight.w400;

  /// Ziffern mit fester Breite. Zahlen, die sich laufend ändern (Timer,
  /// Genauigkeit, Zugzähler), dürfen dabei nicht springen.
  static const FontFeature tabular = FontFeature.tabularFigures();

  static TextTheme build(Color color) {
    TextStyle heading(double size, double height, double trackingEm) {
      return TextStyle(
        fontFamily: fontFamily,
        color: color,
        fontSize: size,
        height: height,
        fontWeight: _headingWeight,
        letterSpacing: size * trackingEm,
      );
    }

    TextStyle body(double size, double height, {FontWeight? weight}) {
      return TextStyle(
        fontFamily: fontFamily,
        color: color,
        fontSize: size,
        height: height,
        fontWeight: weight ?? _bodyWeight,
      );
    }

    return TextTheme(
      // Nur auf Feier-Screens: Level-Up, Report-Ergebnis.
      displayLarge: heading(38, 1.08, -0.02),
      displayMedium: heading(32, 1.1, -0.02),
      // Bildschirmtitel: „Bibliothek", „Guten Abend, …".
      displaySmall: heading(27, 1.1, -0.02),
      headlineLarge: heading(25, 1.12, -0.015),
      // Kennzahlen auf Kacheln — immer zusammen mit [tabular] verwenden.
      headlineMedium: heading(22, 1.15, -0.02),
      // Kartentitel.
      headlineSmall: heading(19, 1.2, -0.01),
      titleLarge: heading(17, 1.2, -0.01),
      titleMedium: body(15, 1.3, weight: FontWeight.w500),
      titleSmall: body(14, 1.3, weight: FontWeight.w500),
      bodyLarge: body(15, 1.55),
      bodyMedium: body(14, 1.45),
      bodySmall: body(13, 1.4),
      labelLarge: body(12, 1.3),
      labelMedium: body(11, 1.3),
      labelSmall: body(10, 1.2),
    );
  }
}

/// Wiederkehrende Textrollen, die keiner Material-Kategorie entsprechen.
extension AppTextStyles on BuildContext {
  TextTheme get _t => Theme.of(this).textTheme;

  /// Die versalen Mini-Überschriften über jedem Abschnitt
  /// (`ALS NÄCHSTES`, `DARSTELLUNG`).
  TextStyle get kickerStyle => _t.labelMedium!.copyWith(
    letterSpacing: 1.1,
    fontWeight: FontWeight.w500,
  );

  /// Kennzahl auf einer Kachel.
  TextStyle get statStyle =>
      _t.headlineMedium!.copyWith(fontFeatures: const [AppTypography.tabular]);

  /// Zugnotation. Muss tabellarisch sein, damit Zuglisten nicht flackern.
  TextStyle get moveStyle =>
      _t.bodySmall!.copyWith(fontFeatures: const [AppTypography.tabular]);
}
