import 'dart:async';

import 'package:flutter/material.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/chess/san_notation.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/features/learn/domain/move_list_layout.dart';

/// Die Zugliste einer Studie: Hauptvariante durchlaufend, Nebenvarianten
/// eingerückt darunter. Der aktuelle Zug ist hervorgehoben und wird beim
/// Navigieren in den sichtbaren Bereich geholt.
class MoveListView extends StatefulWidget {
  const MoveListView({
    required this.rows,
    required this.languageCode,
    required this.onSelect,
    this.currentPathHash,
    super.key,
  });

  final List<MoveRow> rows;
  final String languageCode;
  final String? currentPathHash;
  final void Function(RepertoireNode node) onSelect;

  @override
  State<MoveListView> createState() => _MoveListViewState();
}

class _MoveListViewState extends State<MoveListView> {
  final GlobalKey<State<StatefulWidget>> _currentKey = GlobalKey();

  @override
  void didUpdateWidget(MoveListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPathHash != widget.currentPathHash) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealCurrent());
    }
  }

  void _revealCurrent() {
    final context = _currentKey.currentContext;
    if (context == null || !mounted) return;
    unawaited(
      Scrollable.ensureVisible(
        context,
        duration: AppDurations.fast,
        alignment: 0.5,
        curve: AppCurves.enter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.sm,
      ),
      itemCount: widget.rows.length,
      itemBuilder: (context, index) => _Row(
        row: widget.rows[index],
        languageCode: widget.languageCode,
        currentPathHash: widget.currentPathHash,
        currentKey: _currentKey,
        onSelect: widget.onSelect,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.row,
    required this.languageCode,
    required this.currentPathHash,
    required this.currentKey,
    required this.onSelect,
  });

  final MoveRow row;
  final String languageCode;
  final String? currentPathHash;
  final GlobalKey currentKey;
  final void Function(RepertoireNode node) onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isVariation = row.depth > 0;

    return Padding(
      padding: EdgeInsets.only(
        left: row.depth * AppSpacing.lg,
        top: AppSpacing.xxs / 2,
        bottom: AppSpacing.xxs / 2,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Nebenvarianten bekommen eine Akzentlinie an der Kante statt einer
          // Hintergrundfläche — Akzent als Linie, wie im Entwurf.
          border: isVariation
              ? Border(
                  left: BorderSide(
                    color: tokens.accent.withValues(alpha: 0.35),
                    width: 2,
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.only(left: isVariation ? AppSpacing.sm : 0),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final span in row.spans)
                _span(context, span, isVariation: isVariation),
            ],
          ),
        ),
      ),
    );
  }

  Widget _span(
    BuildContext context,
    MoveSpan span, {
    required bool isVariation,
  }) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    switch (span) {
      case MoveNumberSpan(:final label):
        return Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textAlpha(0.45),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );

      case CommentSpan(:final text):
        return Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textAlpha(0.6),
            fontStyle: FontStyle.italic,
          ),
        );

      case MoveNodeSpan(:final node):
        final isCurrent = node.pathHash == currentPathHash;
        return _MoveChip(
          key: isCurrent ? currentKey : null,
          label: SanNotation.localize(node.san, languageCode),
          nags: node.nags,
          isCurrent: isCurrent,
          isVariation: isVariation,
          onTap: () => onSelect(node),
        );
    }
  }
}

class _MoveChip extends StatelessWidget {
  const _MoveChip({
    required this.label,
    required this.nags,
    required this.isCurrent,
    required this.isVariation,
    required this.onTap,
    super.key,
  });

  final String label;
  final List<int> nags;
  final bool isCurrent;
  final bool isVariation;
  final VoidCallback onTap;

  /// Die gebräuchlichen Annotationen. Alles darüber hinaus wird nicht
  /// angezeigt — im Eröffnungskontext kommt es praktisch nicht vor.
  static const _nagSymbols = <int, String>{
    1: '!',
    2: '?',
    3: '!!',
    4: '??',
    5: '!?',
    6: '?!',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final symbol = nags.map((n) => _nagSymbols[n]).nonNulls.join();

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allXs,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.allXs,
          color: isCurrent
              ? tokens.accent.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
        child: Text(
          '$label$symbol',
          style:
              (isVariation
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                    color: isCurrent
                        ? tokens.accent
                        : tokens.textAlpha(isVariation ? 0.75 : 1),
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
        ),
      ),
    );
  }
}
