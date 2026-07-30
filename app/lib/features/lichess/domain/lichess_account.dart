import 'package:meta/meta.dart';

/// Eine Wertung in einer Zeitkontrolle.
@immutable
class LichessPerf {
  const LichessPerf({
    required this.key,
    required this.rating,
    required this.games,
    this.progress = 0,
    this.provisional = false,
  });

  factory LichessPerf.fromJson(String key, Map<String, dynamic> json) {
    return LichessPerf(
      key: key,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      games: (json['games'] as num?)?.toInt() ?? 0,
      progress: (json['prog'] as num?)?.toInt() ?? 0,
      provisional: json['prov'] as bool? ?? false,
    );
  }

  /// `blitz`, `rapid`, `classical`, …
  final String key;

  final int rating;
  final int games;

  /// Veränderung über die letzten zwölf Partien.
  final int progress;

  /// Noch zu wenige Partien für eine belastbare Zahl.
  final bool provisional;

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'games': games,
    'prog': progress,
    'prov': provisional,
  };
}

/// Das verbundene Lichess-Konto.
///
/// Wird als JSON zwischengespeichert: das Profil soll auch ohne Netz stehen,
/// sonst wäre der Tab beim Start jedes Mal leer.
@immutable
class LichessAccount {
  const LichessAccount({
    required this.id,
    required this.username,
    required this.perfs,
    this.title,
    this.patron = false,
    this.gameCount = 0,
    this.createdAt,
  });

  factory LichessAccount.fromJson(Map<String, dynamic> json) {
    final rawPerfs = json['perfs'] as Map<String, dynamic>? ?? const {};
    final counts = json['count'] as Map<String, dynamic>? ?? const {};

    return LichessAccount(
      id: json['id'] as String,
      username: json['username'] as String? ?? json['id'] as String,
      title: json['title'] as String?,
      patron: json['patron'] as bool? ?? false,
      gameCount: (counts['all'] as num?)?.toInt() ?? 0,
      createdAt: switch (json['createdAt']) {
        final num millis => DateTime.fromMillisecondsSinceEpoch(
          millis.toInt(),
        ),
        _ => null,
      },
      perfs: {
        for (final entry in rawPerfs.entries)
          if (entry.value case final Map<String, dynamic> value)
            // Puzzle- und Sonderarten haben keine Partienzahl, die zu einer
            // Wertungsanzeige taugt.
            if ((value['games'] as num?) != null)
              entry.key: LichessPerf.fromJson(entry.key, value),
      },
    );
  }

  final String id;
  final String username;
  final String? title;
  final bool patron;
  final int gameCount;
  final DateTime? createdAt;

  final Map<String, LichessPerf> perfs;

  /// Die Zeitkontrollen, die im Profil gezeigt werden — in der Reihenfolge,
  /// in der Lichess sie selbst führt, und nur die tatsächlich gespielten.
  static const displayedPerfs = [
    'bullet',
    'blitz',
    'rapid',
    'classical',
    'correspondence',
  ];

  List<LichessPerf> get ratedPerfs => [
    for (final key in displayedPerfs)
      if (perfs[key] case final perf?)
        if (perf.games > 0) perf,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    if (title != null) 'title': title,
    'patron': patron,
    'count': {'all': gameCount},
    if (createdAt != null) 'createdAt': createdAt!.millisecondsSinceEpoch,
    'perfs': {
      for (final entry in perfs.entries) entry.key: entry.value.toJson(),
    },
  };
}
