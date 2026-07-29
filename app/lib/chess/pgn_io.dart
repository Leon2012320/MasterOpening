import 'package:dartchess/dartchess.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:meta/meta.dart';

/// Ergebnis eines PGN-Imports.
///
/// Warnungen statt Ausnahmen: eine Studie von Lichess oder ein Download von
/// irgendwo enthält gern einen Zug, der nicht legal ist, oder einen Kopf ohne
/// Wert. Der Rest der Datei ist deswegen trotzdem brauchbar — der Nutzer
/// soll sehen, was übersprungen wurde, und nicht vor einer Fehlermeldung
/// stehen.
@immutable
class PgnImportResult {
  const PgnImportResult({
    required this.tree,
    required this.headers,
    this.warnings = const [],
  });

  final RepertoireTree tree;
  final Map<String, String> headers;
  final List<String> warnings;

  String? get event => _header('Event');
  String? get white => _header('White');
  String? get black => _header('Black');
  String? get eco => _header('ECO');
  String? get openingName => _header('Opening');

  /// Ein aus dem Kopf abgeleiteter Vorschlag für den Repertoire-Namen.
  String get suggestedName {
    final opening = openingName;
    if (opening != null) return opening;
    final event = this.event;
    if (event != null) return event;
    return 'Importiertes Repertoire';
  }

  String? _header(String key) {
    final value = headers[key];
    if (value == null || value.isEmpty || value == '?') return null;
    return value;
  }
}

/// Liest und schreibt PGN — mit Varianten, Kommentaren und NAGs.
abstract final class PgnIo {
  /// Liest die erste Partie aus [pgn].
  static PgnImportResult parse(String pgn) {
    final game = PgnGame.parsePgn(pgn);
    return _fromGame(game);
  }

  /// Liest alle Partien aus einer Sammel-PGN — so liefert Lichess eine
  /// exportierte Studie: ein Kapitel je Partie.
  static List<PgnImportResult> parseAll(String pgn) {
    final games = PgnGame.parseMultiGamePgn(pgn);
    return [for (final game in games) _fromGame(game)];
  }

  /// Fasst alle Kapitel einer Studie zu einem Baum zusammen. Kapitel mit
  /// abweichender Grundstellung werden übersprungen und gemeldet.
  static PgnImportResult parseStudy(String pgn) {
    final chapters = parseAll(pgn);
    if (chapters.isEmpty) {
      return const PgnImportResult(
        tree: RepertoireTree.empty(),
        headers: {},
        warnings: ['Die Datei enthält keine lesbare Partie.'],
      );
    }
    if (chapters.length == 1) return chapters.first;

    var merged = chapters.first.tree;
    final warnings = [...chapters.first.warnings];

    for (final chapter in chapters.skip(1)) {
      warnings.addAll(chapter.warnings);
      if (chapter.tree.startFen != merged.startFen) {
        warnings.add(
          'Kapitel „${chapter.suggestedName}" beginnt aus einer anderen '
          'Stellung und wurde übersprungen.',
        );
        continue;
      }
      merged = merged.merge(chapter.tree);
    }

    return PgnImportResult(
      tree: merged,
      headers: chapters.first.headers,
      warnings: warnings,
    );
  }

  static PgnImportResult _fromGame(PgnGame<PgnNodeData> game) {
    final warnings = <String>[];
    final fenHeader = game.headers['FEN'];

    Position start;
    var startFen = RepertoireTree.initialFen;
    if (fenHeader != null && fenHeader.isNotEmpty) {
      try {
        start = Chess.fromSetup(Setup.parseFen(fenHeader));
        startFen = start.fen;
      } on Object {
        warnings.add(
          'Die Grundstellung im Kopf ist unlesbar; es wird von der '
          'Ausgangsstellung ausgegangen.',
        );
        start = Chess.initial;
      }
    } else {
      start = Chess.initial;
    }

    final children = _convertLevel(
      pgnChildren: game.moves.children,
      position: start,
      startFen: startFen,
      uciPath: const [],
      ply: 1,
      warnings: warnings,
    );

    return PgnImportResult(
      tree: RepertoireTree(startFen: startFen, children: children),
      headers: Map.unmodifiable(game.headers),
      warnings: warnings,
    );
  }

  static List<RepertoireNode> _convertLevel({
    required List<PgnChildNode<PgnNodeData>> pgnChildren,
    required Position position,
    required String startFen,
    required List<String> uciPath,
    required int ply,
    required List<String> warnings,
  }) {
    final result = <RepertoireNode>[];

    for (final child in pgnChildren) {
      final move = position.parseSan(child.data.san);
      if (move == null) {
        warnings.add(
          'Zug „${child.data.san}" im Halbzug $ply ist nicht legal und wurde '
          'samt seiner Fortsetzungen übersprungen.',
        );
        continue;
      }

      final (next, san) = position.makeSan(move);
      final path = [...uciPath, move.uci];

      result.add(
        RepertoireNode(
          pathHash: RepertoireTree.hashFor(startFen, path),
          ply: ply,
          san: san,
          uci: move.uci,
          fenAfter: next.fen,
          comment: _joinComments(child.data),
          nags: child.data.nags ?? const [],
          children: _convertLevel(
            pgnChildren: child.children,
            position: next,
            startFen: startFen,
            uciPath: path,
            ply: ply + 1,
            warnings: warnings,
          ),
        ),
      );
    }

    return result;
  }

  /// PGN erlaubt mehrere Kommentare je Zug; in der App ist es ein Textfeld.
  static String? _joinComments(PgnNodeData data) {
    final parts = <String>[
      ...?data.startingComments,
      ...?data.comments,
    ].map((c) => c.trim()).where((c) => c.isNotEmpty).toList();

    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Schreibt den Baum als PGN. [headers] überschreiben die Standardköpfe.
  static String write(
    RepertoireTree tree, {
    Map<String, String> headers = const {},
  }) {
    final root = PgnNode<PgnNodeData>();

    void addLevel(List<RepertoireNode> nodes, PgnNode<PgnNodeData> target) {
      for (final node in nodes) {
        final pgnChild = PgnChildNode(
          PgnNodeData(
            san: node.san,
            comments: node.comment == null ? null : [node.comment!],
            nags: node.nags.isEmpty ? null : [...node.nags],
          ),
        );
        target.children.add(pgnChild);
        addLevel(node.children, pgnChild);
      }
    }

    addLevel(tree.children, root);

    final allHeaders = <String, String>{
      ...PgnGame.defaultHeaders(),
      if (tree.startFen != RepertoireTree.initialFen) ...{
        'SetUp': '1',
        'FEN': tree.startFen,
      },
      ...headers,
    };

    return PgnGame(
      headers: allHeaders,
      moves: root,
      comments: const [],
    ).makePgn();
  }
}
