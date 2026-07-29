import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/chess/san_notation.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/chess_board.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Eine Repertoire-Kachel auf der Startseite: Brettvorschau, Name, Umfang und
/// die drei Wege hinein — trainieren, lernen, bearbeiten.
class RepertoireCard extends ConsumerWidget {
  const RepertoireCard({
    required this.overview,
    required this.onTrain,
    required this.onLearn,
    required this.onEdit,
    super.key,
  });

  final RepertoireOverview overview;
  final VoidCallback onTrain;
  final VoidCallback onLearn;
  final VoidCallback onEdit;

  static const _previewSize = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final language = Localizations.localeOf(context).languageCode;

    final isDue = overview.dueCount > 0;

    return AppCard(
      onTap: onLearn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadius.allSm,
                child: BoardThumbnail(
                  fen: overview.previewFen,
                  size: _previewSize,
                  orientation: overview.row.side,
                  settings: BoardTheming.staticSettings(
                    settings,
                    isDark: tokens.isDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.card),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overview.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${SanNotation.sideLabel(overview.row.side, language)}'
                      ' · ${l10n.homeMovesTotal(overview.row.nodeCount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textAlpha(0.55),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTag(
                      l10n.homeDueMoves(overview.dueCount),
                      variant: isDue
                          ? AppTagVariant.accent
                          : AppTagVariant.neutral,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.card),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.actionTrain,
                  icon: PhIcons.play,
                  expand: true,
                  onPressed: onTrain,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: l10n.actionLearn,
                  icon: PhIcons.bookOpen,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  onPressed: onLearn,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(PhIcons.dotsThree, size: 20),
                tooltip: l10n.actionEdit,
                onPressed: onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
