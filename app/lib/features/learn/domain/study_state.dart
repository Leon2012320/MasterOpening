import 'package:collection/collection.dart';
import 'package:dartchess/dartchess.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:meta/meta.dart';

/// Wo man sich beim Durchsehen eines Repertoires gerade befindet.
///
/// Unveränderlich: jede Navigation liefert einen neuen Zustand. Der Bildschirm
/// hält davon genau einen und tauscht ihn aus — dadurch ist die gesamte
/// Navigationslogik ohne Widgets prüfbar.
@immutable
class StudyState {
  const StudyState._({
    required this.tree,
    required this.path,
    required this.orientation,
  });

  /// Beginnt an der Grundstellung.
  factory StudyState.atStart(
    RepertoireTree tree, {
    Side orientation = Side.white,
  }) {
    return StudyState._(tree: tree, path: const [], orientation: orientation);
  }

  final RepertoireTree tree;

  /// Der Weg von der Wurzel bis zum aktuellen Zug. Leer heisst Grundstellung.
  final List<RepertoireNode> path;

  final Side orientation;

  // ── Ableitungen ───────────────────────────────────────────────────────────

  RepertoireNode? get current => path.lastOrNull;

  bool get isAtStart => path.isEmpty;

  /// Der Halbzug, auf dem man steht — 0 an der Grundstellung.
  int get ply => path.length;

  String get fen => current?.fenAfter ?? tree.startFen;

  Position get position => current == null
      ? tree.startPosition
      : Chess.fromSetup(Setup.parseFen(current!.fenAfter));

  Move? get lastMove => current == null ? null : Move.parse(current!.uci);

  /// Die Fortsetzungen an dieser Stelle. Die erste ist die Hauptvariante.
  List<RepertoireNode> get continuations => current?.children ?? tree.children;

  bool get canGoForward => continuations.isNotEmpty;
  bool get canGoBack => path.isNotEmpty;

  /// Ob hier mehrere Wege weitergehen — dann zeigt die Oberfläche eine
  /// Auswahl statt einfach der Hauptvariante zu folgen.
  bool get isBranchPoint => continuations.length > 1;

  /// Der Kommentar zum aktuellen Zug.
  String? get comment => current?.comment;

  /// Die Zugfolge bis hierher, für Anzeige und Weitergabe ans Training.
  List<String> get sanPath => [for (final node in path) node.san];

  List<String> get uciPath => [for (final node in path) node.uci];

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Einen Halbzug vor, entlang der Hauptvariante.
  StudyState forward() {
    final next = continuations.firstOrNull;
    if (next == null) return this;
    return _withPath([...path, next]);
  }

  /// Einen bestimmten Zug spielen — für Verzweigungen und für Züge, die
  /// direkt auf dem Brett ausgeführt werden.
  StudyState playNode(RepertoireNode node) {
    if (!continuations.any((c) => c.pathHash == node.pathHash)) return this;
    return _withPath([...path, node]);
  }

  /// Den Zug spielen, der zu [move] passt — `null`, wenn er im Repertoire
  /// nicht vorgesehen ist.
  StudyState? playMove(Move move) {
    final node = continuations.firstWhereOrNull((c) => c.uci == move.uci);
    return node == null ? null : _withPath([...path, node]);
  }

  StudyState back() {
    if (path.isEmpty) return this;
    return _withPath(path.sublist(0, path.length - 1));
  }

  StudyState toStart() => _withPath(const []);

  /// Bis ans Ende der aktuellen Variante, immer der Hauptlinie folgend.
  StudyState toEnd() {
    final next = [...path];
    var options = continuations;
    while (options.isNotEmpty) {
      next.add(options.first);
      options = next.last.children;
      // Sicherung gegen einen fehlerhaften Baum mit Zyklus.
      if (next.length > 512) break;
    }
    return _withPath(next);
  }

  /// Springt zu einem beliebigen Knoten des Baums.
  StudyState goTo(String pathHash) {
    final found = tree.pathTo(pathHash);
    if (found == null) return this;
    return _withPath(found);
  }

  /// Wechselt an der letzten Verzweigung auf die nächste Geschwistervariante
  /// — so kommt man ohne Zurückgehen durch die Alternativen.
  StudyState nextSibling() {
    if (path.isEmpty) return this;
    final parentPath = path.sublist(0, path.length - 1);
    final siblings = parentPath.isEmpty
        ? tree.children
        : parentPath.last.children;
    if (siblings.length < 2) return this;

    final index = siblings.indexWhere((s) => s.pathHash == path.last.pathHash);
    final next = siblings[(index + 1) % siblings.length];
    return _withPath([...parentPath, next]);
  }

  StudyState flipped() => StudyState._(
    tree: tree,
    path: path,
    orientation: orientation.opposite,
  );

  /// Nach einer Bearbeitung: denselben Weg im neuen Baum wiederfinden.
  ///
  /// Fehlt der Knoten inzwischen, geht es so weit zurück, wie der Weg noch
  /// existiert — der Bildschirm springt dann nicht an den Anfang.
  StudyState withTree(RepertoireTree updated) {
    var kept = <RepertoireNode>[];
    var level = updated.children;
    for (final node in path) {
      final match = level.firstWhereOrNull((c) => c.pathHash == node.pathHash);
      if (match == null) break;
      kept = [...kept, match];
      level = match.children;
    }
    return StudyState._(tree: updated, path: kept, orientation: orientation);
  }

  StudyState _withPath(List<RepertoireNode> next) =>
      StudyState._(tree: tree, path: next, orientation: orientation);

  @override
  bool operator ==(Object other) =>
      other is StudyState &&
      other.orientation == orientation &&
      other.tree == tree &&
      const ListEquality<RepertoireNode>().equals(other.path, path);

  @override
  int get hashCode => Object.hash(tree, Object.hashAll(path), orientation);
}
