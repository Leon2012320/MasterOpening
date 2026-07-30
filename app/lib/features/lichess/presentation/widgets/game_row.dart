import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';

/// Eine importierte Partie als Zeile: Ausgang, Eröffnung, Gegner, Datum.
class GameRow extends StatelessWidget {
  const GameRow({required this.game, super.key, this.onTap});

  final LichessGame game;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final (color, letter) = switch (game.outcome) {
      GameOutcome.win => (tokens.success, 'S'),
      GameOutcome.draw => (tokens.textAlpha(0.5), '='),
      GameOutcome.loss => (tokens.danger, 'N'),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            // Ein Balken statt eines Symbols: drei Ausgänge, drei Farben,
            // auf einen Blick als Muster lesbar.
            Container(
              width: 3,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.allXs,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.openingName ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    [
                      if (game.side == Side.white) '⬦' else '⬥',
                      ?game.opponentName,
                      if (game.opponentRating case final rating?) '$rating',
                    ].join(' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textAlpha(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  letter,
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
                const SizedBox(height: 1),
                Text(
                  DateFormat.MMMd(locale).format(game.playedAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.textAlpha(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
