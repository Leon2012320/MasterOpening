import 'package:dartchess/dartchess.dart' show Side;
import 'package:meta/meta.dart';

/// Eine Eröffnungsfalle, die im Fallen-Modus widerlegt werden soll.
///
/// [pgn] enthält die ganze Linie: bis [askFromPly] den Anlauf samt dem
/// Fallenzug des Gegners, danach die Widerlegung, die der Nutzer finden muss.
@immutable
class OpeningTrap {
  const OpeningTrap({
    required this.id,
    required this.side,
    required this.eco,
    required this.askFromPly,
    required this.pgn,
    required this.nameDe,
    required this.nameEn,
    required this.whyDe,
    required this.whyEn,
  });

  factory OpeningTrap.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as Map<String, dynamic>;
    final why = json['why'] as Map<String, dynamic>;
    return OpeningTrap(
      id: json['id'] as String,
      side: json['side'] == 'black' ? Side.black : Side.white,
      eco: json['eco'] as String,
      askFromPly: json['askFromPly'] as int,
      pgn: json['pgn'] as String,
      nameDe: name['de'] as String,
      nameEn: name['en'] as String,
      whyDe: why['de'] as String,
      whyEn: why['en'] as String,
    );
  }

  final String id;

  /// Die Farbe, mit der der Nutzer spielt — also die Seite, die widerlegt.
  final Side side;

  final String eco;

  /// Ab diesem Halbzug wird gefragt.
  final int askFromPly;

  final String pgn;
  final String nameDe;
  final String nameEn;
  final String whyDe;
  final String whyEn;

  String name(String languageCode) => languageCode == 'de' ? nameDe : nameEn;

  String why(String languageCode) => languageCode == 'de' ? whyDe : whyEn;
}
