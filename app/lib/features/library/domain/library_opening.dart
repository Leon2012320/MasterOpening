import 'package:dartchess/dartchess.dart' show Side;
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:meta/meta.dart';

/// Die Stil-Merkmale einer Eröffnung.
///
/// Sie dienen als Filter in der Bibliothek und als Grundlage für die
/// Spielstil-Empfehlung: dort wird das Profil aus den eigenen Partien mit
/// diesen Merkmalen abgeglichen.
enum OpeningTag {
  attacking,
  solid,
  tactical,
  positional,
  open,
  closed,
  gambit,
  system,
  classical,
  modern,
  flexible,
  universal,
  beginnerFriendly,
  theoryLight,
  theoryHeavy;

  static OpeningTag? fromName(String value) {
    for (final tag in OpeningTag.values) {
      if (tag.name == value) return tag;
    }
    return null;
  }
}

/// Ein typischer Fehler in dieser Eröffnung, samt der Zugfolge, die dorthin
/// führt. Der letzte Zug der Folge *ist* der Fehler.
@immutable
class OpeningMistake {
  const OpeningMistake({
    required this.pgn,
    required this.whyDe,
    required this.whyEn,
  });

  factory OpeningMistake.fromJson(Map<String, dynamic> json) {
    final why = json['why'] as Map<String, dynamic>;
    return OpeningMistake(
      pgn: json['line'] as String,
      whyDe: why['de'] as String,
      whyEn: why['en'] as String,
    );
  }

  final String pgn;
  final String whyDe;
  final String whyEn;

  String why(String languageCode) => languageCode == 'de' ? whyDe : whyEn;
}

/// Der Listeneintrag einer Bibliothekseröffnung.
///
/// Enthält alles für Liste, Suche und Filter — aber nicht den Variantenbaum.
/// Der steckt in einer eigenen Datei und wird erst beim Öffnen geladen.
@immutable
class LibraryOpeningSummary {
  const LibraryOpeningSummary({
    required this.id,
    required this.eco,
    required this.side,
    required this.seedPgn,
    required this.tags,
    required this.difficulty,
    required this.popularity,
    required this.nodeCount,
    required this.lineCount,
    required this.nameDe,
    required this.nameEn,
    required this.summaryDe,
    required this.summaryEn,
  });

  factory LibraryOpeningSummary.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as Map<String, dynamic>;
    final summary = json['summary'] as Map<String, dynamic>;
    return LibraryOpeningSummary(
      id: json['id'] as String,
      eco: json['eco'] as String,
      side: json['side'] == 'black' ? Side.black : Side.white,
      seedPgn: json['seed'] as String,
      tags: [
        for (final tag in json['tags'] as List<dynamic>)
          ?OpeningTag.fromName(tag as String),
      ],
      difficulty: json['difficulty'] as int,
      popularity: json['popularity'] as int,
      nodeCount: json['nodeCount'] as int,
      lineCount: json['lineCount'] as int,
      nameDe: name['de'] as String,
      nameEn: name['en'] as String,
      summaryDe: summary['de'] as String,
      summaryEn: summary['en'] as String,
    );
  }

  final String id;

  /// ECO-Code der Eröffnung, z. B. `C65`.
  final String eco;

  /// Für welche Farbe die Eröffnung gedacht ist.
  final Side side;

  /// Die Zugfolge, ab der die Eröffnung beginnt — in PGN-Schreibweise.
  final String seedPgn;

  final List<OpeningTag> tags;

  /// 1 (leicht) bis 5 (sehr anspruchsvoll).
  final int difficulty;

  /// 0 bis 100 — wie verbreitet die Eröffnung in der Praxis ist.
  final int popularity;

  final int nodeCount;
  final int lineCount;

  final String nameDe;
  final String nameEn;
  final String summaryDe;
  final String summaryEn;

  String name(String languageCode) => languageCode == 'de' ? nameDe : nameEn;

  String summary(String languageCode) =>
      languageCode == 'de' ? summaryDe : summaryEn;

  /// Die Stellung nach der Startfolge — das Symbol der Eröffnung.
  ///
  /// Wird aus [seedPgn] gerechnet und nicht in den Daten mitgeführt: die
  /// Startfolge ist nur wenige Züge lang, und der Erzeuger in `tools/` hat
  /// keinen Schachmotor, der ein FEN ausrechnen könnte.
  String get iconFen {
    var node = PgnIo.parse(seedPgn).tree.children.firstOrNull;
    var fen = RepertoireTree.initialFen;
    while (node != null) {
      fen = node.fenAfter;
      node = node.children.firstOrNull;
    }
    return fen;
  }

  /// Die Startfolge als reine Zugliste, für die Anzeige unter dem Namen.
  List<String> get seedMoves => [
    for (final node in PgnIo.parse(seedPgn).tree.walk()) node.san,
  ];

  /// Ob der Suchbegriff auf Name, ECO-Code oder Zugfolge passt.
  bool matches(String query) {
    if (query.isEmpty) return true;
    final needle = query.toLowerCase().trim();
    return nameDe.toLowerCase().contains(needle) ||
        nameEn.toLowerCase().contains(needle) ||
        eco.toLowerCase().contains(needle) ||
        seedPgn.toLowerCase().contains(needle);
  }

  @override
  bool operator ==(Object other) =>
      other is LibraryOpeningSummary && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Eine Bibliothekseröffnung mit allem, was die Detailseite braucht.
@immutable
class LibraryOpening {
  const LibraryOpening({
    required this.summary,
    required this.pgn,
    required this.plansDe,
    required this.plansEn,
    required this.mistakes,
    required this.maxDepth,
  });

  factory LibraryOpening.fromJson(Map<String, dynamic> json) {
    final plans = json['plans'] as Map<String, dynamic>;
    return LibraryOpening(
      summary: LibraryOpeningSummary.fromJson(json),
      pgn: json['pgn'] as String,
      plansDe: [
        for (final plan in plans['de'] as List<dynamic>) plan as String,
      ],
      plansEn: [
        for (final plan in plans['en'] as List<dynamic>) plan as String,
      ],
      mistakes: [
        for (final mistake in json['mistakes'] as List<dynamic>)
          OpeningMistake.fromJson(mistake as Map<String, dynamic>),
      ],
      maxDepth: json['maxDepth'] as int,
    );
  }

  final LibraryOpeningSummary summary;

  /// Der vollständige Variantenbaum ab der Grundstellung.
  final String pgn;

  final List<String> plansDe;
  final List<String> plansEn;
  final List<OpeningMistake> mistakes;

  /// Tiefe des Baums in Halbzügen.
  final int maxDepth;

  String get id => summary.id;

  List<String> plans(String languageCode) =>
      languageCode == 'de' ? plansDe : plansEn;
}
