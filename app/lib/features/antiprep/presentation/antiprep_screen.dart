import 'dart:async';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/chess/san_notation.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/antiprep/data/antiprep_providers.dart';
import 'package:masteropening/features/antiprep/domain/prep_sheet.dart';
import 'package:masteropening/features/antiprep/domain/scout_report.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/features/training/presentation/training_screen.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Ein Repertoire samt Baum, gegen das die Folgen des Gegners geprüft werden.
typedef PrepRepertoire = ({
  int id,
  String name,
  Side side,
  RepertoireTree tree,
});

/// Lädt den Bericht und reicht ihn an [AntiPrepView] weiter.
class AntiPrepScreen extends ConsumerStatefulWidget {
  const AntiPrepScreen({super.key});

  @override
  ConsumerState<AntiPrepScreen> createState() => _AntiPrepScreenState();
}

class _AntiPrepScreenState extends ConsumerState<AntiPrepScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(antiPrepProvider);
    final notifier = ref.read(antiPrepProvider.notifier);

    final overviews = ref.watch(repertoireOverviewsProvider).value ?? const [];

    return AntiPrepView(
      state: state,
      controller: _controller,
      repertoires: [
        for (final overview in overviews)
          (
            id: overview.id,
            name: overview.name,
            side: overview.row.side,
            tree: overview.tree,
          ),
      ],
      onChanged: notifier.setUsername,
      onSearch: notifier.load,
      onRefresh: () => notifier.load(refresh: true),
      onDrill: (repertoireId, pathHash) => unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => TrainingScreen(
              mode: TrainingMode.variation,
              repertoireId: repertoireId,
              pathHash: pathHash,
            ),
          ),
        ),
      ),
    );
  }
}

/// Das Vorbereitungsblatt zu einem Gegner.
class AntiPrepView extends StatefulWidget {
  const AntiPrepView({
    required this.state,
    required this.repertoires,
    super.key,
    this.controller,
    this.onChanged,
    this.onSearch,
    this.onRefresh,
    this.onDrill,
  });

  final AntiPrepState state;
  final List<PrepRepertoire> repertoires;

  final TextEditingController? controller;
  final void Function(String value)? onChanged;
  final Future<void> Function()? onSearch;
  final Future<void> Function()? onRefresh;
  final void Function(int repertoireId, String pathHash)? onDrill;

  @override
  State<AntiPrepView> createState() => _AntiPrepViewState();
}

class _AntiPrepViewState extends State<AntiPrepView> {
  Side _ownSide = Side.white;

