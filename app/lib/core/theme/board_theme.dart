import 'package:flutter/material.dart';

/// Die Brettfarben sind vom App-Theme entkoppelt: der Entwurf zeigt in den
/// Einstellungen drei Brett-Stile, die unabhängig von hell/dunkel gewählt
/// werden. `nocturne` folgt dem App-Theme, die anderen stehen für sich.
enum BoardStyle {
  /// Graublau, passt sich hell/dunkel an — der Standard aus dem Entwurf.
  nocturne,

  /// Klassisches Holz.
  wood,

  /// Turniergrün.
  green,

  /// Kühles Blau.
  blue,

  /// Sehr kontrastarm, für langes Lesen.
  paper;

  String get storageKey => name;

  static BoardStyle fromStorage(String? value) {
    return BoardStyle.values.firstWhere(
      (s) => s.name == value,
      orElse: () => BoardStyle.nocturne,
    );
  }
}

/// Ein konkretes Farbpaar für die Felder plus die Markierungsfarben, die
/// Training und Lern-Modus brauchen.
@immutable
class BoardColors {
  const BoardColors({
    required this.lightSquare,
    required this.darkSquare,
    required this.coordinateOnLight,
    required this.coordinateOnDark,
  });

  factory BoardColors.of(BoardStyle style, {required bool isDark}) {
    return switch (style) {
      BoardStyle.nocturne when isDark => const BoardColors(
        lightSquare: Color(0xFF484A5E),
        darkSquare: Color(0xFF282A3A),
        coordinateOnLight: Color(0xB3282A3A),
        coordinateOnDark: Color(0xB3484A5E),
      ),
      BoardStyle.nocturne => const BoardColors(
        lightSquare: Color(0xFFDCDEEE),
        darkSquare: Color(0xFF9D9FB8),
        coordinateOnLight: Color(0xB39D9FB8),
        coordinateOnDark: Color(0xCCDCDEEE),
      ),
      BoardStyle.wood => const BoardColors(
        lightSquare: Color(0xFFE8E2CF),
        darkSquare: Color(0xFFA58A63),
        coordinateOnLight: Color(0xB3A58A63),
        coordinateOnDark: Color(0xCCE8E2CF),
      ),
      BoardStyle.green => const BoardColors(
        lightSquare: Color(0xFFD8E6DC),
        darkSquare: Color(0xFF6F8F7D),
        coordinateOnLight: Color(0xB36F8F7D),
        coordinateOnDark: Color(0xCCD8E6DC),
      ),
      BoardStyle.blue => const BoardColors(
        lightSquare: Color(0xFFDEE6F2),
        darkSquare: Color(0xFF6E86A8),
        coordinateOnLight: Color(0xB36E86A8),
        coordinateOnDark: Color(0xCCDEE6F2),
      ),
      BoardStyle.paper => const BoardColors(
        lightSquare: Color(0xFFF2F2F2),
        darkSquare: Color(0xFFC4C4C4),
        coordinateOnLight: Color(0xB3C4C4C4),
        coordinateOnDark: Color(0xCC5A5A5A),
      ),
    };
  }

  final Color lightSquare;
  final Color darkSquare;
  final Color coordinateOnLight;
  final Color coordinateOnDark;

  /// Letzter Zug — im Entwurf ein Akzentschleier, kein Vollton.
  static const Color lastMove = Color(0x59968AE0);

  /// Richtiger Zug im Training.
  static const Color correct = Color(0x665FBF87);

  /// Falscher Zug im Training.
  static const Color wrong = Color(0x66E07A76);

  /// Der Zug, den man hätte spielen sollen.
  static const Color hint = Color(0x66DCAE63);

  /// Auswahl und mögliche Zielfelder.
  static const Color selected = Color(0x40968AE0);
}
