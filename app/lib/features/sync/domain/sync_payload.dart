import 'package:meta/meta.dart';

/// Die Token, mit denen die App beim eigenen Server arbeitet.
@immutable
class SyncSession {
  const SyncSession({required this.accessToken, required this.refreshToken});

  factory SyncSession.fromJson(Map<String, dynamic> json) => SyncSession(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );

  final String accessToken;
  final String refreshToken;
}

/// Ein Repertoire, wie es über die Leitung geht.
///
/// Bewusst nicht die Drift-Zeile selbst: die trägt eine lokale `id`, die auf
/// einem anderen Gerät nichts bedeutet. Über die Leitung reist die `uuid`.
@immutable
class RepertoireDto {
  const RepertoireDto({
    required this.uuid,
    required this.name,
    required this.side,
    required this.pgn,
    required this.startFen,
    required this.source,
    required this.updatedAt,
    this.ecoCodes = '',
    this.sourceRef,
    this.sortOrder = 0,
    this.isArchived = false,
    this.nodeCount = 0,
    this.lineCount = 0,
    this.revision = 0,
    this.deletedAt,
  });

  factory RepertoireDto.fromJson(Map<String, dynamic> json) => RepertoireDto(
    uuid: json['uuid'] as String,
    name: json['name'] as String,
    side: json['side'] as String,
    pgn: json['pgn'] as String,
    startFen: json['startFen'] as String,
    ecoCodes: json['ecoCodes'] as String? ?? '',
    source: json['source'] as String,
    sourceRef: json['sourceRef'] as String?,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    isArchived: json['isArchived'] as bool? ?? false,
    nodeCount: (json['nodeCount'] as num?)?.toInt() ?? 0,
    lineCount: (json['lineCount'] as num?)?.toInt() ?? 0,
    revision: (json['revision'] as num?)?.toInt() ?? 0,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    deletedAt: _parseOptional(json['deletedAt']),
  );

  final String uuid;
  final String name;

  /// `white` oder `black` — der Name des Dart-Enums, wie ihn auch die
  /// Datenbank speichert.
  final String side;

  final String pgn;
  final String startFen;
  final String ecoCodes;
  final String source;
  final String? sourceRef;
  final int sortOrder;
  final bool isArchived;
  final int nodeCount;
  final int lineCount;
  final int revision;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'name': name,
    'side': side,
    'pgn': pgn,
    'startFen': startFen,
    'ecoCodes': ecoCodes,
    'source': source,
    'sourceRef': sourceRef,
    'sortOrder': sortOrder,
    'isArchived': isArchived,
    'nodeCount': nodeCount,
    'lineCount': lineCount,
    'revision': revision,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deletedAt': deletedAt?.toUtc().toIso8601String(),
  };
}

/// Der Lernstand eines Zuges.
@immutable
class ProgressDto {
  const ProgressDto({
    required this.repertoireUuid,
    required this.pathHash,
    required this.state,
    required this.stability,
    required this.difficulty,
    required this.due,
    required this.reps,
    required this.lapses,
    required this.correctCount,
    required this.wrongCount,
    required this.updatedAt,
    this.lastReview,
  });