  @override
  void initState() {
    super.initState();
    // Mit der Farbe beginnen, für die es überhaupt eine Vorbereitung gibt.
    final sides = widget.repertoires.map((r) => r.side).toSet();
    if (!sides.contains(Side.white) && sides.contains(Side.black)) {
      _ownSide = Side.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final state = widget.state;
    final report = state.report;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.antiPrepTitle)),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.xl,
          bottom: AppSpacing.huge,
        ),
        children: [
          ScreenPadding(
            child: Text(
              l10n.antiPrepHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.textAlpha(0.55),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.card),
          ScreenPadding(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              onSubmitted: (_) => unawaited(widget.onSearch?.call()),
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.antiPrepUsername,
                prefixIcon: const Icon(PhIcons.userCircle, size: 18),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ScreenPadding(
            child: AppButton.block(
              label: state.running
                  ? l10n.antiPrepSearching
                  : l10n.antiPrepSearch,
              icon: PhIcons.magnifyingGlass,
              busy: state.running,
              onPressed: state.running || widget.onSearch == null
                  ? null
                  : () => unawaited(widget.onSearch!()),
            ),
          ),

          if (state.error case final error?) ...[
            const SizedBox(height: AppSpacing.md),
            ScreenPadding(
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.danger,
                ),
              ),
            ),
          ],

          if (report != null) ..._reportSections(context, report),
        ],
      ),
    );
  }

  List<Widget> _reportSections(BuildContext context, ScoutReport report) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final locale = Localizations.localeOf(context).toLanguageTag();

    if (report.gamesAnalysed == 0) {
      return [
        const SizedBox(height: AppSpacing.xxl),
        EmptyState(
          icon: PhIcons.magnifyingGlass,
          title: l10n.antiPrepEmptyTitle,
          message: l10n.antiPrepEmptyMessage,
          compact: true,
        ),
      ];
    }

    final tree = report.against(_ownSide);
    final own = widget.repertoires.where((r) => r.side == _ownSide).toList();
    final repertoire = own.isEmpty ? null : own.first;

    final likely = PrepSheet.mostLikely(
      tree,
      repertoire: repertoire?.tree,
    );
    final weak = PrepSheet.weakest(tree, repertoire: repertoire?.tree);
    final uncovered = repertoire == null
        ? const <PrepLine>[]
        : PrepSheet.uncovered(tree, repertoire: repertoire.tree);

    return [
      const SizedBox(height: AppSpacing.xl),
      ScreenPadding(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.username,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    l10n.antiPrepBasis(
                      report.gamesAnalysed,
                      DateFormat.yMMMd(locale).format(report.analysedAt),
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tokens.textAlpha(0.45),
                    ),
                  ),
                ],
              ),
            ),
            // Ein gespeicherter Bericht altert; das Nachladen bleibt aber
            // eine bewusste Entscheidung, weil es dauert.
            AppButton(
              label: l10n.antiPrepRefresh,
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.small,
              onPressed: widget.state.running || widget.onRefresh == null
                  ? null
                  : () => unawaited(widget.onRefresh!()),
            ),
          ],
        ),
      ),

      const SizedBox(height: AppSpacing.card),
      ScreenPadding(
        child: AppSegmentedControl<Side>(
          value: _ownSide,
          onChanged: (side) => setState(() => _ownSide = side),
          segments: [
            AppSegment(value: Side.white, label: l10n.antiPrepAsWhite),
            AppSegment(value: Side.black, label: l10n.antiPrepAsBlack),
          ],
        ),
      ),

      ..._section(
        context,
        title: l10n.antiPrepSectionLikely,
        lines: likely,
        repertoire: repertoire,
      ),
      ..._section(
        context,
        title: l10n.antiPrepSectionWeak,
        lines: weak,
        repertoire: repertoire,
      ),
      ..._section(
        context,
        title: l10n.antiPrepSectionUncovered,
        lines: uncovered,
        repertoire: repertoire,
      ),
    ];
  }

  List<Widget> _section(
    BuildContext context, {
    required String title,
    required List<PrepLine> lines,
    required PrepRepertoire? repertoire,
  }) {
    if (lines.isEmpty) return const [];

    return [
      const SizedBox(height: AppSpacing.xxl),
      ScreenPadding(child: SectionLabel(title)),
      for (final line in lines)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          child: _PrepLineCard(
            line: line,
            totalGames: widget.state.report?.against(_ownSide).games ?? 0,
            repertoire: repertoire,
            onDrill: widget.onDrill,
          ),
        ),
    ];
  }
}

class _PrepLineCard extends StatelessWidget {
  const _PrepLineCard({
    required this.line,
    required this.totalGames,
    this.repertoire,
    this.onDrill,
  });

  final PrepLine line;
  final int totalGames;
  final PrepRepertoire? repertoire;
  final void Function(int repertoireId, String pathHash)? onDrill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    final share = totalGames == 0 ? 0 : (line.games / totalGames * 100).round();

    final target = repertoire == null
        ? null
        : PrepSheet.drillTarget(repertoire!.tree, line);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  SanNotation.localizeAll(
                    [for (final node in line.moves) node.san],
                    language,
                  ).join(' '),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (line.isCovered)
                AppTag(l10n.antiPrepCovered, variant: AppTagVariant.accent),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              l10n.antiPrepGames(line.games),
              l10n.antiPrepShare(share),
              l10n.antiPrepHisScore((line.theirScore * 100).round()),
            ].join(' · '),
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.textAlpha(0.5),
            ),
          ),
          if (target != null && onDrill != null) ...[
            const SizedBox(height: AppSpacing.card),
            AppButton(
              label: l10n.antiPrepDrill,
              size: AppButtonSize.small,
              onPressed: () => onDrill!(repertoire!.id, target),
            ),
          ],
        ],
      ),
    );
  }
}
