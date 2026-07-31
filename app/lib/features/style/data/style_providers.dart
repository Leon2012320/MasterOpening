import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/features/library/data/library_repository.dart';
import 'package:masteropening/features/library/domain/library_opening.dart';
import 'package:masteropening/features/lichess/data/lichess_providers.dart';
import 'package:masteropening/features/lichess/domain/opening_stats.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/features/style/domain/style_profile.dart';

/// Ordnet den gespielten Eröffnungen die Merkmale der Bibliothek zu.
///
/// Der Abgleich läuft über den Familiennamen: Lichess nennt die Eröffnung
/// „Sicilian Defense: Najdorf", die Bibliothek „Sizilianisch" — beides trifft
/// sich in der Familie, nicht in der Variante.
final styleProfileProvider = Provider<StyleProfile>((ref) {
  final games = ref.watch(lichessGamesProvider).value ?? const [];
  if (games.isEmpty) return const StyleProfile(scores: {}, gamesAnalysed: 0);

  final library = ref.watch(libraryIndexProvider).value ?? const [];
  if (library.isEmpty) return const StyleProfile(scores: {}, gamesAnalysed: 0);

  final byFamily = <String, List<OpeningTag>>{};
  for (final opening in library) {
    for (final name in [opening.nameDe, opening.nameEn]) {
      byFamily[name.toLowerCase()] = opening.tags;
    }
  }

  List<OpeningTag> tagsFor(String? openingName) {
    final family = OpeningStats.familyOf(openingName).toLowerCase();
    if (family.isEmpty) return const [];

    for (final entry in byFamily.entries) {
      if (family.contains(entry.key) || entry.key.contains(family)) {
        return entry.value;
      }
    }
    return const [];
  }

  final scored = [
    for (final game in games)
      if (tagsFor(game.openingName) case final tags when tags.isNotEmpty)
        (tags: tags, outcome: game.outcome),
  ];

  return StyleAnalyser.analyse(games: scored);
});

/// Die Eröffnungen, die zum Stilbild passen und noch fehlen.
final styleSuggestionsProvider =
    Provider<List<({LibraryOpeningSummary opening, double match})>>((ref) {
      final profile = ref.watch(styleProfileProvider);
      if (profile.isEmpty) return const [];

      final library = ref.watch(libraryIndexProvider).value ?? const [];
      final repertoires = ref.watch(repertoiresProvider).value ?? const [];

      return StyleAnalyser.suggest(
        profile: profile,
        library: library,
        // Ein Repertoire aus der Bibliothek trägt deren Kennung als Quelle —
        // daran erkennt der Vorschlag, was schon dasteht.
        alreadyInRepertoire: {
          for (final row in repertoires) ?row.sourceRef,
        },
      );
    });
