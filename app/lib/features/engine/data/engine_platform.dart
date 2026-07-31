import 'package:masteropening/features/engine/domain/engine_service.dart';

/// Die Engine dieser Plattform.
///
/// Aktuell liegt keine bei. Das Paket `stockfish` 1.8.1 ist das einzige mit
/// mitgelieferter Bibliothek für Flutter, und sein Android-Build stammt aus
/// der Zeit von AGP 3.5 und `jcenter()` — er lässt sich mit dem heutigen
/// Gradle nicht mehr übersetzen. Eine App, die sich nicht bauen lässt, ist
/// schlechter als eine ohne Engine.
///
/// Alles darüber steht bereits: [UciEngineService] spricht das Protokoll und
/// ist geprüft. Sobald ein baubares Paket vorliegt, ist hier ein
/// [UciTransport] einzusetzen, der dessen Ströme durchreicht — an der übrigen
/// App ändert sich dafür nichts, weil jede Stelle mit „keine Bewertung"
/// umgehen kann.
EngineService createEngineService() => const NoopEngineService();
