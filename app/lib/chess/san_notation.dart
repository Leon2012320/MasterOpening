import 'package:dartchess/dartchess.dart';

/// Übersetzt die Zugnotation für die Anzeige.
///
/// Gespeichert wird immer die englische Standardnotation — das ist, was PGN
/// vorschreibt, und alles, was exportiert oder importiert wird, muss damit
/// zusammenpassen. Nur die Oberfläche zeigt die Figurenbuchstaben der
/// eingestellten Sprache: `Nf3` wird auf Deutsch zu `Sf3`.
abstract final class SanNotation {
  /// Figurenbuchstaben je Sprache, in der Reihenfolge K, Q, R, B, N.
  static const _pieceLetters = <String, Map<String, String>>{
    'de': {'K': 'K', 'Q': 'D', 'R': 'T', 'B': 'L', 'N': 'S'},
    'en': {'K': 'K', 'Q': 'Q', 'R': 'R', 'B': 'B', 'N': 'N'},
  };

  /// Übersetzt einen einzelnen Zug in SAN.
  ///
  /// Betroffen sind nur der führende Figurenbuchstabe und die Umwandlung
  /// hinter dem `=`. Linienbuchstaben sind klein geschrieben und bleiben
  /// unangetastet, Rochade und Schach-/Mattzeichen ebenso.
  static String localize(String san, String languageCode) {
    final letters = _pieceLetters[languageCode];
    if (letters == null || san.isEmpty) return san;

    final buffer = StringBuffer();

    // Führender Figurenbuchstabe.
    var index = 0;
    final first = san[0];
    if (letters.containsKey(first)) {
      buffer.write(letters[first]);
      index = 1;
    }

    // Rest zeichenweise, mit Sonderbehandlung der Umwandlung.
    for (; index < san.length; index++) {
      final char = san[index];
      if (char == '=' && index + 1 < san.length) {
        final promoted = san[index + 1];
        buffer
          ..write('=')
          ..write(letters[promoted] ?? promoted);
        index++;
        continue;
      }
      buffer.write(char);
    }

    return buffer.toString();
  }

  /// Übersetzt eine ganze Zugfolge.
  static List<String> localizeAll(List<String> sans, String languageCode) => [
    for (final san in sans) localize(san, languageCode),
  ];

  /// Der umgekehrte Weg: aus lokalisierter Eingabe wieder Standard-SAN. Wird
  /// gebraucht, wenn jemand einen Zug tippt statt ihn zu ziehen.
  static String normalize(String input, String languageCode) {
    final letters = _pieceLetters[languageCode];
    if (letters == null || input.isEmpty) return input;

    final reversed = {
      for (final entry in letters.entries) entry.value: entry.key,
    };

    final buffer = StringBuffer();
    var index = 0;
    final first = input[0];
    if (reversed.containsKey(first)) {
      buffer.write(reversed[first]);
      index = 1;
    }

    for (; index < input.length; index++) {
      final char = input[index];
      if (char == '=' && index + 1 < input.length) {
        final promoted = input[index + 1];
        buffer
          ..write('=')
          ..write(reversed[promoted] ?? promoted);
        index++;
        continue;
      }
      buffer.write(char);
    }

    return buffer.toString();
  }

  /// Wie ein Halbzug in einer Zugliste beschriftet wird: „12." für Weiß,
  /// „12…" für Schwarz, wenn dieser Halbzug eine Zeile beginnt.
  static String moveNumberLabel(int ply, {required bool forceBlackEllipsis}) {
    final number = (ply + 1) ~/ 2;
    final isWhite = ply.isOdd;
    if (isWhite) return '$number.';
    return forceBlackEllipsis ? '$number…' : '';
  }

  /// Der Name einer Seite in der eingestellten Sprache.
  static String sideLabel(Side side, String languageCode) {
    if (languageCode == 'de') {
      return side == Side.white ? 'Weiß' : 'Schwarz';
    }
    return side == Side.white ? 'White' : 'Black';
  }
}
