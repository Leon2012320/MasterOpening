import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/chess/san_notation.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/widgets/chess_board.dart';
import 'package:masteropening/core/widgets/fading_divider.dart';
import 'package:masteropening/features/library/domain/library_opening.dart';

/// Eine Zeile der Bibliotheksliste.
///
/// Das Symbol links ist ein echtes Miniaturbrett mit der Stellung nach den
/// ersten Zügen — es zeigt auf einen Blick, worum es geht, und braucht keine
/// gezeichneten Symbole je Eröffnung.
class OpeningRow extends ConsumerWidget {
  const OpeningRow({
    required this.opening,
    required this.onTap,
    this.isInRepertoire = false,
    super.key,
  });

  final LibraryOpeningSummary opening;
  final VoidCallback onTap;
  final bool isInRepertoire;

  static const _iconSize = 46.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final language = Localizations.localeOf(context).languageCode;

    final moves = SanNotation.localizeAll(
      opening.seedMoves,
      language,
    ).join(' ');

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.allSm,
                  child: BoardThumbnail(
                    fen: opening.iconFen,
                    size: _iconSize,
                    orientation: opening.side,
                    settings: BoardTheming.staticSettings(
                      settings,
                      isDark: tokens.isDark,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              opening.name(language),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            opening.eco,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tokens.textAlpha(0.45),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
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
                const SizedBox(width: AppSpacing.sm),
                _Trailing(opening: opening, isInRepertoire: isInRepertoire),
              ],
            ),
          ),
          const FadingDivider(),
        ],
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({required this.opening, required this.isInRepertoire});

  final LibraryOpeningSummary opening;
  final bool isInRepertoire;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _DifficultyDots(level: opening.difficulty),
        const SizedBox(height: AppSpacing.xxs),
        if (isInRepertoire)
          Icon(Icons.check_rounded, size: 15, color: tokens.success)
        else
          Text(
            '${opening.lineCount}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tokens.textAlpha(0.4),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}

/// Fünf Punkte, von denen so viele gefüllt sind, wie die Eröffnung
/// Schwierigkeitsgrade hat — kompakter als eine Zahl mit Beschriftung.
class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) const SizedBox(width: 3),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= level ? tokens.accent : tokens.textAlpha(0.15),
            ),
          ),
        ],
      ],
    );
  }
}
