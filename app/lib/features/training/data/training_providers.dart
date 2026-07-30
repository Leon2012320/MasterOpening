import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/features/training/data/training_repository.dart';
import 'package:masteropening/features/training/data/trap_repository.dart';
import 'package:masteropening/features/training/domain/training_plan.dart';
import 'package:meta/meta.dart';

final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => TrainingRepository(ref.watch(databaseProvider)),
);

/// Womit eine Einheit gestartet wird.
@immutable
class TrainingRequest {
  const TrainingRequest({
    required this.mode,
    this.repertoireId,
    this.pathHash,
  });

  final TrainingMode mode;

  /// `null` heisst: über alle Repertoires hinweg.
  final int? repertoireId;

  /// Nur im Modus „bestimmte Variante": welcher Zug gemeint ist.
  final String? pathHash;

  @override
  bool operator ==(Object other) =>
      other is TrainingRequest &&
      other.mode == mode &&
      other.repertoireId == repertoireId &&
      other.pathHash == pathHash;

  @override
  int get hashCode => Object.hash(mode, repertoireId, pathHash);
}

/// Stellt den Plan für eine Einheit zusammen.
///
/// Der Rückgabetyp von `FutureProvider.family` ist bei Riverpod nicht
/// öffentlich; die Typargumente stehen deshalb nur am Aufruf.
// ignore: specify_nonobvious_property_types
final trainingPlanProvider =
    FutureProvider.family<List<TrainingLine>, TrainingRequest>((
      ref,
      request,
    ) async {
      final settings = ref.watch(settingsProvider);
      final maxLines = _linesFor(settings.dailyReviewLimit);

      final sources = await ref
          .watch(trainingRepositoryProvider)
          .loadSources(
            repertoires: ref.watch(repertoireRepositoryProvider),
            repertoireId: request.repertoireId,
          );

      // Der Fallen-Modus schöpft nicht aus dem Repertoire, sondern aus den
      // mitgelieferten Fallen — passend zu den Farben, die man spielt.
      if (request.mode == TrainingMode.trap) {
        return ref
            .watch(trapRepositoryProvider)
            .asTrainingLines(
              sides: sources.map((s) => s.side).toSet(),
              languageCode: settings.languageCode ?? 'de',
              maxLines: maxLines,
            );
      }

      // Eine einzelne Variante gezielt üben.
      final pathHash = request.pathHash;
      if (request.mode == TrainingMode.variation && pathHash != null) {
        if (sources.isEmpty) return const [];
        return TrainingPlanner.single(
          source: sources.first,
          pathHash: pathHash,
        );
      }

      return TrainingPlanner.build(
        sources: sources,
        options: PlannerOptions(mode: request.mode, maxLines: maxLines),
      );
    });

/// Aus dem Tageslimit an Wiederholungen wird die Zahl der Varianten je
/// Einheit: eine Variante bringt im Mittel rund drei eigene Züge.
int _linesFor(int dailyReviewLimit) => (dailyReviewLimit / 3).round().clamp(
  3,
  25,
);
