import 'package:chessground/chessground.dart' show PlayerSide;
import 'package:dartchess/dartchess.dart' show Move;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/chess/san_notation.dart';
import 'package:masteropening/core/db/app_database.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/chess_board.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/learn/domain/move_list_layout.dart';
import 'package:masteropening/features/learn/domain/study_state.dart';
import 'package:masteropening/features/learn/presentation/widgets/move_list_view.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Züge eines Repertoires bearbeiten.
///
/// Ergänzt wird durch Ziehen auf dem Brett: jeder legale Zug, der noch nicht
/// im Baum steht, kommt an der aktuellen Stelle hinzu. Das ist derselbe
/// Handgriff wie im Lern-Modus, nur dass er hier etwas verändert.
class RepertoireEditScreen extends ConsumerWidget {
  const RepertoireEditScreen({required this.repertoireId, super.key});

  final int repertoireId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(repertoireTreeProvider(repertoireId));

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.treeEditTitle)),
        body: EmptyState(
          icon: PhIcons.warning,
          title: l10n.learnLoadError,
          message: '$error',
        ),
      ),
      data: (loaded) => loaded == null
          ? Scaffold(
              appBar: AppBar(title: Text(l10n.treeEditTitle)),
              body: EmptyState(
                icon: PhIcons.warning,
                title: l10n.learnLoadError,
              ),
            )
          : _Editor(row: loaded.row, tree: loaded.tree),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.row, required this.tree});

  final Repertoire row;
  final RepertoireTree tree;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  StudyState? _state;
  bool _saving = false;

  StudyState get _study => _state!;

  void _sync() {
    final current = _state;
    if (current == null) {
      _state = StudyState.atStart(widget.tree, orientation: widget.row.side);
    } else if (current.tree != widget.tree) {
      _state = current.withTree(widget.tree);
    }
  }

  /// Schreibt den Baum und behält dabei die Stelle, an der gerade gearbeitet
  /// wird. Der Provider liefert danach die neue Fassung nach; `withTree`
  /// findet den Weg darin wieder.
  Future<void> _save(RepertoireTree next, {String? toast}) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _saving = true;
      _state = _study.withTree(next);
    });

    try {
      await ref.read(repertoireRepositoryProvider).saveTree(widget.row, next);
      if (toast != null) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(toast)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onMove(Move move) async {
    final l10n = AppL10n.of(context);

    // Steht der Zug schon im Baum, wird nur navigiert — nichts hinzugefügt.
    final existing = _study.playMove(move);
    if (existing != null) {
      setState(() => _state = existing);
      return;
    }

    final position = _study.position;
    if (!position.isLegal(move)) return;

    final (_, san) = position.makeSan(move);
    final next = _study.tree.withSanLine([..._study.sanPath, san]);

    await _save(next, toast: l10n.treeEditAdded);
    // Nach dem Ergänzen auf den neuen Zug stellen, damit man direkt
    // weiterziehen kann.
    setState(() => _state = _study.playMove(move) ?? _study);
  }

  Future<void> _deleteCurrent() async {
    final l10n = AppL10n.of(context);
    final node = _study.current;
    if (node == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.treeEditDeleteConfirm),
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

    setState(() => _state = _study.back());
    await _save(_study.tree.withoutNode(node.pathHash));
  }

  Future<void> _promoteCurrent() async {
    final node = _study.current;
    if (node == null) return;
    await _save(_study.tree.withMainline(node.pathHash));
  }

  Future<void> _editComment() async {
    final l10n = AppL10n.of(context);
    final node = _study.current;
    if (node == null) return;

    final controller = TextEditingController(text: node.comment ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.treeEditComment),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(hintText: l10n.treeEditCommentHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;

    await _save(_study.tree.withComment(node.pathHash, result));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final settings = ref.watch(settingsProvider);
    final language = Localizations.localeOf(context).languageCode;

    _sync();
    final state = _study;
    final node = state.current;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.row.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(PhIcons.arrowsClockwise),
            tooltip: l10n.learnFlipBoard,
            onPressed: () => setState(() => _state = state.flipped()),
          ),
        ],
        bottom: _saving
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth.clamp(
                0.0,
                MediaQuery.sizeOf(context).height * 0.46,
              );
              return Center(
                child: AppChessboard(
                  size: size,
                  position: state.position,
                  orientation: state.orientation,
                  lastMove: state.lastMove,
                  interactableSide: PlayerSide.both,
                  settings: BoardTheming.settings(
                    settings,
                    isDark: tokens.isDark,
                  ),
                  onMove: _onMove,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.md,
            ),
            child: Text(
              node == null
                  ? l10n.treeEditHint
                  : '${SanNotation.localize(node.san, language)}'
                        '${node.comment == null ? '' : ' — ${node.comment}'}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tokens.textAlpha(0.65),
              ),
            ),
          ),
          _Actions(
            enabled: node != null && !_saving,
            onBack: state.canGoBack
                ? () => setState(() => _state = state.back())
                : null,
            onDelete: _deleteCurrent,
            onPromote: _promoteCurrent,
            onComment: _editComment,
          ),
          const FadingDivider(),
          Expanded(
            child: MoveListView(
              rows: MoveListLayout.build(widget.tree),
              languageCode: language,
              currentPathHash: node?.pathHash,
              onSelect: (selected) =>
                  setState(() => _state = state.goTo(selected.pathHash)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.enabled,
    required this.onBack,
    required this.onDelete,
    required this.onPromote,
    required this.onComment,
  });

  final bool enabled;
  final VoidCallback? onBack;
  final VoidCallback onDelete;
  final VoidCallback onPromote;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(PhIcons.arrowUUpLeft),
            tooltip: l10n.commonBack,
            onPressed: onBack,
          ),
          IconButton(
            icon: const Icon(PhIcons.arrowLineUp),
            tooltip: l10n.treeEditPromote,
            onPressed: enabled ? onPromote : null,
          ),
          IconButton(
            icon: const Icon(PhIcons.chatText),
            tooltip: l10n.treeEditComment,
            onPressed: enabled ? onComment : null,
          ),
          IconButton(
            icon: const Icon(PhIcons.trash),
            tooltip: l10n.treeEditDelete,
            onPressed: enabled ? onDelete : null,
          ),
        ],
      ),
    );
  }
}
