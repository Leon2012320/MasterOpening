import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:dartchess/dartchess.dart';
import 'package:meta/meta.dart';

/// Ein Zug im Repertoire, samt der Stellung, die daraus entsteht.
///
/// Die Identität eines Knotens ist sein [pathHash] — der SHA-1 über
/// Startstellung und die UCI-Zugfolge bis hierher. Damit hängt der
/// Lernfortschritt an der Zugfolge und nicht an einer Datenbank-ID: Der Baum
/// darf umgebaut werden, ohne dass Statistiken ihre Zuordnung verlieren, und
/// zwei Geräte kommen beim Abgleich ohne Konfliktauflösung pro Knoten aus.
@immutable
class RepertoireNode {
  RepertoireNode({
    required this.pathHash,
    required this.ply,
    required this.san,
    required this.uci,
    required this.fenAfter,
    this.comment,
    List<int> nags = const [],
    List<RepertoireNode> children = const [],
  }) : nags = List.unmodifiable(nags),
       children = List.unmodifiable(children);

  final String pathHash;

  /// Halbzugnummer ab der Startstellung, beginnend bei 1.
  final int ply;

  /// Standard-Notation in Englisch — so, wie PGN sie speichert. Die Anzeige
  /// übersetzt daraus, siehe `san_notation.dart`.
  final String san;

  final String uci;

  /// Die Stellung *nach* diesem Zug.
  final String fenAfter;

  final String? comment;

  /// Numeric Annotation Glyphs (1 = `!`, 2 = `?`, 4 = `??` …).
  final List<int> nags;

  /// `children.first` ist die Hauptvariante an dieser Stelle.
  final List<RepertoireNode> children;

  bool get isLeaf => children.isEmpty;

  /// Wer diesen Zug ausgeführt hat.
  Side get movedBy => ply.isOdd ? Side.white : Side.black;

  /// Volle Zugnummer, wie sie in der Notation steht (1, 1, 2, 2, 3 …).
  int get moveNumber => (ply + 1) ~/ 2;

