import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/gamification/data/gamification_repository.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Zeigt die Belohnungen einer Einheit, falls es welche gibt.
///
/// Bewusst nach dem Report und nicht davor: erst das Ergebnis, dann das Lob.
/// Umgekehrt überdeckte die Feier die Zahlen, um die es eigentlich geht.
Future<void> showCelebration(
  BuildContext context,
  GamificationOutcome outcome,
) {
  if (!outcome.hasSomethingToCelebrate) return Future.value();

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: AppDurations.medium,
    pageBuilder: (context, _, _) => _CelebrationDialog(outcome: outcome),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppCurves.enter),
      child: child,
    ),
  );
}

/// Eine Zeile in der Feier.
@immutable
class _CelebrationItem {
  const _CelebrationItem({
    required this.icon,
    required this.kicker,
    required this.title,
    this.detail,
  });

  final IconData icon;

  /// Worum es sich handelt („Erfolg freigeschaltet").
  final String kicker;

  /// Der Name der Sache selbst.
  final String title;

  /// Der Punktegewinn, falls einer anfällt.
  final String? detail;
}

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog({required this.outcome});

  final GamificationOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    final items = <_CelebrationItem>[
      if (outcome.didLevelUp)
        _CelebrationItem(
          icon: PhIcons.sparkle,
          kicker: l10n.celebrationTitle,
          title: l10n.levelUp(outcome.levelAfter),
        ),
      for (final achievement in outcome.unlockedAchievements)
        _CelebrationItem(
          icon: PhIcons.trophy,
          kicker: l10n.achievementUnlocked,
          title: achievement.name(language),
          detail: l10n.reportXp(achievement.xpReward),
        ),
      for (final challenge in outcome.completedChallenges)
        _CelebrationItem(
          icon: PhIcons.target,
          kicker: l10n.challengeDone,
          title: challenge.template.text(language),
          detail: l10n.reportXp(challenge.template.xpReward),
        ),
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Der Lichtkranz: der Akzent als Kontur, wie überall sonst
                // auch — nur hier einmal groß.
                Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.surface,
                        border: Border.all(color: tokens.accent, width: 2),
                      ),
                      child: Icon(
                        PhIcons.sparkle,
                        size: 34,
                        color: tokens.accent,
                      ),
                    )
                    .animate()
                    .scaleXY(
                      begin: 0.4,
                      duration: AppDurations.celebration,
                      curve: AppCurves.emphasized,
                    )
                    .fadeIn(),

                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.celebrationTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.25),

                const SizedBox(height: AppSpacing.xl),
                for (var i = 0; i < items.length; i++)
                  Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ItemCard(item: items[i]),
                      )
                      .animate()
                      .fadeIn(delay: (300 + i * 120).ms)
                      .slideY(
                        begin: 0.3,
                        curve: AppCurves.enter,
                      ),

                const SizedBox(height: AppSpacing.md),
                AppButton.block(
                  label: l10n.celebrationContinue,
                  onPressed: () => Navigator.of(context).pop(),
                ).animate().fadeIn(delay: (400 + items.length * 120).ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final _CelebrationItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: tokens.accent),
          const SizedBox(width: AppSpacing.card),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.kicker.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.textAlpha(0.45),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(item.title, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          if (item.detail case final detail?) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              detail,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
