import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/daos/lichess_dao.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:masteropening/features/lichess/data/lichess_repository.dart';
import 'package:masteropening/features/lichess/domain/lichess_account.dart';
import 'package:masteropening/features/lichess/domain/opening_stats.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:meta/meta.dart';

final Provider<LichessDao> lichessDaoProvider = Provider(
  (ref) => ref.watch(databaseProvider).lichessDao,
);

final lichessRepositoryProvider = Provider<LichessRepository>(
  (ref) => LichessRepository(db: ref.watch(databaseProvider)),
);

/// Alle importierten Partien, neueste zuerst.
final lichessGamesProvider = StreamProvider<List<LichessGame>>(
  (ref) => ref.watch(lichessDaoProvider).watchAll(),
);

/// Was der Lichess-Tab gerade tut.
enum LichessStatus { idle, connecting, importing }

/// Der Zustand der Anbindung, wie ihn der Bildschirm braucht.
@immutable
class LichessState {
  const LichessState({
    this.account,
    this.status = LichessStatus.idle,
    this.lastImport,
    this.error,
  });

  /// `null`, solange kein Konto verbunden ist.
  final LichessAccount? account;

  final LichessStatus status;

  /// Das Ergebnis des letzten Imports — für die Rückmeldung nach dem Tippen.
  final LichessImportResult? lastImport;

  /// Fehlermeldung des letzten Versuchs, falls einer schiefging.
  final String? error;

  bool get isConnected => account != null;
  bool get isBusy => status != LichessStatus.idle;

  LichessState copyWith({
    LichessAccount? account,
    LichessStatus? status,
    LichessImportResult? lastImport,
    String? error,
    bool clearAccount = false,
    bool clearError = false,
    bool clearImport = false,
  }) {
    return LichessState(
      account: clearAccount ? null : account ?? this.account,
      status: status ?? this.status,
      lastImport: clearImport ? null : lastImport ?? this.lastImport,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final lichessProvider = AsyncNotifierProvider<LichessController, LichessState>(
  LichessController.new,
);

/// Führt Anmeldung, Import und Trennen aus.
class LichessController extends AsyncNotifier<LichessState> {
  @override
  Future<LichessState> build() async {
    final repository = ref.watch(lichessRepositoryProvider);
    return LichessState(account: await repository.cachedAccount());
  }

  LichessRepository get _repository => ref.read(lichessRepositoryProvider);

  Future<void> connect() async {
    final current = state.value ?? const LichessState();
    state = AsyncData(
      current.copyWith(status: LichessStatus.connecting, clearError: true),
    );

    try {
      final account = await _repository.connect();
      state = AsyncData(
        LichessState(account: account),
      );
      // Direkt nach dem Verbinden lohnt sich der erste Import: ein leerer Tab
      // nach erfolgreicher Anmeldung wirkt wie ein Fehler.
      await importGames();
    } on Object catch (error) {
      state = AsyncData(
        current.copyWith(status: LichessStatus.idle, error: _messageFor(error)),
      );
    }
  }

  Future<void> importGames({int max = 300}) async {
    final current = state.value ?? const LichessState();
    if (!current.isConnected) return;

    state = AsyncData(
      current.copyWith(status: LichessStatus.importing, clearError: true),
    );

    try {
      final result = await _repository.importGames(max: max);
      state = AsyncData(
        current.copyWith(status: LichessStatus.idle, lastImport: result),
      );
    } on Object catch (error) {
      state = AsyncData(
        current.copyWith(status: LichessStatus.idle, error: _messageFor(error)),
      );
    }
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
    state = const AsyncData(LichessState());
  }

  /// Die Technik gehört ins Protokoll, nicht auf den Bildschirm — hier bleibt
  /// nur, was ein Mensch lesen kann.
  static String _messageFor(Object error) {
    final text = error.toString();
    return text.length > 160 ? '${text.substring(0, 157)}…' : text;
  }
}

/// Die Eröffnungsstatistik aus den eigenen Partien, abgeglichen mit den
/// vorhandenen Repertoires.
final openingStatsProvider = Provider<List<OpeningStat>>((ref) {
  final games = ref.watch(lichessGamesProvider).value ?? const <LichessGame>[];
  if (games.isEmpty) return const [];

  final repertoires =
      ref.watch(repertoiresProvider).value ?? const <Repertoire>[];

  // Ein Repertoire deckt eine Familie ab, wenn sein Name sie enthält oder
  // umgekehrt — Nutzer nennen ihr Repertoire „Sizilianisch Najdorf", Lichess
  // die Familie „Sicilian Defense".
  bool covered(String family, Side side) {
    final needle = family.toLowerCase();
    return repertoires.any((r) {
      if (r.side != side) return false;
      final name = r.name.toLowerCase();
      return name.contains(needle) || needle.contains(name);
    });
  }

  return [
    for (final stat in OpeningStats.from(games))
      stat.copyWith(inRepertoire: covered(stat.family, stat.side)),
  ];
});
