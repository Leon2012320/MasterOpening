import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/router/app_routes.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/lichess/data/lichess_providers.dart';
import 'package:masteropening/features/lichess/domain/opening_stats.dart';
import 'package:masteropening/features/lichess/presentation/widgets/game_row.dart';
import 'package:masteropening/features/lichess/presentation/widgets/lichess_profile_card.dart';
import 'package:masteropening/features/lichess/presentation/widgets/opening_stat_row.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Lichess-Tab: Konto, Partie-Import und die Eröffnungen, die wirklich
/// gespielt werden.
class LichessScreen extends ConsumerWidget {
  const LichessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lichessProvider).value ?? const LichessState();
    final controller = ref.read(lichessProvider.notifier);

    return LichessView(
      state: state,
      games: ref.watch(lichessGamesProvider).value ?? const [],
      openings: ref.watch(openingStatsProvider),
      onConnect: controller.connect,
      onImport: controller.importGames,
      onDisconnect: () => _confirmDisconnect(context, ref),
      onRepair: () => context.push(Routes.lichessGaps),
      onAntiPrep: () => context.push(Routes.antiPrep),
      onStyle: () => context.push(Routes.styleAdvice),
    );
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.lichessDisconnectConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.lichessDisconnect),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(lichessProvider.notifier).disconnect();
    messenger.showSnackBar(SnackBar(content: Text(l10n.lichessDisconnected)));
  }
}

/// Der Tab ohne Datenzugriff — so lässt er sich in jedem Zustand prüfen.
class LichessView extends StatelessWidget {
  const LichessView({
    required this.state,
    required this.games,
    required this.openings,
    super.key,
    this.onConnect,
    this.onImport,
    this.onDisconnect,
    this.onRepair,
    this.onAntiPrep,
    this.onStyle,
  });

  final LichessState state;
  final List<LichessGame> games;
  final List<OpeningStat> openings;

  final Future<void> Function()? onConnect;
  final Future<void> Function()? onImport;
  final Future<void> Function()? onDisconnect;
  final Future<void> Function()? onRepair;
  final Future<void> Function()? onAntiPrep;
  final Future<void> Function()? onStyle;

  /// Mehr als das passt nicht auf einen Tab, ohne zur Liste zu werden.
  static const _recentGames = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return TabScaffold(
      slivers: [
        SliverBox(
          bottom: AppSpacing.xl,
          child: ScreenTitle(
            l10n.tabLichess,
            trailing: state.isConnected
                ? IconButton(
                    icon: const Icon(PhIcons.signOut),
                    tooltip: l10n.lichessDisconnect,
                    onPressed: onDisconnect == null
                        ? null
                        : () => unawaited(onDisconnect!()),
                  )
                : null,
          ),
        ),

        if (state.error case final error?)
          SliverBox(
            bottom: AppSpacing.xl,
            child: _ErrorNote(message: l10n.lichessFailed(error)),
          ),

        if (!state.isConnected) ...[
          SliverToBoxAdapter(
            child: EmptyState(
              icon: PhIcons.userCircle,
              title: l10n.lichessNotConnectedTitle,
              message: l10n.lichessNotConnectedMessage,
            ),
          ),
          // Der Knopf steht ausserhalb des Leerzustands, damit er beim
          // Verbinden sichtbar bleiben und einen Spinner tragen kann.
          SliverBox(
            child: AppButton.block(
              label: state.status == LichessStatus.connecting
                  ? l10n.lichessConnecting
                  : l10n.lichessConnect,
              icon: PhIcons.signIn,
              busy: state.status == LichessStatus.connecting,
              onPressed: state.isBusy || onConnect == null
                  ? null
                  : () => unawaited(onConnect!()),
            ),
          ),
          SliverBox(
            top: AppSpacing.md,
            child: Text(
              l10n.lichessScopeHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.tokens.textAlpha(0.45),
              ),
            ),
          ),
        ] else ...[
          if (state.account case final account?)
            SliverBox(
              bottom: AppSpacing.xl,
              child: LichessProfileCard(account: account),
            ),

          SliverBox(
            bottom: AppSpacing.xl,
            child: _ImportRow(
              state: state,
              storedGames: games.length,
              onImport: onImport,
            ),
          ),

          SliverBox(
            bottom: AppSpacing.xxl,
            child: Column(
              children: [
                if (games.isNotEmpty) ...[
                  AppButton.block(
                    label: l10n.lichessRepairAction,
                    icon: PhIcons.wrench,
                    variant: AppButtonVariant.secondary,
                    onPressed: onRepair == null
                        ? null
                        : () => unawaited(onRepair!()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.block(
                    label: l10n.styleAction,
                    icon: PhIcons.compass,
                    variant: AppButtonVariant.secondary,
                    onPressed: onStyle == null
                        ? null
                        : () => unawaited(onStyle!()),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                // Ausspähen geht auch ohne eigene Partien — der Bericht
                // handelt schliesslich vom Gegner.
                AppButton.block(
                  label: l10n.antiPrepAction,
                  icon: PhIcons.crosshair,
                  variant: AppButtonVariant.secondary,
                  onPressed: onAntiPrep == null
                      ? null
                      : () => unawaited(onAntiPrep!()),
                ),
              ],
            ),
          ),

          if (games.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: PhIcons.chartBar,
                title: l10n.lichessNoGamesTitle,
                message: l10n.lichessNoGamesMessage,
                compact: true,
              ),
            )
          else ...[
            SliverBox(
              bottom: AppSpacing.md,
              child: SectionLabel(l10n.lichessSectionOpenings),
            ),
            if (openings.isEmpty)
              SliverBox(
                bottom: AppSpacing.xl,
                child: Text(
                  l10n.lichessNoOpeningsMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.tokens.textAlpha(0.5),
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: openings.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) => ScreenPadding(
                  child: OpeningStatRow(stat: openings[index]),
                ),
              ),

            SliverBox(
              top: AppSpacing.xxl,
              bottom: AppSpacing.md,
              child: SectionLabel(l10n.lichessSectionGames),
            ),
            SliverList.separated(
              itemCount: games.length.clamp(0, _recentGames),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  ScreenPadding(child: GameRow(game: games[index])),
            ),
          ],
        ],
      ],
    );
  }
}

/// Importknopf mit dem Stand daneben.
class _ImportRow extends StatelessWidget {
  const _ImportRow({
    required this.state,
    required this.storedGames,
    this.onImport,
  });

  final LichessState state;
  final int storedGames;
  final Future<void> Function()? onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final importing = state.status == LichessStatus.importing;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.lichessGamesStored(storedGames),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (state.lastImport case final result?) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.lichessImported(result.imported),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: result.isEmpty
                        ? tokens.textAlpha(0.5)
                        : tokens.success,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AppButton(
          label: importing ? l10n.lichessImporting : l10n.lichessImport,
          icon: PhIcons.arrowsClockwise,
          busy: importing,
          onPressed: state.isBusy || onImport == null
              ? null
              : () => unawaited(onImport!()),
        ),
      ],
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AppCard(
      child: Row(
        children: [
          Icon(PhIcons.warning, size: 18, color: tokens.danger),
          const SizedBox(width: AppSpacing.card),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
