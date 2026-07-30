import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/router/app_routes.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/gamification/data/gamification_providers.dart';
import 'package:masteropening/features/gamification/domain/challenge.dart';
import 'package:masteropening/features/gamification/domain/level_system.dart';
import 'package:masteropening/features/gamification/domain/streak.dart';
import 'package:masteropening/features/gamification/presentation/widgets/accuracy_chart.dart';
import 'package:masteropening/features/gamification/presentation/widgets/activity_heatmap.dart';
import 'package:masteropening/features/gamification/presentation/widgets/challenge_card.dart';
import 'package:masteropening/features/home/presentation/home_screen.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Lädt die Kennzahlen und reicht sie an [StatsView] weiter.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StatsView(
      totalXp: ref.watch(userProfileProvider).value?.totalXp ?? 0,
      days: ref.watch(activityDaysProvider).value ?? const [],
      sessions: ref.watch(recentSessionsProvider).value ?? const [],
      streak: ref.watch(streakProvider).value,
      challenges: ref.watch(challengesProvider).value ?? const [],
    );
  }
}

/// Alles, was sich über die Zeit angesammelt hat: Level, Serie, Aktivität,
/// Genauigkeitsverlauf und die offenen Aufgaben.
class StatsView extends StatelessWidget {
  const StatsView({
    required this.totalXp,
    required this.days,
    required this.sessions,
    required this.challenges,
    this.streak,
    super.key,
  });

  final int totalXp;
  final List<ActivityDay> days;
  final List<TrainingSession> sessions;
  final List<ChallengeInstance> challenges;
  final StreakState? streak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final level = LevelSystem.progressFor(totalXp);
    final seconds = days.fold(0, (sum, d) => sum + d.secondsStudied);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
        actions: [
          IconButton(
            icon: const Icon(PhIcons.trophy),
            tooltip: l10n.achievementsTitle,
            onPressed: () => unawaited(context.push(Routes.achievements)),
          ),
        ],
      ),
      body: days.isEmpty && sessions.isEmpty
          ? EmptyState(
              icon: PhIcons.chartLine,
              title: l10n.statsNoDataTitle,
              message: l10n.statsNoDataMessage,
            )
          : ListView(
              padding: const EdgeInsets.only(
                top: AppSpacing.xl,
                bottom: AppSpacing.huge,
              ),
              children: [
                ScreenPadding(child: _LevelCard(progress: level)),

                const SizedBox(height: AppSpacing.xl),
                ScreenPadding(
                  child: Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: '${streak?.current ?? 0}',
                          label: l10n.statsStreakCurrent,
                          icon: PhIcons.flame,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatTile(
                          value: '${streak?.best ?? 0}',
                          label: l10n.statsStreakBest,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatTile(
                          value: l10n.statsHours(
                            seconds ~/ 3600,
                            (seconds % 3600) ~/ 60,
                          ),
                          label: l10n.statsStudyTime,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
                ScreenPadding(child: SectionLabel(l10n.statsSectionActivity)),
                ActivityHeatmap(
                  days: days,
                  today: DateTime.now(),
                  frozenDays: streak?.usedFreezeDays ?? const {},
                ),
                const SizedBox(height: AppSpacing.md),
                ScreenPadding(
                  child: _FreezeHint(left: streak?.freezesLeft ?? 0),
                ),

                if (_accuracySessions.length >= 2) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  ScreenPadding(child: SectionLabel(l10n.statsSectionAccuracy)),
                  ScreenPadding(
                    child: AccuracyChart(sessions: _accuracySessions),
                  ),
                ],

                if (challenges.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  ScreenPadding(
                    child: SectionLabel(l10n.statsSectionChallenges),
                  ),
                  for (final kind in ChallengeKind.values) ...[
                    ScreenPadding(
                      child: Text(
                        kind == ChallengeKind.daily
                            ? l10n.statsDaily
                            : l10n.statsWeekly,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.tokens.textAlpha(0.45),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final challenge in challenges.where(
                      (c) => c.template.kind == kind,
                    ))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          0,
                          AppSpacing.screen,
                          AppSpacing.md,
                        ),
                        child: ChallengeCard(challenge: challenge),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ],
            ),
    );
  }

  /// Einheiten ohne Züge sagen über die Genauigkeit nichts aus.
  List<TrainingSession> get _accuracySessions =>
      sessions.where((s) => s.movesTotal > 0).toList();
}

/// Level, Punktestand und die Leiste zum nächsten Rang.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.progress});

  final LevelProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                l10n.statsLevel(progress.level),
                style: theme.textTheme.headlineSmall,
              ),
              const Spacer(),
              Text(
                '${progress.totalXp} XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textAlpha(0.55),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.card),
          AppProgressBar(value: progress.fraction, height: 6),
          const SizedBox(height: AppSpacing.sm),
          Text(
            progress.isMaxLevel
                ? l10n.statsMaxLevel
                : l10n.statsXpToNext(progress.xpRemaining, progress.level + 1),
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textAlpha(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wie viele Schutztage noch bereitstehen — die Erklärung zu den Kästchen mit
/// Kontur in der Heatmap.
class _FreezeHint extends StatelessWidget {
  const _FreezeHint({required this.left});

  final int left;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Row(
      children: [
        Icon(PhIcons.snowflake, size: 14, color: tokens.textAlpha(0.45)),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${AppL10n.of(context).statsFreezes}: $left',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tokens.textAlpha(0.45),
          ),
        ),
      ],
    );
  }
}
