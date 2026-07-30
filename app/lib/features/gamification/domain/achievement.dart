import 'package:meta/meta.dart';

/// Wonach ein Erfolg bemessen wird.
///
/// Jede Kennzahl ist ein Zählerstand, der nur wachsen kann — dadurch bleibt
/// ein einmal freigeschalteter Erfolg freigeschaltet, auch wenn die Serie
/// später reisst.
enum AchievementMetric {
  /// Insgesamt geübte Züge.
  movesTrained,

  /// Abgeschlossene Trainingseinheiten.
  sessions,

  /// Längste Serie in Tagen.
  bestStreak,

  /// Fehlerfrei gespielte Varianten.
  linesMastered,

  /// Angelegte Repertoires.
  repertoires,

  /// Einheiten ohne einen einzigen Fehler.
  perfectSessions,

  /// Gesamte Lernzeit in Minuten.
  studyMinutes,

  /// Erreichtes Level.
  level,

  /// Widerlegte Eröffnungsfallen.
  trapsRefuted,

  /// Von Lichess importierte Partien.
  lichessGames,
}

/// Die Gruppen, in denen Erfolge auf dem Bildschirm stehen.
enum AchievementCategory {
  volume,
  accuracy,
  streak,
  repertoire,
  modes,
  lichess,
}

/// Ein Erfolg.
@immutable
class Achievement {
  const Achievement({
    required this.id,
    required this.category,
    required this.metric,
    required this.threshold,
    required this.nameDe,
    required this.nameEn,
    required this.hintDe,
    required this.hintEn,
    this.xpReward = 100,
  });

  final String id;
  final AchievementCategory category;
  final AchievementMetric metric;

  /// Ab diesem Wert ist der Erfolg freigeschaltet.
  final int threshold;

  final String nameDe;
  final String nameEn;

  /// Was zu tun ist — steht solange dort, bis der Erfolg offen ist.
  final String hintDe;
  final String hintEn;

  final int xpReward;

  String name(String languageCode) => languageCode == 'de' ? nameDe : nameEn;

  String hint(String languageCode) => languageCode == 'de' ? hintDe : hintEn;
}

/// Wie weit ein Erfolg gediehen ist.
@immutable
class AchievementStatus {
  const AchievementStatus({
    required this.achievement,
    required this.value,
    this.unlockedAt,
  });

  final Achievement achievement;

  /// Der aktuelle Stand der Kennzahl.
  final int value;

  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  double get fraction => (value / achievement.threshold).clamp(0.0, 1.0);
}

