import 'dart:math';

import 'package:masteropening/core/db/enums.dart';
import 'package:meta/meta.dart';

/// Wonach eine Aufgabe bemessen wird.
///
/// Anders als bei den Erfolgen zählen hier nur die Werte des Zeitraums —
/// eine Tagesaufgabe fragt, was heute passiert ist.
enum ChallengeMetric {
  /// Geübte Züge im Zeitraum.
  moves,

  /// Abgeschlossene Einheiten im Zeitraum.
  sessions,

  /// Fehlerfrei gespielte Varianten im Zeitraum.
  masteredLines,

  /// Lernzeit in Minuten im Zeitraum.
  minutes,

  /// Tage mit Übung im Zeitraum — nur für Wochenaufgaben sinnvoll.
  activeDays,

  /// Richtige Züge in Folge, ohne Fehler dazwischen.
  correctMoves,
}

/// Die Vorlage einer Aufgabe.
@immutable
class ChallengeTemplate {
  const ChallengeTemplate({
    required this.type,
    required this.kind,
    required this.metric,
    required this.target,
    required this.xpReward,
    required this.textDe,
    required this.textEn,
  });

  /// Slug, der in der Datenbank steht.
  final String type;

  final ChallengeKind kind;
  final ChallengeMetric metric;
  final int target;
  final int xpReward;

  /// Beschreibung mit `{target}` als Platzhalter — die Zahl steht in den
  /// Daten, nicht im Text, damit sich Zielwerte ändern lassen, ohne die
  /// Übersetzung anzufassen.
  final String textDe;
  final String textEn;

  String text(String languageCode) {
    final template = languageCode == 'de' ? textDe : textEn;
    return template.replaceAll('{target}', '$target');
  }
}

/// Eine Aufgabe für einen konkreten Zeitraum.
@immutable
class ChallengeInstance {
  const ChallengeInstance({
    required this.template,
    required this.periodKey,
    required this.progress,
    this.completedAt,
  });

  final ChallengeTemplate template;

  /// `JJJJ-MM-TT` für Tages-, `JJJJ-WNN` für Wochenaufgaben.
  final String periodKey;

  final int progress;
  final DateTime? completedAt;

  /// `<kind>:<periodKey>:<type>` — dieselbe Aufgabe existiert je Zeitraum
  /// genau einmal.
  String get id => '${template.kind.name}:$periodKey:${template.type}';

  bool get isComplete => completedAt != null || progress >= template.target;

  double get fraction => (progress / template.target).clamp(0.0, 1.0);
}

/// Der Katalog und die Auswahl je Zeitraum.
abstract final class Challenges {
  /// Wie viele Aufgaben gleichzeitig offen sind.
  static const perDay = 3;
  static const perWeek = 3;

  static const daily = <ChallengeTemplate>[
    ChallengeTemplate(
      type: 'moves-30',
      kind: ChallengeKind.daily,
      metric: ChallengeMetric.moves,
      target: 30,
      xpReward: 60,
      textDe: 'Übe heute {target} Züge',
      textEn: 'Train {target} moves today',
    ),
    ChallengeTemplate(
      type: 'moves-60',
      kind: ChallengeKind.daily,
      metric: ChallengeMetric.moves,
      target: 60,
      xpReward: 100,
      textDe: 'Übe heute {target} Züge',
      textEn: 'Train {target} moves today',
    ),
    ChallengeTemplate(
      type: 'sessions-2',
      kind: ChallengeKind.daily,
      metric: ChallengeMetric.sessions,
      target: 2,
      xpReward: 80,
      textDe: 'Schließe heute {target} Einheiten ab',
      textEn: 'Complete {target} sessions today',
    ),
    ChallengeTemplate(
      type: 'mastered-3',
      kind: ChallengeKind.daily,
      metric: ChallengeMetric.masteredLines,
      target: 3,
      xpReward: 100,
      textDe: 'Meistere heute {target} Varianten fehlerfrei',
      textEn: 'Master {target} lines flawlessly today',
    ),
    ChallengeTemplate(
      type: 'minutes-10',
      kind: ChallengeKind.daily,
      metric: ChallengeMetric.minutes,
      target: 10,
      xpReward: 70,
      textDe: 'Übe heute {target} Minuten',
      textEn: 'Study for {target} minutes today',
    ),
    ChallengeTemplate(
      type: 'correct-25',
      kind: ChallengeKind.daily,
      metric: ChallengeMetric.correctMoves,
      target: 25,
      xpReward: 90,
      textDe: 'Spiele heute {target} Züge richtig',
      textEn: 'Play {target} moves correctly today',
    ),
  ];

