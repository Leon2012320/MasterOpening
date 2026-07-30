import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Der Rang eines Spielers, ausgerechnet aus den gesammelten Punkten.
@immutable
class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.totalXp,
    required this.xpAtLevelStart,
    required this.xpForNextLevel,
  });

  final int level;
  final int totalXp;

  /// Punktestand, ab dem dieses Level beginnt.
  final int xpAtLevelStart;

  /// Punktestand, ab dem das nächste Level beginnt. `null` beim höchsten.
  final int? xpForNextLevel;

  bool get isMaxLevel => xpForNextLevel == null;

  /// Punkte, die im aktuellen Level bereits gesammelt sind.
  int get xpInLevel => totalXp - xpAtLevelStart;

  /// Punkte, die dieses Level insgesamt umfasst.
  int get xpSpan => (xpForNextLevel ?? totalXp) - xpAtLevelStart;

  /// Wie viele Punkte noch bis zum nächsten Level fehlen.
  int get xpRemaining => xpForNextLevel == null ? 0 : xpForNextLevel! - totalXp;

  /// 0 bis 1 — der Füllstand der Levelleiste.
  double get fraction {
    if (isMaxLevel || xpSpan <= 0) return 1;
    return (xpInLevel / xpSpan).clamp(0.0, 1.0);
  }
}

/// Die Levelkurve.
///
/// Früh geht es schnell voran, später immer langsamer: die ersten Level sollen
/// sich nach zwei Einheiten einstellen, Level 20 nach Monaten. Der Exponent
/// 2,1 trifft das — linear wäre auf Dauer langweilig, quadratisch schon nach
/// wenigen Wochen unerreichbar.
abstract final class LevelSystem {
  static const maxLevel = 60;

  static const _factor = 20;
  static const _exponent = 2.1;

  /// Punktestand, ab dem [level] beginnt. Level 1 beginnt bei null.
  static int xpToReach(int level) {
    if (level <= 1) return 0;
    return (_factor * math.pow(level - 1, _exponent)).round();
  }

  /// Der Rang zu einem Punktestand.
  static LevelProgress progressFor(int totalXp) {
    final xp = totalXp < 0 ? 0 : totalXp;

    var level = 1;
    while (level < maxLevel && xp >= xpToReach(level + 1)) {
      level++;
    }

    return LevelProgress(
      level: level,
      totalXp: xp,
      xpAtLevelStart: xpToReach(level),
      xpForNextLevel: level >= maxLevel ? null : xpToReach(level + 1),
    );
  }

  /// Ob ein Punktezuwachs über eine Levelgrenze getragen hat — die Bedingung
  /// für die Aufstiegs-Animation.
  static bool didLevelUp({required int before, required int after}) =>
      progressFor(after).level > progressFor(before).level;
}