  factory ProgressDto.fromJson(Map<String, dynamic> json) => ProgressDto(
    repertoireUuid: json['repertoireUuid'] as String,
    pathHash: json['pathHash'] as String,
    state: json['state'] as String,
    stability: (json['stability'] as num).toDouble(),
    difficulty: (json['difficulty'] as num).toDouble(),
    due: DateTime.parse(json['due'] as String),
    lastReview: _parseOptional(json['lastReview']),
    reps: (json['reps'] as num).toInt(),
    lapses: (json['lapses'] as num).toInt(),
    correctCount: (json['correctCount'] as num).toInt(),
    wrongCount: (json['wrongCount'] as num).toInt(),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final String repertoireUuid;
  final String pathHash;
  final String state;
  final double stability;
  final double difficulty;
  final DateTime due;
  final DateTime? lastReview;
  final int reps;
  final int lapses;
  final int correctCount;
  final int wrongCount;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'repertoireUuid': repertoireUuid,
    'pathHash': pathHash,
    'state': state,
    'stability': stability,
    'difficulty': difficulty,
    'due': due.toUtc().toIso8601String(),
    'lastReview': lastReview?.toUtc().toIso8601String(),
    'reps': reps,
    'lapses': lapses,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

/// Punkte, Level und Serie.
@immutable
class ProfileDto {
  const ProfileDto({
    required this.totalXp,
    required this.streakCurrent,
    required this.streakBest,
    required this.streakFreezes,
    required this.updatedAt,
    this.lastActiveDay,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) => ProfileDto(
    totalXp: (json['totalXp'] as num).toInt(),
    streakCurrent: (json['streakCurrent'] as num).toInt(),
    streakBest: (json['streakBest'] as num).toInt(),
    streakFreezes: (json['streakFreezes'] as num).toInt(),
    lastActiveDay: json['lastActiveDay'] as String?,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final int totalXp;
  final int streakCurrent;
  final int streakBest;
  final int streakFreezes;
  final String? lastActiveDay;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'totalXp': totalXp,
    'streakCurrent': streakCurrent,
    'streakBest': streakBest,
    'streakFreezes': streakFreezes,
    'lastActiveDay': lastActiveDay,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

/// Was hochgeschoben wird.
@immutable
class PushPayload {
  const PushPayload({
    this.repertoires = const [],
    this.progress = const [],
    this.profile,
  });

  final List<RepertoireDto> repertoires;
  final List<ProgressDto> progress;
  final ProfileDto? profile;

  bool get isEmpty =>
      repertoires.isEmpty && progress.isEmpty && profile == null;

  Map<String, dynamic> toJson() => {
    'repertoires': [for (final r in repertoires) r.toJson()],
    'progress': [for (final p in progress) p.toJson()],
    if (profile != null) 'profile': profile!.toJson(),
  };
}

/// Was der Server angenommen und was er abgelehnt hat.
@immutable
class PushResponse {
  const PushResponse({
    required this.serverTime,
    required this.appliedRepertoires,
    required this.appliedProgress,
    required this.conflictedRepertoires,
  });

  factory PushResponse.fromJson(Map<String, dynamic> json) {
    final applied = json['applied'] as Map<String, dynamic>? ?? const {};
    final conflicts = json['conflicts'] as Map<String, dynamic>? ?? const {};

    return PushResponse(
      serverTime: DateTime.parse(json['serverTime'] as String),
      appliedRepertoires: (applied['repertoires'] as num?)?.toInt() ?? 0,
      appliedProgress: (applied['progress'] as num?)?.toInt() ?? 0,
      conflictedRepertoires: [
        for (final uuid in (conflicts['repertoires'] as List? ?? const []))
          uuid as String,
      ],
    );
  }

  final DateTime serverTime;
  final int appliedRepertoires;
  final int appliedProgress;

  /// Repertoires, bei denen der Server einen jüngeren Stand hatte. Sie kommen
  /// beim nächsten Abholen in der Serverfassung zurück.
  final List<String> conflictedRepertoires;
}

/// Was vom Server kommt.
@immutable
class PullResponse {
  const PullResponse({
    required this.serverTime,
    required this.repertoires,
    required this.progress,
    this.profile,
  });

  factory PullResponse.fromJson(Map<String, dynamic> json) => PullResponse(
    serverTime: DateTime.parse(json['serverTime'] as String),
    repertoires: [
      for (final row in (json['repertoires'] as List? ?? const []))
        RepertoireDto.fromJson(row as Map<String, dynamic>),
    ],
    progress: [
      for (final row in (json['progress'] as List? ?? const []))
        ProgressDto.fromJson(row as Map<String, dynamic>),
    ],
    profile: json['profile'] == null
        ? null
        : ProfileDto.fromJson(json['profile'] as Map<String, dynamic>),
  );

  final DateTime serverTime;
  final List<RepertoireDto> repertoires;
  final List<ProgressDto> progress;
  final ProfileDto? profile;
}

DateTime? _parseOptional(Object? value) =>
    value is String ? DateTime.parse(value) : null;
