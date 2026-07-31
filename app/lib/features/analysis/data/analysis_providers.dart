import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:masteropening/features/analysis/data/analysis_repository.dart';
import 'package:masteropening/features/analysis/domain/gap.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:meta/meta.dart';

final analysisRepositoryProvider = Provider<AnalysisRepository>(
  (ref) => AnalysisRepository(
    ref.watch(databaseProvider),
    ref.watch(repertoireRepositoryProvider),
  ),
);

/// Die offenen Lücken, dringendste zuerst.
final gapsProvider = StreamProvider<List<RepertoireGap>>(
  (ref) => ref.watch(analysisRepositoryProvider).watchOpenGaps(),
);

/// Die Züge, die im Training am häufigsten danebengehen.
final mistakesProvider = FutureProvider<List<MoveMistake>>(
  (ref) => ref.watch(analysisRepositoryProvider).mistakes(),
);

/// Zustand des Reparatur-Bildschirms.
@immutable
class AnalysisState {
  const AnalysisState({this.running = false, this.summary, this.error});

  final bool running;
  final AnalysisSummary? summary;
  final String? error;

  AnalysisState copyWith({
    bool? running,
    AnalysisSummary? summary,
    String? error,
    bool clearError = false,
  }) {
    return AnalysisState(
      running: running ?? this.running,
      summary: summary ?? this.summary,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final analysisProvider = NotifierProvider<AnalysisController, AnalysisState>(
  AnalysisController.new,
);

class AnalysisController extends Notifier<AnalysisState> {
  @override
  AnalysisState build() => const AnalysisState();

  /// Wertet die Partien aus.
  ///
  /// [force] prüft auch schon geprüfte erneut — nötig, wenn sich das
  /// Repertoire geändert hat, denn dann stimmen die alten Marken nicht mehr.
  Future<void> run({bool force = false}) async {
    if (state.running) return;
    state = state.copyWith(running: true, clearError: true);

    try {
      final summary = await ref
          .read(analysisRepositoryProvider)
          .analyse(force: force);
      state = state.copyWith(running: false, summary: summary);
      ref.invalidate(mistakesProvider);
    } on Object catch (error) {
      state = state.copyWith(running: false, error: error.toString());
    }
  }

  Future<void> dismiss(int gapId) =>
      ref.read(analysisRepositoryProvider).dismissGap(gapId);

  /// Trägt den fehlenden Zug ins Repertoire ein und liefert seinen `pathHash`.
  Future<String?> addToRepertoire(RepertoireGap gap) async {
    final hash = await ref
        .read(analysisRepositoryProvider)
        .addGapToRepertoire(gap);
    ref.invalidate(mistakesProvider);
    return hash;
  }
}
