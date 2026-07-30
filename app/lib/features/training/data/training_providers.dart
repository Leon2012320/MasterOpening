import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/features/training/data/training_repository.dart';
import 'package:masteropening/features/training/domain/training_plan.dart';
import 'package:meta/meta.dart';

final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => TrainingRepository(ref.watch(databaseProvider)),
);

/// Womit eine Einheit gestartet wird.
@immutable
class TrainingRequest {
  const TrainingRequest({required this.mode, this.repertoireId});

  final TrainingMode mode;

  /// `null` heisst: über alle Repertoires hinweg.
  final int? repertoireId;

  @override
  bool operator ==(Object other) =>
      other is TrainingRequest &&
      other.mode == mode &&
      other.repertoireId == repertoireId;

  @override
  int get hashCode => Object.hash(mode, repertoireId);
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
      final sources = await ref
          .watch(trainingRepositoryProvider)
          .loadSources(
            repertoires: ref.watch(repertoireRepositoryProvider),
            repertoireId: request.repertoireId,
          );

      return TrainingPlanner.build(
        sources: sources,
        options: PlannerOptions(
          mode: request.mode,
          maxLines: _linesFor(ref.watch(settingsProvider).dailyReviewLimit),
        ),
      );
    });

/// Aus dem Tageslimit an Wiederholungen wird die Zahl der Varianten je
/// Einheit: eine Variante bringt im Mittel rund drei eigene Züge.
int _linesFor(int dailyReviewLimit) => (dailyReviewLimit / 3).round().clamp(
  3,
  25,
);
