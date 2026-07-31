import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/chess/san_notation.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/analysis/data/analysis_providers.dart';
import 'package:masteropening/features/analysis/domain/gap.dart';
import 'package:masteropening/features/lichess/data/lichess_providers.dart';
import 'package:masteropening/features/training/presentation/training_screen.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Lädt Lücken und Fehler und reicht sie an [RepairView] weiter.
class RepairScreen extends ConsumerWidget {
  const RepairScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);
    final controller = ref.read(analysisProvider.notifier);

    return RepairView(
      state: state,
      gaps: ref.watch(gapsProvider).value ?? const [],
      mistakes: ref.watch(mistakesProvider).value ?? const [],
      hasGames: (ref.watch(lichessGamesProvider).value ?? const []).isNotEmpty,
      onAnalyse: () => controller.run(force: true),
      onDismiss: controller.dismiss,
      onAdd: (gap) => _add(context, ref, gap),
      // Direkt in den Variantenmodus, nicht über die Modusauswahl: wer hier
      // tippt, hat sich schon für einen Zug entschieden.
      onTrain: (mistake) => unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => TrainingScreen(
              mode: TrainingMode.variation,
              repertoireId: mistake.repertoireId,
              pathHash: mistake.pathHash,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    RepertoireGap gap,
  ) async {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final language = Localizations.localeOf(context).languageCode;

    final hash = await ref.read(analysisProvider.notifier).addToRepertoire(gap);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          hash == null
              ? l10n.repairGapAddFailed
              : l10n.repairGapAdded(
                  SanNotation.localize(gap.missingSan, language),
                ),
        ),
      ),
    );
  }
}

/// Was die Auswertung der eigenen Partien ergeben hat.
class RepairView extends StatelessWidget {
  const RepairView({
    required this.state,
    required this.gaps,
    required this.mistakes,
    required this.hasGames,
    super.key,
    this.onAnalyse,
    this.onDismiss,
    this.onAdd,
    this.onTrain,
  });

  final AnalysisState state;
  final List<RepertoireGap> gaps;
  final List<MoveMistake> mistakes;
  final bool hasGames;

  final Future<void> Function()? onAnalyse;
  final Future<void> Function(int gapId)? onDismiss;
  final Future<void> Function(RepertoireGap gap)? onAdd;
  final void Function(MoveMistake mistake)? onTrain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.repairTitle)),
      body: !hasGames
          ? EmptyState(
              icon: PhIcons.chartBar,
              title: l10n.repairNoGamesTitle,
              message: l10n.repairNoGamesMessage,
            )
          : ListView(
              padding: const EdgeInsets.only(
                top: AppSpacing.xl,
                bottom: AppSpacing.huge,
              ),
              children: [
                ScreenPadding(
                  child: AppButton.block(
                    label: state.running
                        ? l10n.repairAnalysing
                        : l10n.repairAnalyse,
                    icon: PhIcons.magnifyingGlass,
                    busy: state.running,
                    onPressed: state.running || onAnalyse == null
                        ? null
                        : () => unawaited(onAnalyse!()),
                  ),
                ),

                if (state.summary case final summary?) ...[
                  const SizedBox(height: AppSpacing.md),
                  ScreenPadding(
                    child: Text(
                      l10n.repairSummary(
                        summary.gamesAnalysed,
                        summary.gapsFound,
                        summary.ownDeviations,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textAlpha(0.55),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xxl),
                ScreenPadding(child: SectionLabel(l10n.repairSectionGaps)),

                if (gaps.isEmpty)
                  ScreenPadding(
                    child: Text(
                      l10n.repairNoGapsMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textAlpha(0.5),
                      ),
                    ),
                  )
                else ...[
                  ScreenPadding(
                    child: Text(
                      l10n.repairGapExplain,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textAlpha(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final gap in gaps)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        0,
                        AppSpacing.screen,
                        AppSpacing.md,
                      ),
                      child: _GapCard(
                        gap: gap,
                        onAdd: onAdd,
                        onDismiss: onDismiss,
                      ),
                    ),
                ],

                const SizedBox(height: AppSpacing.xxl),
                ScreenPadding(child: SectionLabel(l10n.repairSectionMistakes)),

                if (mistakes.isEmpty)
                  ScreenPadding(
                    child: Text(
                      l10n.repairNoMistakes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textAlpha(0.5),
                      ),
                    ),
                  )
                else
                  for (final mistake in mistakes)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        0,
                        AppSpacing.screen,
                        AppSpacing.md,
                      ),
                      child: _MistakeCard(mistake: mistake, onTrain: onTrain),
                    ),
              ],
            ),
    );
  }
}

class _GapCard extends StatelessWidget {
  const _GapCard({required this.gap, this.onAdd, this.onDismiss});

  final RepertoireGap gap;
  final Future<void> Function(RepertoireGap gap)? onAdd;
  final Future<void> Function(int gapId)? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  SanNotation.localize(gap.missingSan, language),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              AppTag(
                l10n.repairGapPointsLost(
                  gap.pointsLost.toStringAsFixed(1),
                ),
                variant: gap.pointsLost > 0
                    ? AppTagVariant.accent
                    : AppTagVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.repairGapOccurrences(gap.occurrences),
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textAlpha(0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.card),
          Row(
            children: [
              AppButton(
                label: l10n.repairGapAdd,
                size: AppButtonSize.small,
                onPressed: onAdd == null ? null : () => unawaited(onAdd!(gap)),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: l10n.repairGapDismiss,
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.small,
                onPressed: onDismiss == null
                    ? null
                    : () => unawaited(onDismiss!(gap.id)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({required this.mistake, this.onTrain});

  final MoveMistake mistake;
  final void Function(MoveMistake mistake)? onTrain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    return AppCard(
      onTap: onTrain == null ? null : () => onTrain!(mistake),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SanNotation.localize(mistake.expectedSan, language),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                if (mistake.sanLine.isNotEmpty)
                  Text(
                    mistake.sanLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textAlpha(0.5),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    l10n.repairMistakeRate(mistake.wrong, mistake.attempts),
                    if (mistake.commonWrongSan case final san?)
                      l10n.repairMistakeInstead(
                        SanNotation.localize(san, language),
                      ),
                  ].join(' · '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.danger,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(PhIcons.caretRight, size: 14, color: tokens.textAlpha(0.4)),
        ],
      ),
    );
  }
}
