import 'package:flutter/widgets.dart';

/// Abstände, wie sie im Entwurf tatsächlich vorkommen. Der Entwurf arbeitet
/// nicht mit einer reinen Vielfachen-Skala, sondern mit einer kleinen Menge
/// wiederkehrender Werte — die stehen hier und sonst nirgends.
abstract final class AppSpacing {
  /// 4 — zwischen Zeilen innerhalb einer Zelle.
  static const double xxs = 4;

  /// 6 — Icon zu Text.
  static const double xs = 6;

  /// 8 — Chips untereinander, Rasterlücken bei Kacheln.
  static const double sm = 8;

  /// 10 — Standardlücke innerhalb einer Karte.
  static const double md = 10;

  /// 12 — Lücke zwischen kleinen Karten.
  static const double lg = 12;

  /// 14 — Innenabstand einer Karte.
  static const double card = 14;

  /// 16 — Lücke zwischen Blöcken.
  static const double xl = 16;

  /// 18 — seitlicher Bildschirmrand und Abstand zwischen Abschnitten.
  static const double screen = 18;

  /// 24 — Abstand vor einer neuen Überschrift.
  static const double xxl = 24;

  /// 32 — großzügiger Block, z. B. über dem Report-Ergebnis.
  static const double huge = 32;
}

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;

  /// 14 — die große Hero-Karte auf dem Start-Tab.
  static const double xxl = 14;

  /// Vollrund, für Pillen und Schalter.
  static const double pill = 999;

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));
}

abstract final class AppDurations {
  /// Schalter, Chips, Hover — alles, was sofort reagieren soll.
  static const fast = Duration(milliseconds: 180);

  /// Tab-Wechsel, Ein- und Ausblenden von Karten.
  static const medium = Duration(milliseconds: 260);

  /// Zuganimation auf dem Brett, Fortschrittsbalken.
  static const slow = Duration(milliseconds: 420);

  /// Feiern: Level-Up, Achievement, Report-Ergebnis.
  static const celebration = Duration(milliseconds: 900);
}

abstract final class AppCurves {
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeOutBack;
}
