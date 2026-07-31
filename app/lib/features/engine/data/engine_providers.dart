import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/features/engine/data/stockfish_transport.dart';
import 'package:masteropening/features/engine/domain/engine_service.dart';
import 'package:masteropening/features/engine/domain/uci.dart';

/// Die Engine der App.
///
/// Wird erst beim ersten Zugriff gestartet und beim Verwerfen des Providers
/// wieder beendet — eine Engine im Hintergrund kostet Speicher und Akku.
final engineServiceProvider = Provider<EngineService>((ref) {
  final engine = createEngineService();
  ref.onDispose(engine.dispose);
  return engine;
});

/// Ob die Oberfläche überhaupt eine Bewertung anbieten darf.
final engineAvailableProvider = Provider<bool>(
  (ref) => ref.watch(engineServiceProvider).isAvailable,
);

/// Die eingestellte Spielstärke, auf den Bereich der Engine begrenzt.
final engineEloProvider = Provider<int>((ref) {
  final elo = ref.watch(settingsProvider.select((s) => s.engineElo));
  return elo.clamp(Uci.minElo, Uci.maxElo);
});