  static const weekly = <ChallengeTemplate>[
    ChallengeTemplate(
      type: 'moves-300',
      kind: ChallengeKind.weekly,
      metric: ChallengeMetric.moves,
      target: 300,
      xpReward: 400,
      textDe: 'Übe diese Woche {target} Züge',
      textEn: 'Train {target} moves this week',
    ),
    ChallengeTemplate(
      type: 'days-5',
      kind: ChallengeKind.weekly,
      metric: ChallengeMetric.activeDays,
      target: 5,
      xpReward: 500,
      textDe: 'Übe an {target} Tagen dieser Woche',
      textEn: 'Practise on {target} days this week',
    ),
    ChallengeTemplate(
      type: 'days-7',
      kind: ChallengeKind.weekly,
      metric: ChallengeMetric.activeDays,
      target: 7,
      xpReward: 700,
      textDe: 'Übe an allen {target} Tagen dieser Woche',
      textEn: 'Practise on all {target} days this week',
    ),
    ChallengeTemplate(
      type: 'mastered-25',
      kind: ChallengeKind.weekly,
      metric: ChallengeMetric.masteredLines,
      target: 25,
      xpReward: 450,
      textDe: 'Meistere diese Woche {target} Varianten',
      textEn: 'Master {target} lines this week',
    ),
    ChallengeTemplate(
      type: 'minutes-90',
      kind: ChallengeKind.weekly,
      metric: ChallengeMetric.minutes,
      target: 90,
      xpReward: 400,
      textDe: 'Übe diese Woche {target} Minuten',
      textEn: 'Study for {target} minutes this week',
    ),
    ChallengeTemplate(
      type: 'sessions-10',
      kind: ChallengeKind.weekly,
      metric: ChallengeMetric.sessions,
      target: 10,
      xpReward: 450,
      textDe: 'Schließe diese Woche {target} Einheiten ab',
      textEn: 'Complete {target} sessions this week',
    ),
  ];

  /// Der Schlüssel des Tages.
  static String dayKey(DateTime local) {
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  /// Der Schlüssel der Woche nach ISO 8601 — Montag beginnt sie.
  ///
  /// Gerechnet wird in UTC: eine Zeitumstellung mitten in der Woche würde
  /// sonst beim Addieren von Tagen eine Stunde verschieben und die Woche über
  /// die Grenze kippen lassen.
  static String weekKey(DateTime local) {
    final date = DateTime.utc(local.year, local.month, local.day);

    // Der Donnerstag derselben Woche entscheidet, zu welchem Jahr sie zählt —
    // so bekommt eine Woche über den Jahreswechsel eine eindeutige Nummer.
    final thursday = date.add(Duration(days: 4 - date.weekday));

    // Die Woche mit dem 4. Januar ist per Definition Woche 1.
    final fourthOfJanuary = DateTime.utc(thursday.year, 1, 4);
    final firstMonday = fourthOfJanuary.subtract(
      Duration(days: fourthOfJanuary.weekday - 1),
    );

    final week = 1 + thursday.difference(firstMonday).inDays ~/ 7;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// Welche Aufgaben in diesem Zeitraum gelten.
  ///
  /// Die Auswahl hängt am Zeitraumschlüssel und nicht am Zufall des Moments:
  /// derselbe Tag ergibt immer dieselben drei Aufgaben, auch nach einem
  /// Neustart der App.
  static List<ChallengeTemplate> pick({
    required ChallengeKind kind,
    required String periodKey,
  }) {
    final pool = [...kind == ChallengeKind.daily ? daily : weekly];
    final count = kind == ChallengeKind.daily ? perDay : perWeek;

    final random = Random(periodKey.hashCode);
    pool.shuffle(random);
    return pool.take(count).toList();
  }
}
