import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/utils/greeting.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Start-Tab. Kopf, Kennzahlen und Repertoire-Liste.
///
/// Die Kennzahlen stehen in Phase 1 noch auf Null — sie werden mit der
/// Datenbank und der Gamification verdrahtet.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();

    return TabScaffold(
      slivers: [
        SliverBox(
          bottom: AppSpacing.screen,
          child: ScreenTitle(
            greetingFor(l10n, now),
            kicker: DateFormat('EEEE, d. MMMM', locale).format(now),
            trailing: const _StreakPill(days: 0),
          ),
        ),
        SliverBox(
          bottom: AppSpacing.screen,
          child: Row(
            children: [
              Expanded(
                child: StatTile(value: '—', label: l10n.statAccuracy),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(value: '0', label: l10n.statMovesTrained),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(value: '0', label: l10n.statRepertoires),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: EmptyState(
            icon: PhIcons.bookOpen,
            title: l10n.homeEmptyTitle,
            message: l10n.homeEmptyMessage,
            actionLabel: l10n.homeEmptyAction,
            onAction: () {},
          ),
        ),
      ],
    );
  }
}

/// Die Serien-Pille oben rechts: Flamme plus Anzahl, in Akzentkontur.
class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.allPill,
        border: Border.all(color: tokens.accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhIcons.flame,
            size: 15,
            color: tokens.accent,
          ),
          const SizedBox(width: 5),
          Text(
            '$days',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.accent),
          ),
        ],
      ),
    );
  }
}
