import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/app.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/settings/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Die App ist Hochformat: jeder Bildschirm ist um ein quadratisches Brett
  // herum gebaut, das im Querformat den größten Teil der Fläche verschenkt.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Einstellungen vor dem ersten Frame laden, damit die App nicht sichtbar im
  // falschen Theme startet und dann umspringt.
  final store = SharedPreferencesSettingsStore();
  final settings = await store.load();

  runApp(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        initialSettingsProvider.overrideWithValue(settings),
      ],
      child: const MasterOpeningApp(),
    ),
  );
}
