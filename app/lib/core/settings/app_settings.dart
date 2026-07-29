import 'package:equatable/equatable.dart';
import 'package:masteropening/core/theme/app_theme.dart';
import 'package:masteropening/core/theme/board_theme.dart';

/// Alle Einstellungen der App in einem unveränderlichen Objekt.
///
/// Bewusst ein einziger Typ statt vieler Einzelwerte: der Einstellungen-Tab,
/// die Persistenz und der Cloud-Sync arbeiten damit jeweils gegen genau eine
/// Struktur, und ein neuer Schalter braucht nur hier ein Feld.
class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.boardStyle = BoardStyle.nocturne,
    this.pieceSet = 'staunty',
    this.languageCode,
    this.showCoordinates = true,
    this.boardAnimations = true,
    this.hapticFeedback = true,
    this.soundEnabled = true,
    this.dailyReviewLimit = 30,
    this.autoPlayOpponentMoves = true,
    this.showEngineEval = false,
    this.blitzSecondsPerMove = 3,
    this.engineElo = 1600,
    this.dailyReminderEnabled = false,
    this.dailyReminderMinutes = 19 * 60 + 30,
    this.streakRiskReminder = true,
  });

  // ── Darstellung ───────────────────────────────────────────────────────────
  final AppThemeMode themeMode;
  final BoardStyle boardStyle;

  /// Name des Figurensatzes aus `chessground`. Als String gehalten, damit die
  /// Einstellungen nicht von einem UI-Paket abhängen.
  final String pieceSet;

  /// `null` bedeutet: der Systemsprache folgen.
  final String? languageCode;

  final bool showCoordinates;
  final bool boardAnimations;
  final bool hapticFeedback;
  final bool soundEnabled;

  // ── Training ──────────────────────────────────────────────────────────────

  /// Obergrenze fälliger Wiederholungen pro Tag (Spaced Repetition).
  final int dailyReviewLimit;

  /// Zieht die App die Antwort des Gegners im Training selbst nach?
  final bool autoPlayOpponentMoves;

  final bool showEngineEval;

  /// Bedenkzeit pro Zug im Blitz-Modus.
  final int blitzSecondsPerMove;

  /// Spielstärke für „gegen Engine weiterspielen" (UCI_Elo).
  final int engineElo;

  // ── Erinnerungen ──────────────────────────────────────────────────────────
  final bool dailyReminderEnabled;

  /// Minuten seit Mitternacht — zeitzonenfrei speicherbar.
  final int dailyReminderMinutes;

  /// Abends erinnern, wenn die Serie zu reißen droht.
  final bool streakRiskReminder;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    BoardStyle? boardStyle,
    String? pieceSet,
    String? languageCode,
    bool clearLanguage = false,
    bool? showCoordinates,
    bool? boardAnimations,
    bool? hapticFeedback,
    bool? soundEnabled,
    int? dailyReviewLimit,
    bool? autoPlayOpponentMoves,
    bool? showEngineEval,
    int? blitzSecondsPerMove,
    int? engineElo,
    bool? dailyReminderEnabled,
    int? dailyReminderMinutes,
    bool? streakRiskReminder,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      boardStyle: boardStyle ?? this.boardStyle,
      pieceSet: pieceSet ?? this.pieceSet,
      languageCode: clearLanguage ? null : (languageCode ?? this.languageCode),
      showCoordinates: showCoordinates ?? this.showCoordinates,
      boardAnimations: boardAnimations ?? this.boardAnimations,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      autoPlayOpponentMoves:
          autoPlayOpponentMoves ?? this.autoPlayOpponentMoves,
      showEngineEval: showEngineEval ?? this.showEngineEval,
      blitzSecondsPerMove: blitzSecondsPerMove ?? this.blitzSecondsPerMove,
      engineElo: engineElo ?? this.engineElo,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderMinutes: dailyReminderMinutes ?? this.dailyReminderMinutes,
      streakRiskReminder: streakRiskReminder ?? this.streakRiskReminder,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    boardStyle,
    pieceSet,
    languageCode,
    showCoordinates,
    boardAnimations,
    hapticFeedback,
    soundEnabled,
    dailyReviewLimit,
    autoPlayOpponentMoves,
    showEngineEval,
    blitzSecondsPerMove,
    engineElo,
    dailyReminderEnabled,
    dailyReminderMinutes,
    streakRiskReminder,
  ];
}
