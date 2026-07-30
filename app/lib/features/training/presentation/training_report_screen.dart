import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masteropening/chess/san_notation.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/training/domain/training_plan.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Was nach einer Einheit herauskam.
///
/// Die Genauigkeit zählt in Zügen, nicht in Varianten — eine Variante, in der
/// nur der letzte Zug danebenging, ist nicht dasselbe wie eine, die von vorn
/// nicht saß.
class TrainingReportScreen extends StatelessWidget {
  const TrainingReportScreen({required this.report, super.key});

  final TrainingReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.huge,
                  AppSpacing.screen,
                  AppSpacing.xl,
                ),
                children: [
                  _AccuracyRing(percent: report.accuracyPercent),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    l10n.reportTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.reportMoves(report.movesCorrect, report.movesTotal),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textAlpha(0.55),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: '${report.learnedCount}',
                          label: l10n.reportLearned,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatTile(
                          value: '${report.masteredCount}',
                          label: l10n.reportMastered,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatTile(
                          value: l10n.reportDuration(
                            report.duration.inMinutes,
                          ),
                          label: l10n.statStreak,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),

                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: AppTag(
                      l10n.reportXp(report.xpEarned),
                      variant: AppTagVariant.accent,
                    ),
                  ).animate().fadeIn(delay: 500.ms).scaleXY(begin: 0.8),

                  const SizedBox(height: AppSpacing.xxl),
                  if (report.weakest.isEmpty)
                    Center(
                      child: Text(
                        l10n.reportAllPerfect,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.success,
                        ),
                      ),
                    )
                  else ...[
                    SectionLabel(l10n.reportWeakest),
                    const SizedBox(height: AppSpacing.md),
                    for (final result in report.weakest)
                      _WeakLine(result: result, language: language),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                AppSpacing.xl,
              ),
              child: AppButton.block(
                label: l10n.reportDone,
                icon: PhIcons.check,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Der Genauigkeitsring — die Zahl, auf die es ankommt, füllt sich beim
/// Erscheinen auf.
class _AccuracyRing extends StatelessWidget {
  const _AccuracyRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Center(
      child: SizedBox(
        width: 148,
        height: 148,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: percent / 100),
          duration: const Duration(milliseconds: 900),
          curve: AppCurves.enter,
          builder: (context, value, _) => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: tokens.textAlpha(0.1),
                  valueColor: AlwaysStoppedAnimation(tokens.accent),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    AppL10n.of(context).reportAccuracy,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.textAlpha(0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeakLine extends StatelessWidget {
  const _WeakLine({required this.result, required this.language});

  final LineResult result;
  final String language;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final moves = SanNotation.localizeAll(
      [for (final node in result.line.line.nodes) node.san],
      language,
    ).take(8).join(' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.line.repertoireName,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moves,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textAlpha(0.55),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${(result.accuracy * 100).round()}%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: result.accuracy < 0.5 ? tokens.danger : tokens.warning,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