/// Der Katalog. Er steht im Code und nicht in den Daten: die Bedingungen sind
/// Logik, und eine neue Sprache soll sie nicht neu erzeugen müssen.
abstract final class Achievements {
  static const all = <Achievement>[
    // ── Umfang ───────────────────────────────────────────────────────────────
    Achievement(
      id: 'moves-100',
      category: AchievementCategory.volume,
      metric: AchievementMetric.movesTrained,
      threshold: 100,
      nameDe: 'Erste hundert',
      nameEn: 'First hundred',
      hintDe: 'Übe 100 Züge.',
      hintEn: 'Train 100 moves.',
      xpReward: 50,
    ),
    Achievement(
      id: 'moves-1000',
      category: AchievementCategory.volume,
      metric: AchievementMetric.movesTrained,
      threshold: 1000,
      nameDe: 'Tausend Züge',
      nameEn: 'A thousand moves',
      hintDe: 'Übe 1000 Züge.',
      hintEn: 'Train 1000 moves.',
    ),
    Achievement(
      id: 'moves-5000',
      category: AchievementCategory.volume,
      metric: AchievementMetric.movesTrained,
      threshold: 5000,
      nameDe: 'Fünftausend',
      nameEn: 'Five thousand',
      hintDe: 'Übe 5000 Züge.',
      hintEn: 'Train 5000 moves.',
      xpReward: 250,
    ),
    Achievement(
      id: 'moves-20000',
      category: AchievementCategory.volume,
      metric: AchievementMetric.movesTrained,
      threshold: 20000,
      nameDe: 'Zwanzigtausend',
      nameEn: 'Twenty thousand',
      hintDe: 'Übe 20 000 Züge.',
      hintEn: 'Train 20,000 moves.',
      xpReward: 750,
    ),
    Achievement(
      id: 'sessions-10',
      category: AchievementCategory.volume,
      metric: AchievementMetric.sessions,
      threshold: 10,
      nameDe: 'Angekommen',
      nameEn: 'Settled in',
      hintDe: 'Schließe 10 Trainingseinheiten ab.',
      hintEn: 'Complete 10 training sessions.',
      xpReward: 50,
    ),
    Achievement(
      id: 'sessions-50',
      category: AchievementCategory.volume,
      metric: AchievementMetric.sessions,
      threshold: 50,
      nameDe: 'Fünfzig Einheiten',
      nameEn: 'Fifty sessions',
      hintDe: 'Schließe 50 Trainingseinheiten ab.',
      hintEn: 'Complete 50 training sessions.',
    ),
    Achievement(
      id: 'sessions-200',
      category: AchievementCategory.volume,
      metric: AchievementMetric.sessions,
      threshold: 200,
      nameDe: 'Zweihundert Einheiten',
      nameEn: 'Two hundred sessions',
      hintDe: 'Schließe 200 Trainingseinheiten ab.',
      hintEn: 'Complete 200 training sessions.',
      xpReward: 400,
    ),
    Achievement(
      id: 'minutes-60',
      category: AchievementCategory.volume,
      metric: AchievementMetric.studyMinutes,
      threshold: 60,
      nameDe: 'Eine Stunde',
      nameEn: 'One hour',
      hintDe: 'Sammle 60 Minuten Lernzeit.',
      hintEn: 'Accumulate 60 minutes of study time.',
      xpReward: 50,
    ),
    Achievement(
      id: 'minutes-600',
      category: AchievementCategory.volume,
      metric: AchievementMetric.studyMinutes,
      threshold: 600,
      nameDe: 'Zehn Stunden',
      nameEn: 'Ten hours',
      hintDe: 'Sammle 10 Stunden Lernzeit.',
      hintEn: 'Accumulate 10 hours of study time.',
      xpReward: 250,
    ),
    Achievement(
      id: 'minutes-3000',
      category: AchievementCategory.volume,
      metric: AchievementMetric.studyMinutes,
      threshold: 3000,
      nameDe: 'Fünfzig Stunden',
      nameEn: 'Fifty hours',
      hintDe: 'Sammle 50 Stunden Lernzeit.',
      hintEn: 'Accumulate 50 hours of study time.',
      xpReward: 750,
    ),

    // ── Genauigkeit ─────────────────────────────────────────────────────────
    Achievement(
      id: 'perfect-1',
      category: AchievementCategory.accuracy,
      metric: AchievementMetric.perfectSessions,
      threshold: 1,
      nameDe: 'Ohne Fehler',
      nameEn: 'Flawless',
      hintDe: 'Spiele eine Einheit ohne einen einzigen Fehler.',
      hintEn: 'Play a session without a single mistake.',
      xpReward: 75,
    ),
    Achievement(
      id: 'perfect-10',
      category: AchievementCategory.accuracy,
      metric: AchievementMetric.perfectSessions,
      threshold: 10,
      nameDe: 'Zehn saubere Runden',
      nameEn: 'Ten clean rounds',
      hintDe: 'Spiele 10 fehlerfreie Einheiten.',
      hintEn: 'Play 10 flawless sessions.',
    ),
    Achievement(
      id: 'perfect-50',
      category: AchievementCategory.accuracy,
      metric: AchievementMetric.perfectSessions,
      threshold: 50,
      nameDe: 'Präzisionsarbeit',
      nameEn: 'Precision work',
      hintDe: 'Spiele 50 fehlerfreie Einheiten.',
      hintEn: 'Play 50 flawless sessions.',
      xpReward: 500,
    ),
    Achievement(
      id: 'mastered-10',
      category: AchievementCategory.accuracy,
      metric: AchievementMetric.linesMastered,
      threshold: 10,
      nameDe: 'Zehn gemeistert',
      nameEn: 'Ten mastered',
      hintDe: 'Meistere 10 Varianten fehlerfrei.',
      hintEn: 'Master 10 lines without mistakes.',
      xpReward: 75,
    ),
    Achievement(
      id: 'mastered-100',
      category: AchievementCategory.accuracy,
      metric: AchievementMetric.linesMastered,
      threshold: 100,
      nameDe: 'Hundert gemeistert',
      nameEn: 'A hundred mastered',
      hintDe: 'Meistere 100 Varianten.',
      hintEn: 'Master 100 lines.',
      xpReward: 300,
    ),
    Achievement(
      id: 'mastered-500',
      category: AchievementCategory.accuracy,
      metric: AchievementMetric.linesMastered,
      threshold: 500,
      nameDe: 'Fünfhundert gemeistert',
      nameEn: 'Five hundred mastered',
      hintDe: 'Meistere 500 Varianten.',
      hintEn: 'Master 500 lines.',
      xpReward: 800,
    ),

    // ── Serie ────────────────────────────────────────────────────────────────
    Achievement(
      id: 'streak-3',
      category: AchievementCategory.streak,
      metric: AchievementMetric.bestStreak,
      threshold: 3,
      nameDe: 'Drei Tage',
      nameEn: 'Three days',
      hintDe: 'Übe an drei Tagen hintereinander.',
      hintEn: 'Practise three days in a row.',
      xpReward: 50,
    ),
    Achievement(
      id: 'streak-7',
      category: AchievementCategory.streak,
      metric: AchievementMetric.bestStreak,
      threshold: 7,
      nameDe: 'Eine Woche',
      nameEn: 'One week',
      hintDe: 'Übe an sieben Tagen hintereinander.',
      hintEn: 'Practise seven days in a row.',
    ),
    Achievement(
      id: 'streak-30',
      category: AchievementCategory.streak,
      metric: AchievementMetric.bestStreak,
      threshold: 30,
      nameDe: 'Ein Monat',
      nameEn: 'One month',
      hintDe: 'Übe an 30 Tagen hintereinander.',
      hintEn: 'Practise 30 days in a row.',
      xpReward: 400,
    ),
    Achievement(
      id: 'streak-100',
      category: AchievementCategory.streak,
      metric: AchievementMetric.bestStreak,
      threshold: 100,
      nameDe: 'Hundert Tage',
      nameEn: 'A hundred days',
      hintDe: 'Übe an 100 Tagen hintereinander.',
      hintEn: 'Practise 100 days in a row.',
      xpReward: 1000,
    ),
    Achievement(
      id: 'streak-365',
      category: AchievementCategory.streak,
      metric: AchievementMetric.bestStreak,
      threshold: 365,
      nameDe: 'Ein ganzes Jahr',
      nameEn: 'A whole year',
      hintDe: 'Übe an 365 Tagen hintereinander.',
      hintEn: 'Practise 365 days in a row.',
      xpReward: 2500,
    ),

    // ── Repertoire ──────────────────────────────────────────────────────────
    Achievement(
      id: 'repertoires-1',
      category: AchievementCategory.repertoire,
      metric: AchievementMetric.repertoires,
      threshold: 1,
      nameDe: 'Der Anfang',
      nameEn: 'The beginning',
      hintDe: 'Lege dein erstes Repertoire an.',
      hintEn: 'Create your first repertoire.',
      xpReward: 25,
    ),
    Achievement(
      id: 'repertoires-5',
      category: AchievementCategory.repertoire,
      metric: AchievementMetric.repertoires,
      threshold: 5,
      nameDe: 'Breites Repertoire',
      nameEn: 'Broad repertoire',
      hintDe: 'Führe fünf Repertoires.',
      hintEn: 'Keep five repertoires.',
    ),
    Achievement(
      id: 'repertoires-12',
      category: AchievementCategory.repertoire,
      metric: AchievementMetric.repertoires,
      threshold: 12,
      nameDe: 'Für jeden Fall gewappnet',
      nameEn: 'Ready for anything',
      hintDe: 'Führe zwölf Repertoires.',
      hintEn: 'Keep twelve repertoires.',
      xpReward: 300,
    ),
    Achievement(
      id: 'level-5',
      category: AchievementCategory.repertoire,
      metric: AchievementMetric.level,
      threshold: 5,
      nameDe: 'Level 5',
      nameEn: 'Level 5',
      hintDe: 'Erreiche Level 5.',
      hintEn: 'Reach level 5.',
      xpReward: 50,
    ),
    Achievement(
      id: 'level-10',
      category: AchievementCategory.repertoire,
      metric: AchievementMetric.level,
      threshold: 10,
      nameDe: 'Level 10',
      nameEn: 'Level 10',
      hintDe: 'Erreiche Level 10.',
      hintEn: 'Reach level 10.',
      xpReward: 150,
    ),
    Achievement(
      id: 'level-25',
      category: AchievementCategory.repertoire,
      metric: AchievementMetric.level,
      threshold: 25,
      nameDe: 'Level 25',
      nameEn: 'Level 25',
      hintDe: 'Erreiche Level 25.',
      hintEn: 'Reach level 25.',
      xpReward: 600,
    ),
    Achievement(
      id: 'level-50',
      category: AchievementCategory.repertoire,
      metric: AchievementMetric.level,
      threshold: 50,
      nameDe: 'Level 50',
      nameEn: 'Level 50',
      hintDe: 'Erreiche Level 50.',
      hintEn: 'Reach level 50.',
      xpReward: 2000,
    ),

    // ── Modi ────────────────────────────────────────────────────────────────
    Achievement(
      id: 'traps-1',
      category: AchievementCategory.modes,
      metric: AchievementMetric.trapsRefuted,
      threshold: 1,
      nameDe: 'Nicht hereingefallen',
      nameEn: 'Did not fall for it',
      hintDe: 'Widerlege eine Eröffnungsfalle.',
      hintEn: 'Refute an opening trap.',
      xpReward: 50,
    ),
    Achievement(
      id: 'traps-10',
      category: AchievementCategory.modes,
      metric: AchievementMetric.trapsRefuted,
      threshold: 10,
      nameDe: 'Fallenkenner',
      nameEn: 'Trap spotter',
      hintDe: 'Widerlege 10 Eröffnungsfallen.',
      hintEn: 'Refute 10 opening traps.',
      xpReward: 150,
    ),
    Achievement(
      id: 'traps-25',
      category: AchievementCategory.modes,
      metric: AchievementMetric.trapsRefuted,
      threshold: 25,
      nameDe: 'Alle Fallen gesehen',
      nameEn: 'Seen every trap',
      hintDe: 'Widerlege 25 Eröffnungsfallen.',
      hintEn: 'Refute 25 opening traps.',
      xpReward: 400,
    ),

    // ── Lichess ─────────────────────────────────────────────────────────────
    Achievement(
      id: 'lichess-1',
      category: AchievementCategory.lichess,
      metric: AchievementMetric.lichessGames,
      threshold: 1,
      nameDe: 'Verbunden',
      nameEn: 'Connected',
      hintDe: 'Importiere deine erste Partie von Lichess.',
      hintEn: 'Import your first game from Lichess.',
      xpReward: 50,
    ),
    Achievement(
      id: 'lichess-100',
      category: AchievementCategory.lichess,
      metric: AchievementMetric.lichessGames,
      threshold: 100,
      nameDe: 'Hundert Partien',
      nameEn: 'A hundred games',
      hintDe: 'Importiere 100 Partien von Lichess.',
      hintEn: 'Import 100 games from Lichess.',
      xpReward: 150,
    ),
    Achievement(
      id: 'lichess-1000',
      category: AchievementCategory.lichess,
      metric: AchievementMetric.lichessGames,
      threshold: 1000,
      nameDe: 'Tausend Partien',
      nameEn: 'A thousand games',
      hintDe: 'Importiere 1000 Partien von Lichess.',
      hintEn: 'Import 1000 games from Lichess.',
      xpReward: 500,
    ),
  ];

