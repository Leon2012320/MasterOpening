import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/lichess/domain/lichess_account.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Das verbundene Konto: Name, Titel, Partienzahl und die Wertungen.
class LichessProfileCard extends StatelessWidget {
  const LichessProfileCard({required this.account, super.key});

  final LichessAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Kein Netzabruf für ein Bild: der Anfangsbuchstabe in
              // Akzentkontur ist schneller da und passt zum Rest.
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.accent),
                ),
                child: Text(
                  account.username.characters.first.toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.card),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (account.title case final title?) ...[
                          AppTag(title, variant: AppTagVariant.accent),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Flexible(
                          child: Text(
                            account.username,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (account.patron) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            PhIcons.crown,
                            size: 14,
                            color: tokens.textAlpha(0.5),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      [
                        l10n.lichessProfileGames(account.gameCount),
                        if (account.createdAt case final created?)
                          l10n.lichessMemberSince(
                            DateFormat.yMMM(locale).format(created),
                          ),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textAlpha(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (account.ratedPerfs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.card),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final perf in account.ratedPerfs)
                  AppTag(
                    '${_perfLabel(perf.key)} ${perf.rating}'
                    '${perf.provisional ? '?' : ''}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Die Zeitkontrollen heißen auf Lichess in jeder Sprache gleich; nur die
  /// Großschreibung ist unsere Sache.
  static String _perfLabel(String key) =>
      key[0].toUpperCase() + key.substring(1);
}
