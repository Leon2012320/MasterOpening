import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/gamification/domain/challenge.dart';

/// Eine Tages- oder Wochenaufgabe mit ihrem Fortschritt.
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({required this.challenge, super.key});

  final ChallengeInstance challenge;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final done = challenge.isComplete;

    return AppCard(
      child: Row(
        children: [
          Icon(
            done ? PhIcons.check : PhIcons.target,
            size: 18,
            color: done ? tokens.success : tokens.accent,
          ),
          const SizedBox(width: AppSpacing.card),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.template.text(language),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: done ? tokens.textAlpha(0.55) : tokens.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppProgressBar(
                  value: challenge.fraction,
                  color: done ? tokens.success : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.card),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${challenge.template.xpReward}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: done ? tokens.success : tokens.accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${challenge.progress}/${challenge.template.target}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.textAlpha(0.45),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
