import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/gamification/data/gamification_providers.dart';
import 'package:masteropening/features/gamification/domain/achievement.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Lädt den Stand aller Erfolge.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(achievementsProvider).value;

    if (statuses == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppL10n.of(context).achievementsTitle)),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return AchievementsView(statuses: statuses);
  }
}

/// Alle Erfolge, nach Kategorien gruppiert.
///
/// Auch die noch verschlossenen stehen hier mit ihrer Bedingung — ein
/// Erfolgsschrank, den man nicht sehen kann, motiviert niemanden.
class AchievementsView extends StatelessWidget {
  const AchievementsView({required this.statuses, super.key});

  final List<AchievementStatus> statuses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final unlocked = statuses.where((s) => s.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.xl,
          bottom: AppSpacing.huge,
        ),
        children: [
          ScreenPadding(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhIcons.trophy, size: 20, color: tokens.accent),
                      const SizedBox(width: AppSpacing.card),
                      Expanded(
                        child: Text(
                          l10n.achievementsUnlockedOf(
                            unlocked,
                            statuses.length,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.card),
                  AppProgressBar(
                    value: statuses.isEmpty ? 0 : unlocked / statuses.length,
                    height: 6,
                  ),
                ],
              ),
            ),
          ),

          for (final category in AchievementCategory.values) ...[
            const SizedBox(height: AppSpacing.xxl),
            ScreenPadding(child: SectionLabel(_categoryLabel(l10n, category))),
            for (final status in statuses.where(
              (s) => s.achievement.category == category,
            ))
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  0,
                  AppSpacing.screen,
                  AppSpacing.md,
                ),
                child: _AchievementTile(status: status),
              ),
          ],
        ],
      ),
    );
  }

  static String _categoryLabel(AppL10n l10n, AchievementCategory category) {
    return switch (category) {
      AchievementCategory.volume => l10n.achievementCategoryVolume,
      AchievementCategory.accuracy => l10n.achievementCategoryAccuracy,
      AchievementCategory.streak => l10n.achievementCategoryStreak,
      AchievementCategory.repertoire => l10n.achievementCategoryRepertoire,
      AchievementCategory.modes => l10n.achievementCategoryModes,
      AchievementCategory.lichess => l10n.achievementCategoryLichess,
    };
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.status});

  final AchievementStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final open = status.isUnlocked;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Freigeschaltet: Akzentkontur mit Medaille. Verschlossen: eine
          // matte Fläche mit Schloss — sichtbar, aber ohne Aufmerksamkeit.
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: open ? Colors.transparent : tokens.surfaceSunken,
              border: open ? Border.all(color: tokens.accent) : null,
            ),
            child: Icon(
              open ? PhIcons.medal : PhIcons.lockSimple,
              size: 18,
              color: open ? tokens.accent : tokens.textAlpha(0.35),
            ),
          ),
          const SizedBox(width: AppSpacing.card),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.achievement.name(language),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: open ? tokens.text : tokens.textAlpha(0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  status.achievement.hint(language),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textAlpha(0.5),
                  ),
                ),
                if (!open) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppProgressBar(value: status.fraction),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${status.value} / ${status.achievement.threshold}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.textAlpha(0.45),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '+${status.achievement.xpReward}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: open ? tokens.accent : tokens.textAlpha(0.35),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
