import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/config/app_config.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:masteropening/features/sync/data/sync_api.dart';
import 'package:masteropening/features/sync/data/sync_repository.dart';
import 'package:meta/meta.dart';

final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => SyncRepository(db: ref.watch(databaseProvider)),
);

/// Was der Abgleich gerade tut.
@immutable
class SyncStatus {
  const SyncStatus({
    this.signedIn = false,
    this.running = false,
    this.lastOutcome,
    this.error,
  });

  final bool signedIn;
  final bool running;
  final SyncOutcome? lastOutcome;
  final String? error;

  /// Ohne Serveradresse gibt es nichts abzugleichen — dann bleibt die
  /// Oberfläche stumm statt einen Knopf anzubieten, der nur scheitern kann.
  bool get available => AppConfig.syncConfigured;

  SyncStatus copyWith({
    bool? signedIn,
    bool? running,
    SyncOutcome? lastOutcome,
    String? error,
    bool clearError = false,
  }) {
    return SyncStatus(
      signedIn: signedIn ?? this.signedIn,
      running: running ?? this.running,
      lastOutcome: lastOutcome ?? this.lastOutcome,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final syncProvider = AsyncNotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

class SyncController extends AsyncNotifier<SyncStatus> {
  @override
  Future<SyncStatus> build() async {
    if (!AppConfig.syncConfigured) return const SyncStatus();

    final repository = ref.watch(syncRepositoryProvider);
    return SyncStatus(signedIn: await repository.isSignedIn);
  }

  SyncRepository get _repository => ref.read(syncRepositoryProvider);

  /// Meldet sich mit dem Lichess-Token am eigenen Server an und gleicht
  /// gleich ab.
  Future<void> signIn(String lichessToken) async {
    final current = state.value ?? const SyncStatus();
    if (!current.available) return;

    state = AsyncData(current.copyWith(running: true, clearError: true));

    try {
      await _repository.signIn(lichessToken);
      state = AsyncData(
        current.copyWith(signedIn: true, running: false),
      );
      await syncNow();
    } on Object catch (error) {
      state = AsyncData(
        current.copyWith(running: false, error: _messageFor(error)),
      );
    }
  }

  Future<void> syncNow() async {
    final current = state.value ?? const SyncStatus();
    if (!current.available || !current.signedIn || current.running) return;

    state = AsyncData(current.copyWith(running: true, clearError: true));

    try {
      final outcome = await _repository.sync();
      state = AsyncData(
        current.copyWith(running: false, lastOutcome: outcome),
      );
    } on Object catch (error) {
      state = AsyncData(
        current.copyWith(running: false, error: _messageFor(error)),
      );
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(SyncStatus());
  }

  static String _messageFor(Object error) {
    if (error is SyncException) return error.message;
    final text = error.toString();
    return text.length > 160 ? '${text.substring(0, 157)}…' : text;
  }
}
