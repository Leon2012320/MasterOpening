import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/lichess/domain/opening_stats.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Eine Eröffnungsfamilie mit Bilanz und Repertoire-Abgleich.
class OpeningStatRow extends StatelessWidget {
  const OpeningStatRow({required this.stat, super.key, this.onTap});

  final OpeningStat stat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SideDot(side: stat.side),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  stat.family,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.lichessScore((stat.score * 100).round()),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: _scoreColor(stat.score, tokens),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (stat.eco.isNotEmpty) ...[
                Text(
                  stat.eco,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.textAlpha(0.45),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                '${stat.games} · '
                '${l10n.lichessRecord(stat.wins, stat.draws, stat.losses)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.textAlpha(0.45),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              AppTag(
                stat.inRepertoire
                    ? l10n.lichessInRepertoire
                    : l10n.lichessMissing,
                variant: stat.inRepertoire
                    ? AppTagVariant.accent
                    : AppTagVariant.neutral,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Rot unter 45 %, grün ab 55 % — dazwischen bleibt es neutral, weil eine
  /// ausgeglichene Bilanz weder Lob noch Warnung verdient.
  static Color _scoreColor(double score, AppTokens tokens) {
    if (score >= 0.55) return tokens.success;
    if (score < 0.45) return tokens.danger;
    return tokens.text;
  }
}

/// Weiß oder Schwarz, als gefüllter beziehungsweise offener Punkt.
class _SideDot extends StatelessWidget {
  const _SideDot({required this.side});

  final Side side;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final white = side == Side.white;

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: white ? tokens.text : Colors.transparent,
        border: Border.all(color: tokens.textAlpha(white ? 0 : 0.6)),
      ),
    );
  }
}
