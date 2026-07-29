import 'package:masteropening/core/settings/app_settings.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/theme/board_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Liest und schreibt [AppSettings] als Einzelwerte in SharedPreferences.
///
/// Bewusst kein JSON-Blob: einzelne Schlüssel lassen sich später ergänzen oder
/// entfernen, ohne dass beim ersten Start nach einem Update alle Einstellungen
/// des Nutzers auf Standard zurückfallen, weil ein Feld nicht mehr passt.
abstract interface class SettingsStore {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _themeMode = 'settings.themeMode';
  static const _boardStyle = 'settings.boardStyle';
  static const _pieceSet = 'settings.pieceSet';
  static const _language = 'settings.language';
  static const _coordinates = 'settings.showCoordinates';
  static const _boardAnimations = 'settings.boardAnimations';
  static const _haptic = 'settings.hapticFeedback';
  static const _sound = 'settings.soundEnabled';
  static const _dailyLimit = 'settings.dailyReviewLimit';
  static const _autoPlay = 'settings.autoPlayOpponentMoves';
  static const _engineEval = 'settings.showEngineEval';
  static const _blitzSeconds = 'settings.blitzSecondsPerMove';
  static const _engineElo = 'settings.engineElo';
  static const _reminderOn = 'settings.dailyReminderEnabled';
  static const _reminderAt = 'settings.dailyReminderMinutes';
  static const _streakRisk = 'settings.streakRiskReminder';

  /// Sentinel für „der Nutzer folgt der Systemsprache". Ein leerer String lässt
  /// sich von „Schlüssel nie geschrieben" unterscheiden, `null` nicht.
  static const _systemLanguage = '';

  @override
  Future<AppSettings> load() async {
    const defaults = AppSettings();

    // Ein Rundtrip statt sechzehn: der Plattformkanal ist der teure Teil.
    final values = await _prefs.getAll(
      allowList: {
        _themeMode,
        _boardStyle,
        _pieceSet,
        _language,
        _coordinates,
        _boardAnimations,
        _haptic,
        _sound,
        _dailyLimit,
        _autoPlay,
        _engineEval,
        _blitzSeconds,
        _engineElo,
        _reminderOn,
        _reminderAt,
        _streakRisk,
      },
    );

    T read<T>(String key, T fallback) {
      final value = values[key];
      return value is T ? value : fallback;
    }

    final language = values[_language];

    return AppSettings(
      themeMode: AppThemeMode.fromStorage(values[_themeMode] as String?),
      boardStyle: BoardStyle.fromStorage(values[_boardStyle] as String?),
      pieceSet: read(_pieceSet, defaults.pieceSet),
      languageCode: language is String && language != _systemLanguage
          ? language
          : null,
      showCoordinates: read(_coordinates, defaults.showCoordinates),
      boardAnimations: read(_boardAnimations, defaults.boardAnimations),
      hapticFeedback: read(_haptic, defaults.hapticFeedback),
      soundEnabled: read(_sound, defaults.soundEnabled),
      dailyReviewLimit: read(_dailyLimit, defaults.dailyReviewLimit),
      autoPlayOpponentMoves: read(_autoPlay, defaults.autoPlayOpponentMoves),
      showEngineEval: read(_engineEval, defaults.showEngineEval),
      blitzSecondsPerMove: read(_blitzSeconds, defaults.blitzSecondsPerMove),
      engineElo: read(_engineElo, defaults.engineElo),
      dailyReminderEnabled: read(_reminderOn, defaults.dailyReminderEnabled),
      dailyReminderMinutes: read(_reminderAt, defaults.dailyReminderMinutes),
      streakRiskReminder: read(_streakRisk, defaults.streakRiskReminder),
    );
  }

  @override
  Future<void> save(AppSettings s) async {
    await Future.wait([
      _prefs.setString(_themeMode, s.themeMode.storageKey),
      _prefs.setString(_boardStyle, s.boardStyle.storageKey),
      _prefs.setString(_pieceSet, s.pieceSet),
      _prefs.setString(_language, s.languageCode ?? _systemLanguage),
      _prefs.setBool(_coordinates, s.showCoordinates),
      _prefs.setBool(_boardAnimations, s.boardAnimations),
      _prefs.setBool(_haptic, s.hapticFeedback),
      _prefs.setBool(_sound, s.soundEnabled),
      _prefs.setInt(_dailyLimit, s.dailyReviewLimit),
      _prefs.setBool(_autoPlay, s.autoPlayOpponentMoves),
      _prefs.setBool(_engineEval, s.showEngineEval),
      _prefs.setInt(_blitzSeconds, s.blitzSecondsPerMove),
      _prefs.setInt(_engineElo, s.engineElo),
      _prefs.setBool(_reminderOn, s.dailyReminderEnabled),
      _prefs.setInt(_reminderAt, s.dailyReminderMinutes),
      _prefs.setBool(_streakRisk, s.streakRiskReminder),
    ]);
  }
}

/// Hält die Einstellungen nur im Speicher — für Tests und Widget-Previews.
class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore([this._settings = const AppSettings()]);

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}
