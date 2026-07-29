import 'package:dartchess/dartchess.dart' show Side;
import 'package:masteropening/features/library/domain/library_opening.dart';
import 'package:meta/meta.dart';

/// Wonach die Bibliothek gerade gefiltert wird.
///
/// Eigener unveränderlicher Typ statt einzelner Felder im Widget: die
/// Filterlogik ist damit ohne Oberfläche prüfbar, und der Zustand lässt sich
/// später ohne Umbau merken.
@immutable
class LibraryFilter {
  const LibraryFilter({
    this.query = '',
    this.side,
    this.tags = const {},
  });

  final String query;

  /// `null` heisst „beide Farben".
  final Side? side;

  /// Ein Eintrag muss *alle* gewählten Merkmale tragen — sonst liefert eine
  /// zweite Auswahl mehr Treffer statt weniger, was niemand erwartet.
  final Set<OpeningTag> tags;

  bool get isActive => query.isNotEmpty || side != null || tags.isNotEmpty;

  LibraryFilter copyWith({
    String? query,
    Side? side,
    bool clearSide = false,
    Set<OpeningTag>? tags,
  }) {
    return LibraryFilter(
      query: query ?? this.query,
      side: clearSide ? null : (side ?? this.side),
      tags: tags ?? this.tags,
    );
  }

  LibraryFilter toggleTag(OpeningTag tag) {
    return copyWith(
      tags: tags.contains(tag) ? ({...tags}..remove(tag)) : {...tags, tag},
    );
  }

  bool matches(LibraryOpeningSummary opening) {
    if (side != null && opening.side != side) return false;
    if (!tags.every(opening.tags.contains)) return false;
    return opening.matches(query);
  }

  List<LibraryOpeningSummary> apply(List<LibraryOpeningSummary> openings) =>
      openings.where(matches).toList();

  @override
  bool operator ==(Object other) =>
      other is LibraryFilter &&
      other.query == query &&
      other.side == side &&
      other.tags.length == tags.length &&
      other.tags.containsAll(tags);

  @override
  int get hashCode => Object.hash(query, side, Object.hashAllUnordered(tags));
}