  static Achievement? byId(String id) {
    for (final achievement in all) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }

  static List<Achievement> inCategory(AchievementCategory category) =>
      all.where((a) => a.category == category).toList();

  /// Prüft alle Erfolge gegen die Kennzahlen und liefert den Stand.
  ///
  /// [unlocked] enthält die Zeitpunkte bereits freigeschalteter Erfolge; sie
  /// bleiben stehen, auch wenn eine Kennzahl später kleiner wird — ein
  /// gelöschtes Repertoire soll einen Erfolg nicht zurücknehmen.
  static List<AchievementStatus> evaluate({
    required Map<AchievementMetric, int> metrics,
    required Map<String, DateTime> unlocked,
    required DateTime now,
  }) {
    return [
      for (final achievement in all)
        AchievementStatus(
          achievement: achievement,
          value: metrics[achievement.metric] ?? 0,
          unlockedAt:
              unlocked[achievement.id] ??
              ((metrics[achievement.metric] ?? 0) >= achievement.threshold
                  ? now
                  : null),
        ),
    ];
  }

  /// Welche Erfolge mit diesen Kennzahlen neu offen sind.
  static List<Achievement> newlyUnlocked({
    required Map<AchievementMetric, int> metrics,
    required Set<String> alreadyUnlocked,
  }) {
    return [
      for (final achievement in all)
        if (!alreadyUnlocked.contains(achievement.id) &&
            (metrics[achievement.metric] ?? 0) >= achievement.threshold)
          achievement,
    ];
  }
}
