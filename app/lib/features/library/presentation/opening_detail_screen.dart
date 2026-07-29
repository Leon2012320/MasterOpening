import 'package:dartchess/dartchess.dart' show Chess, Setup;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/san_notation.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/router/app_routes.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/chess_board.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/learn/domain/move_list_layout.dart';
import 'package:masteropening/features/learn/presentation/widgets/move_list_view.dart';
import 'package:masteropening/features/library/data/library_repository.dart';
import 'package:masteropening/features/library/domain/library_opening.dart';
import 'package:masteropening/features/library/presentation/library_l10n.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Die Detailseite einer Bibliothekseröffnung: Brett, Beschreibung, Pläne,
/// der vollständige Variantenbaum und die typischen Fehler.
class OpeningDetailScreen extends ConsumerWidget {
  const OpeningDetailScreen({required this.openingId, super.key});

  final String openingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(libraryOpeningProvider(openingId));

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: PhIcons.warning,
          title: l10n.libraryLoadError,
          message: '$error',
        ),
      ),
      data: (opening) => _Loaded(opening: opening),
    );
  }
}

class _Loaded extends ConsumerStatefulWidget {
  const _Loaded({required this.opening});

  final LibraryOpening opening;

  @override
  ConsumerState<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends ConsumerState<_Loaded> {
  /// Die Stellung, die das Brett gerade zeigt. Wechselt, wenn in der
  /// Zugliste oder bei den typischen Fehlern etwas angetippt wird.
  String? _shownFen;
  bool _adding = false;

  LibraryOpeningSummary get _summary => widget.opening.summary;

  String get _fen => _shownFen ?? _summary.iconFen;

  Future<void> _addToRepertoire() async {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final language = Localizations.localeOf(context).languageCode;

    setState(() => _adding = true);
    try {
      final repository = ref.read(repertoireRepositoryProvider);
      final tree = PgnIo.parse(widget.opening.pgn).tree;

      await repository.create(
        name: _summary.name(language),
        side: _summary.side,
        tree: tree,
        source: RepertoireSource.library,
        sourceRef: _summary.id,
        ecoCodes: _summary.eco,
      );

      messenger.showSnackBar(
        SnackBar(content: Text(l10n.libraryAdded(_summary.name(language)))),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final settings = ref.watch(settingsProvider);

    final existing = ref
        .watch(repertoiresProvider)
        .maybeWhen(
          data: (rows) =>
              rows.where((r) => r.sourceRef == _summary.id).firstOrNull,
          orElse: () => null,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_summary.name(language), overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.huge),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth.clamp(
                    0.0,
                    MediaQuery.sizeOf(context).height * 0.42,
                  );
                  return AppChessboard(
                    size: size,
                    position: Chess.fromSetup(Setup.parseFen(_fen)),
                    orientation: _summary.side,
                    settings: BoardTheming.settings(
                      settings,
                      isDark: tokens.isDark,
                      showValidMoves: false,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          ScreenPadding(child: _Header(summary: _summary)),
          const SizedBox(height: AppSpacing.xl),

          ScreenPadding(
            child: Text(
              _summary.summary(language),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textAlpha(0.8),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          ScreenPadding(
            child: existing != null
                ? AppButton.block(
                    label: l10n.libraryAlreadyAdded,
                    variant: AppButtonVariant.secondary,
                    icon: PhIcons.check,
                    onPressed: () =>
                        context.push(Routes.repertoireLearn(existing.id)),
                  )
                : AppButton.block(
                    label: l10n.libraryAddToRepertoire,
                    icon: PhIcons.plus,
                    busy: _adding,
                    onPressed: _addToRepertoire,
                  ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          ScreenPadding(child: SectionLabel(l10n.librarySectionPlans)),
          const SizedBox(height: AppSpacing.md),
          for (final plan in widget.opening.plans(language))
            _PlanRow(text: plan),

          const SizedBox(height: AppSpacing.xxl),
          ScreenPadding(child: SectionLabel(l10n.librarySectionMistakes)),
          const SizedBox(height: AppSpacing.md),
          for (final mistake in widget.opening.mistakes)
            _MistakeCard(
              mistake: mistake,
              language: language,
              onShow: (fen) => setState(() => _shownFen = fen),
            ),

          const SizedBox(height: AppSpacing.xxl),
          ScreenPadding(child: SectionLabel(l10n.librarySectionLines)),
          const SizedBox(height: AppSpacing.sm),
          _Lines(
            pgn: widget.opening.pgn,
            language: language,
            onSelect: (fen) => setState(() => _shownFen = fen),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.summary});

  final LibraryOpeningSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppTag(summary.eco, variant: AppTagVariant.accent),
            AppTag(
              SanNotation.sideLabel(summary.side, language),
            ),
            for (final tag in summary.tags)
              AppTag(l10n.openingTag(tag), variant: AppTagVariant.outline),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.libraryMovesAndLines(
                  summary.nodeCount,
                  summary.lineCount,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textAlpha(0.55),
                ),
              ),
            ),
            Text(
              '${l10n.libraryDifficulty}: '
              '${l10n.openingDifficulty(summary.difficulty)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textAlpha(0.55),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Akzent als kurze Linie statt eines Aufzählungspunkts.
          Container(
            width: 2,
            height: 18,
            margin: const EdgeInsets.only(top: 3, right: AppSpacing.md),
            color: tokens.accent,
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textAlpha(0.85),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({
    required this.mistake,
    required this.language,
    required this.onShow,
  });

  final OpeningMistake mistake;
  final String language;
  final void Function(String fen) onShow;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final line = PgnIo.parse(mistake.pgn).tree.lines().firstOrNull;
    final moves = line == null
        ? const <String>[]
        : SanNotation.localizeAll(
            [for (final node in line.nodes) node.san],
            language,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.lg,
      ),
      child: AppCard(
        onTap: line == null ? null : () => onShow(line.last.fenAfter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhIcons.warning, size: 15, color: tokens.danger),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    // Der letzte Zug der Folge ist der Fehler.
                    moves.isEmpty ? '' : moves.last,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.danger,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              moves.length <= 1
                  ? ''
                  : _numbered(moves.sublist(0, moves.length - 1)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textAlpha(0.5),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              mistake.why(language),
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textAlpha(0.8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Setzt Zugnummern vor die weissen Züge: „1. e4 e5 2. Sf3".
  static String _numbered(List<String> moves) {
    final buffer = StringBuffer();
    for (var i = 0; i < moves.length; i++) {
      if (i.isEven) buffer.write('${i ~/ 2 + 1}. ');
      buffer
        ..write(moves[i])
        ..write(' ');
    }
    return buffer.toString().trimRight();
  }
}

class _Lines extends StatelessWidget {
  const _Lines({
    required this.pgn,
    required this.language,
    required this.onSelect,
  });

  final String pgn;
  final String language;
  final void Function(String fen) onSelect;

  @override
  Widget build(BuildContext context) {
    final tree = PgnIo.parse(pgn).tree;

    return ConstrainedBox(
      // Der Baum ist lang; die Detailseite scrollt ohnehin, deshalb bekommt
      // die Zugliste eine feste Höhe mit eigenem Scrollbereich.
      constraints: const BoxConstraints(maxHeight: 320),
      child: MoveListView(
        rows: MoveListLayout.build(tree),
        languageCode: language,
        onSelect: (node) => onSelect(node.fenAfter),
      ),
    );
  }
}
