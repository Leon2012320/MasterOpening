import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/db/database_provider.dart';
import 'package:masteropening/core/router/app_routes.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/utils/greeting.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/gamification/domain/level_system.dart';
import 'package:masteropening/features/home/presentation/widgets/repertoire_card.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/features/repertoire/presentation/add_repertoire_sheet.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Der Spielerstand. Steht auf Null, bis die Gamification ihn füttert — die
/// Zeile existiert von Anfang an, damit der Kopf nicht später umgebaut werden
/// muss.
final userProfileProvider = StreamProvider<UserProfile>(
  (ref) => ref.watch(activityDaoProvider).watchProfile(),
);

/// Start-Tab: Begrüßung, Serie, Kennzahlen und das eigene Repertoire.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();

    final overviews = ref.watch(repertoireOverviewsProvider);
    final profile = ref.watch(userProfileProvider).value;
    final totalDue = ref.watch(totalDueProvider);

    final list = overviews.value ?? const [];
    final totalMoves = list.fold(0, (sum, o) => sum + o.row.nodeCount);

    return TabScaffold(
      floatingAction: list.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => showAddRepertoireSheet(context),
              tooltip: l10n.homeEmptyAction,
              child: const Icon(PhIcons.plus),
            ),
      slivers: [
        SliverBox(
          bottom: AppSpacing.screen,
          child: ScreenTitle(
            greetingFor(l10n, now),
            kicker: DateFormat('EEEE, d. MMMM', locale).format(now),
            trailing: _StreakPill(days: profile?.streakCurrent ?? 0),
          ),
        ),
        SliverBox(
          bottom: AppSpacing.screen,
          child: _LevelStrip(totalXp: profile?.totalXp ?? 0),
        ),
        SliverBox(
          bottom: AppSpacing.screen,
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '$totalDue',
                  label: l10n.homeDueToday,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  value: '$totalMoves',
                  label: l10n.statMovesTrained,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatTile(
                  value: '${list.length}',
                  label: l10n.statRepertoires,
                ),
              ),
            ],
          ),
        ),

        if (overviews.isLoading && list.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: AppSpacing.huge),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
          )
        else if (list.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: PhIcons.bookOpen,
              title: l10n.homeEmptyTitle,
              message: l10n.homeEmptyMessage,
              actionLabel: l10n.homeEmptyAction,
              onAction: () => showAddRepertoireSheet(context),
            ),
          )
        else ...[
          SliverBox(
            bottom: AppSpacing.md,
            child: SectionLabel(l10n.homeSectionRepertoire),
          ),
          SliverList.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              final overview = list[index];
              return ScreenPadding(
                child: RepertoireCard(
                  overview: overview,
                  onTrain: () => unawaited(
                    context.push(Routes.trainingSetup(overview.id)),
                  ),
                  onLearn: () =>
                      context.push(Routes.repertoireLearn(overview.id)),
                  onEdit: () =>
                      unawaited(_showRepertoireActions(context, ref, overview)),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  /// Die Aktionen eines Repertoires: umbenennen, Züge bearbeiten,
  /// Lernfortschritt zurücksetzen, löschen.
  Future<void> _showRepertoireActions(
    BuildContext context,
    WidgetRef ref,
    RepertoireOverview overview,
  ) {
    final l10n = AppL10n.of(context);

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(PhIcons.treeStructure),
              title: Text(l10n.repertoireEditTree),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(context.push(Routes.repertoireEdit(overview.id)));
              },
            ),
            ListTile(
              leading: const Icon(PhIcons.pencilSimple),
              title: Text(l10n.repertoireRename),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(_rename(context, ref, overview));
              },
            ),
            ListTile(
              leading: const Icon(PhIcons.arrowUUpLeft),
              title: Text(l10n.repertoireResetProgress),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final messenger = ScaffoldMessenger.of(context);
                await ref.read(progressDaoProvider).reset(overview.id);
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.repertoireResetProgressDone)),
                );
              },
            ),
            ListTile(
              leading: const Icon(PhIcons.trash),
              title: Text(l10n.repertoireDelete),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(_delete(context, ref, overview));
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    RepertoireOverview overview,
  ) async {
    final l10n = AppL10n.of(context);
    final controller = TextEditingController(text: overview.name);

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.repertoireRename),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty) return;
    await ref.read(repertoireDaoProvider).rename(overview.id, name);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RepertoireOverview overview,
  ) async {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(overview.name),
        content: Text(l10n.repertoireDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(repertoireRepositoryProvider).delete(overview.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.repertoireDeleted)));
  }
}

/// Die Levelleiste im Kopf: Rang, Füllstand und der Weg zur Statistik.
///
/// Sie ist die einzige Stelle, an der der Punktestand ständig sichtbar ist —
/// deshalb hängt hier auch der Einstieg in alles Weitere.
class _LevelStrip extends StatelessWidget {
  const _LevelStrip({required this.totalXp});

  final int totalXp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final progress = LevelSystem.progressFor(totalXp);

    return AppCard(
      onTap: () => unawaited(context.push(Routes.stats)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.homeLevel(progress.level),
                style: theme.textTheme.titleSmall,
              ),
              const Spacer(),
              Text(
                progress.isMaxLevel
                    ? l10n.statsMaxLevel
                    : l10n.statsXpToNext(
                        progress.xpRemaining,
                        progress.level + 1,
                      ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.textAlpha(0.5),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                PhIcons.caretRight,
                size: 13,
                color: tokens.textAlpha(0.4),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(value: progress.fraction),
        ],
      ),
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
    final active = days > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.allPill,
        border: Border.all(
          color: active ? tokens.accent : tokens.textAlpha(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhIcons.flame,
            size: 15,
            color: active ? tokens.accent : tokens.textAlpha(0.4),
          ),
          const SizedBox(width: 5),
          Text(
            '$days',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active ? tokens.accent : tokens.textAlpha(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
