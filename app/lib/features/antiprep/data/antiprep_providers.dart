import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:masteropening/features/antiprep/data/antiprep_repository.dart';
import 'package:masteropening/features/antiprep/domain/scout_report.dart';
import 'package:masteropening/features/lichess/domain/lichess_oauth.dart';
import 'package:meta/meta.dart';

final antiPrepRepositoryProvider = Provider<AntiPrepRepository>(
  (ref) => AntiPrepRepository(db: ref.watch(databaseProvider)),
);

/// Zustand des Anti-Vorbereitungs-Bildschirms.
@immutable
class AntiPrepState {
  const AntiPrepState({
    this.username = '',
    this.report,
    this.running = false,
    this.error,
  });

  final String username;
  final ScoutReport? report;
  final bool running;
  final String? error;

  AntiPrepState copyWith({
    String? username,
    ScoutReport? report,
    bool? running,
    String? error,
    bool clearReport = false,
    bool clearError = false,
  }) {
    return AntiPrepState(
      username: username ?? this.username,
      report: clearReport ? null : report ?? this.report,
      running: running ?? this.running,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final antiPrepProvider = NotifierProvider<AntiPrepController, AntiPrepState>(
  AntiPrepController.new,
);

class AntiPrepController extends Notifier<AntiPrepState> {
  @override
  AntiPrepState build() => const AntiPrepState();

  AntiPrepRepository get _repository => ref.read(antiPrepRepositoryProvider);

  void setUsername(String value) {
    state = state.copyWith(username: value, clearError: true);
  }

  /// Sucht den Gegner. Ein bekannter Bericht erscheint sofort; geholt wird
  /// erst, wenn der Nutzer es ausdrücklich verlangt.
  Future<void> load({bool refresh = false}) async {
    final name = state.username.trim();
    if (name.isEmpty || state.running) return;

    state = state.copyWith(running: true, clearError: true);

    try {
      final report = refresh
          ? await _repository.scout(name)
          : await _repository.cached(name) ?? await _repository.scout(name);

      state = state.copyWith(running: false, report: report);
    } on Object catch (error) {
      state = state.copyWith(
        running: false,
        error: _messageFor(error),
        clearReport: true,
      );
    }
  }

  static String _messageFor(Object error) {
    if (error is LichessAuthException) return error.message;
    final text = error.toString();
    return text.length > 160 ? '${text.substring(0, 157)}…' : text;
  }
}