  RepertoireNode copyWith({
    String? comment,
    bool clearComment = false,
    List<int>? nags,
    List<RepertoireNode>? children,
  }) {
    return RepertoireNode(
      pathHash: pathHash,
      ply: ply,
      san: san,
      uci: uci,
      fenAfter: fenAfter,
      comment: clearComment ? null : (comment ?? this.comment),
      nags: nags ?? this.nags,
      children: children ?? this.children,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RepertoireNode &&
      other.pathHash == pathHash &&
      other.comment == comment &&
      const ListEquality<int>().equals(other.nags, nags) &&
      const ListEquality<RepertoireNode>().equals(other.children, children);

  @override
  int get hashCode => Object.hash(
    pathHash,
    comment,
    Object.hashAll(nags),
    Object.hashAll(children),
  );

  @override
  String toString() => 'RepertoireNode($ply. $san)';
}

/// Eine durchgehende Zugfolge von der Startstellung bis zu einem Blatt.
@immutable
class RepertoireLine {
  RepertoireLine(List<RepertoireNode> nodes) : nodes = List.unmodifiable(nodes);

  final List<RepertoireNode> nodes;

  RepertoireNode get last => nodes.last;
  int get length => nodes.length;

  /// Der Knoten am Ende identifiziert die Variante eindeutig.
  String get id => nodes.last.pathHash;

  /// Nur die Züge der Seite, die das Repertoire spielt — die Züge des Gegners
  /// werden vorgegeben und zählen nicht zur Trefferquote.
  List<RepertoireNode> ownMoves(Side side) =>
      nodes.where((n) => n.movedBy == side).toList();

  String get sanLine {
    final buffer = StringBuffer();
    for (final node in nodes) {
      if (node.movedBy == Side.white) {
        buffer.write('${node.moveNumber}. ');
      } else if (node == nodes.first) {
        buffer.write('${node.moveNumber}... ');
      }
      buffer
        ..write(node.san)
        ..write(' ');
    }
    return buffer.toString().trimRight();
  }
}

/// Der vollständige Variantenbaum eines Repertoires.
///
/// Unveränderlich: jede Bearbeitung liefert einen neuen Baum. Bei den
/// Größenordnungen eines Eröffnungsrepertoires (einige hundert bis wenige
/// tausend Knoten) ist das Kopieren des Rückgrats vernachlässigbar und spart
/// die gesamte Fehlerklasse „jemand hat den Baum unter uns verändert".
@immutable
class RepertoireTree {
  RepertoireTree({
    required this.startFen,
    List<RepertoireNode> children = const [],
  }) : children = List.unmodifiable(children);

  const RepertoireTree.empty({String? startFen})
    : startFen = startFen ?? initialFen,
      children = const [];

  /// FEN der Grundstellung. Als Konstante statt `Chess.initial.fen`, damit der
  /// Wert in `const`-Kontexten und in Hashes verlässlich derselbe ist.
  static const initialFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  final String startFen;
  final List<RepertoireNode> children;

  bool get isEmpty => children.isEmpty;
  bool get isNotEmpty => children.isNotEmpty;

  /// Die Startstellung als spielbare Position.
  Position get startPosition => startFen == initialFen
      ? Chess.initial
      : Chess.fromSetup(Setup.parseFen(startFen));

  /// Der Hash eines Knotens, erreicht über [uciPath].
  ///
  /// Die Startstellung geht mit ein, damit derselbe Zugweg aus verschiedenen
  /// Grundstellungen nicht denselben Fortschritt erbt.
  static String hashFor(String startFen, List<String> uciPath) {
    final input = utf8.encode('$startFen|${uciPath.join(' ')}');
    return sha1.convert(input).toString();
  }

  /// Alle Knoten in Tiefensuche, Hauptvariante zuerst.
  Iterable<RepertoireNode> walk() sync* {
    final stack = <RepertoireNode>[...children.reversed];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      yield node;
      stack.addAll(node.children.reversed);
    }
  }

  int get nodeCount => walk().length;

  int get maxDepth =>
      walk().fold(0, (best, node) => node.ply > best ? node.ply : best);

  /// Alle Stellungen, die im Repertoire vorkommen — Grundlage für den
  /// Abgleich mit echten Partien.
  Set<String> get positionFens => {
    startFen,
    for (final node in walk()) node.fenAfter,
  };

  RepertoireNode? findByHash(String pathHash) =>
      walk().firstWhereOrNull((n) => n.pathHash == pathHash);

  /// Der Pfad von der Wurzel bis zum Knoten mit [pathHash], oder `null`.
  List<RepertoireNode>? pathTo(String pathHash) {
    List<RepertoireNode>? search(
      List<RepertoireNode> nodes,
      List<RepertoireNode> prefix,
    ) {
      for (final node in nodes) {
        final path = [...prefix, node];
        if (node.pathHash == pathHash) return path;
        final found = search(node.children, path);
        if (found != null) return found;
      }
      return null;
    }

    return search(children, const []);
  }

  /// Folgt einer UCI-Zugfolge, soweit sie im Baum vorhanden ist.
  RepertoireNode? nodeAtUciPath(List<String> uciPath) {
    if (uciPath.isEmpty) return null;
    var level = children;
    RepertoireNode? current;
    for (final uci in uciPath) {
      current = level.firstWhereOrNull((n) => n.uci == uci);
      if (current == null) return null;
      level = current.children;
    }
    return current;
  }

  /// Alle Varianten von der Wurzel bis zu jedem Blatt.
  List<RepertoireLine> lines() {
    final result = <RepertoireLine>[];

    void descend(RepertoireNode node, List<RepertoireNode> prefix) {
      final path = [...prefix, node];
      if (node.isLeaf) {
        result.add(RepertoireLine(path));
      } else {
        for (final child in node.children) {
          descend(child, path);
        }
      }
    }

    for (final child in children) {
      descend(child, const []);
    }
    return result;
  }

  // ── Bearbeitung ───────────────────────────────────────────────────────────

  /// Ergänzt eine Zugfolge in SAN. Bereits vorhandene Züge werden
  /// wiederverwendet, nur der neue Teil kommt hinzu.
  ///
  /// Wirft [InvalidMoveException], wenn ein Zug in seiner Stellung nicht legal
  /// ist.
  RepertoireTree withSanLine(List<String> sanMoves, {String? leafComment}) {
    var position = startPosition;
    final uciPath = <String>[];
    var level = children;
    final spine = <RepertoireNode>[];

    // Vorhandenes Präfix abgehen.
    var index = 0;
    for (; index < sanMoves.length; index++) {
      final move = position.parseSan(sanMoves[index]);
      if (move == null) {
        throw InvalidMoveException(sanMoves[index], position.fen, index + 1);
      }
      final uci = move.uci;
      final existing = level.firstWhereOrNull((n) => n.uci == uci);
      if (existing == null) break;
      position = position.play(move);
      uciPath.add(uci);
      spine.add(existing);
      level = existing.children;
    }

    if (index == sanMoves.length) {
      // Die Linie steht schon vollständig im Baum; höchstens der Kommentar
      // am Blatt ist neu.
      if (leafComment == null || spine.isEmpty) return this;
      return withComment(spine.last.pathHash, leafComment);
    }

    // Rest als neue Kette bauen — von hinten nach vorn, damit Kinder fertig
    // sind, bevor der Elternknoten entsteht.
    final tailPositions = <String>[];
    final tailSan = <String>[];
    final tailUci = <String>[];
    var tailPosition = position;
    final tailPath = [...uciPath];

    for (var i = index; i < sanMoves.length; i++) {
      final move = tailPosition.parseSan(sanMoves[i]);
      if (move == null) {
        throw InvalidMoveException(sanMoves[i], tailPosition.fen, i + 1);
      }
      final (next, san) = tailPosition.makeSan(move);
      tailPosition = next;
      tailSan.add(san);
      tailUci.add(move.uci);
      tailPath.add(move.uci);
      tailPositions.add(next.fen);
    }

    RepertoireNode? built;
    for (var i = sanMoves.length - 1; i >= index; i--) {
      final offset = i - index;
      final pathSoFar = tailPath.sublist(0, uciPath.length + offset + 1);
      built = RepertoireNode(
        pathHash: hashFor(startFen, pathSoFar),
        ply: i + 1,
        san: tailSan[offset],
        uci: tailUci[offset],
        fenAfter: tailPositions[offset],
        comment: i == sanMoves.length - 1 ? leafComment : null,
        children: built == null ? const [] : [built],
      );
    }

    return _insert(spine, built!);
  }

  /// Hängt [newChild] unter den durch [spine] beschriebenen Knoten und baut
  /// den Pfad zur Wurzel neu auf.
  RepertoireTree _insert(List<RepertoireNode> spine, RepertoireNode newChild) {
    var child = newChild;
    for (var i = spine.length - 1; i >= 0; i--) {
      final parent = spine[i];
      child = parent.copyWith(
        children: _replaceOrAppend(parent.children, child),
      );
    }
    return RepertoireTree(
      startFen: startFen,
      children: _replaceOrAppend(children, child),
    );
  }

  /// Setzt [node] an die Stelle des Geschwisters mit gleichem Hash, oder
  /// hängt ihn hinten an.
  ///
  /// Beim Neuaufbau des Rückgrats trägt jeder Elternknoten sein Kind noch in
  /// der alten Fassung; würde man nur anhängen, stünde derselbe Zug zweimal
  /// auf einer Ebene und der Teilbaum darunter wäre gedoppelt.
  static List<RepertoireNode> _replaceOrAppend(
    List<RepertoireNode> siblings,
    RepertoireNode node,
  ) {
    final index = siblings.indexWhere((s) => s.pathHash == node.pathHash);
    if (index < 0) return [...siblings, node];
    return [
      for (var i = 0; i < siblings.length; i++)
        if (i == index) node else siblings[i],
    ];
  }

  /// Entfernt einen Knoten samt allem, was darunter hängt.
  RepertoireTree withoutNode(String pathHash) {
    List<RepertoireNode> prune(List<RepertoireNode> nodes) => [
      for (final node in nodes)
        if (node.pathHash != pathHash)
          node.copyWith(children: prune(node.children)),
    ];

    return RepertoireTree(startFen: startFen, children: prune(children));
  }

  /// Macht den Knoten zur Hauptvariante seiner Ebene, indem er nach vorn
  /// rückt. Sein gesamter Pfad rückt mit, sonst bliebe die Hauptlinie über
  /// ihm eine Nebenvariante.
  RepertoireTree withMainline(String pathHash) {
    final path = pathTo(pathHash);
    if (path == null) return this;

    final hashesOnPath = path.map((n) => n.pathHash).toSet();

    List<RepertoireNode> promote(List<RepertoireNode> nodes) {
      final index = nodes.indexWhere((n) => hashesOnPath.contains(n.pathHash));
      if (index < 0) return nodes;
      final chosen = nodes[index].copyWith(
        children: promote(nodes[index].children),
      );
      return [
        chosen,
        for (var i = 0; i < nodes.length; i++)
          if (i != index) nodes[i],
      ];
    }

    return RepertoireTree(startFen: startFen, children: promote(children));
  }

  RepertoireTree withComment(String pathHash, String? comment) =>
      _updateNode(pathHash, (node) {
        final trimmed = comment?.trim();
        return node.copyWith(
          comment: trimmed,
          clearComment: trimmed == null || trimmed.isEmpty,
        );
      });

  RepertoireTree withNags(String pathHash, List<int> nags) =>
      _updateNode(pathHash, (node) => node.copyWith(nags: nags));

  RepertoireTree _updateNode(
    String pathHash,
    RepertoireNode Function(RepertoireNode) update,
  ) {
    List<RepertoireNode> apply(List<RepertoireNode> nodes) => [
      for (final node in nodes)
        if (node.pathHash == pathHash)
          update(node)
        else
          node.copyWith(children: apply(node.children)),
    ];

    return RepertoireTree(startFen: startFen, children: apply(children));
  }

  /// Verschmilzt einen zweiten Baum hinein — für „Variante aus der Bibliothek
  /// zum bestehenden Repertoire hinzufügen".
  RepertoireTree merge(RepertoireTree other) {
    if (other.startFen != startFen) {
      throw ArgumentError(
        'Baeume mit verschiedenen Startstellungen lassen sich nicht '
        'zusammenfuehren: $startFen vs. ${other.startFen}',
      );
    }

    List<RepertoireNode> mergeLevel(
      List<RepertoireNode> mine,
      List<RepertoireNode> theirs,
    ) {
      final result = [...mine];
      for (final incoming in theirs) {
        final index = result.indexWhere((n) => n.uci == incoming.uci);
        if (index < 0) {
          result.add(incoming);
        } else {
          final existing = result[index];
          result[index] = existing.copyWith(
            // Ein vorhandener Kommentar gewinnt: er stammt vom Nutzer, der
            // eingehende aus der Bibliothek.
            comment: existing.comment ?? incoming.comment,
            nags: existing.nags.isEmpty ? incoming.nags : existing.nags,
            children: mergeLevel(existing.children, incoming.children),
          );
        }
      }
      return result;
    }

    return RepertoireTree(
      startFen: startFen,
      children: mergeLevel(children, other.children),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RepertoireTree &&
      other.startFen == startFen &&
      const ListEquality<RepertoireNode>().equals(other.children, children);

  @override
  int get hashCode => Object.hash(startFen, Object.hashAll(children));
}

/// Ein Zug aus einer PGN-Datei ist in seiner Stellung nicht spielbar.
class InvalidMoveException implements Exception {
  const InvalidMoveException(this.san, this.fen, this.ply);

  final String san;
  final String fen;
  final int ply;

  @override
  String toString() => 'Zug „$san" ist im Halbzug $ply nicht legal ($fen)';
}
