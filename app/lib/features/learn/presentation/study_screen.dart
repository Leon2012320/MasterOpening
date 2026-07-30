import 'dart:async';

import 'package:chessground/chessground.dart' show PlayerSide;
import 'package:dartchess/dartchess.dart' show Move, Side;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/chess/repertoire_tree.dart';
import 'package:masteropening/chess/san_notation.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/chess_board.dart';
import 'package:masteropening/core/widgets/empty_state.dart';
import 'package:masteropening/core/widgets/fading_divider.dart';
import 'package:masteropening/features/learn/domain/move_list_layout.dart';
import 'package:masteropening/features/learn/domain/study_state.dart';
import 'package:masteropening/features/learn/presentation/widgets/move_list_view.dart';
import 'package:masteropening/features/learn/presentation/widgets/study_controls.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/features/training/presentation/training_screen.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Lädt das Repertoire und übergibt es an [StudyView].
///
/// Das Laden steckt bewusst in einem eigenen Widget: [StudyView] ist dadurch
/// eine reine Funktion ihrer Daten und lässt sich ohne Datenbank prüfen.
class StudyScreen extends ConsumerWidget {
  const StudyScreen({required this.repertoireId, super.key});

  final int repertoireId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);

    return ref
        .watch(repertoireTreeProvider(repertoireId))
        .when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: Text(l10n.learnTitle)),
            body: EmptyState(
              icon: PhIcons.warning,
              title: l10n.learnLoadError,
              message: '$error',
            ),
          ),
          data: (loaded) {
            if (loaded == null) {
              return Scaffold(
                appBar: AppBar(title: Text(l10n.learnTitle)),
                body: EmptyState(
                  icon: PhIcons.warning,
                  title: l10n.learnLoadError,
                ),
              );
            }
            return StudyView(
              repertoireId: repertoireId,
              title: loaded.row.name,
              tree: loaded.tree,
              side: loaded.row.side,
            );
          },
        );
  }
}

/// Der Lern-Modus: das Repertoire durchsehen wie eine Lichess-Studie.
///
/// Oben das Brett, darunter Kommentar und Verzweigungen, dann die Zugleiste
/// und schliesslich der Variantenbaum. Züge lassen sich auf dem Brett ziehen,
/// über die Leiste durchblättern, per Wischgeste wechseln oder in der Liste
/// direkt anspringen.
class StudyView extends ConsumerStatefulWidget {
  const StudyView({
    required this.repertoireId,
    required this.title,
    required this.tree,
    required this.side,
    super.key,
  });

  final int repertoireId;
  final String title;
  final RepertoireTree tree;

  /// Die Farbe des Repertoires — sie bestimmt, wie herum das Brett steht.
  final Side side;

  @override
  ConsumerState<StudyView> createState() => _StudyViewState();
}

class _StudyViewState extends ConsumerState<StudyView> {
  StudyState? _state;
  Timer? _autoplay;
  final _focusNode = FocusNode();

  /// Der Takt, in dem das automatische Abspielen weiterzieht — langsam genug,
  /// um mitzulesen.
  static const _autoplayInterval = Duration(milliseconds: 1100);

  @override
  void dispose() {
    _autoplay?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isPlaying => _autoplay != null;

  void _apply(StudyState Function(StudyState) transition) {
    final current = _state;
    if (current == null) return;
    final next = transition(current);
    if (next == current) return;
    setState(() => _state = next);
  }

  void _stopAutoplay() {
    if (_autoplay == null) return;
    _autoplay!.cancel();
    setState(() => _autoplay = null);
  }

  void _toggleAutoplay() {
    if (_isPlaying) {
      _stopAutoplay();
      return;
    }
    setState(() {
      _autoplay = Timer.periodic(_autoplayInterval, (_) {
        final current = _state;
        if (current == null || !current.canGoForward) {
          _stopAutoplay();
          return;
        }
        setState(() => _state = current.forward());
      });
    });
  }

  void _onBoardMove(Move move) {
    final current = _state;
    if (current == null) return;
    _stopAutoplay();

    final next = current.playMove(move);
    if (next == null) {
      _showNotInRepertoire();
      return;
    }
    setState(() => _state = next);
  }

  void _showNotInRepertoire() {
    final settings = ref.read(settingsProvider);
    if (settings.hapticFeedback) unawaited(HapticFeedback.lightImpact());

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(AppL10n.of(context).learnNotInRepertoire),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    // Unterhalb dieser Geschwindigkeit war es eher ein Verrutschen als eine
    // Geste.
    if (velocity.abs() < 120) return;
    _stopAutoplay();
    // Nach links wischen heisst vorwärts — der Zug kommt von rechts herein.
    _apply((s) => velocity < 0 ? s.forward() : s.back());
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        _stopAutoplay();
        _apply((s) => s.forward());
      case LogicalKeyboardKey.arrowLeft:
        _stopAutoplay();
        _apply((s) => s.back());
      case LogicalKeyboardKey.arrowUp:
        _stopAutoplay();
        _apply((s) => s.toStart());
      case LogicalKeyboardKey.arrowDown:
        _stopAutoplay();
        _apply((s) => s.toEnd());
      case LogicalKeyboardKey.space:
        _toggleAutoplay();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tree = widget.tree;

    // Beim ersten Aufbau und nach jeder Bearbeitung des Repertoires den
    // Zustand an den aktuellen Baum anpassen, ohne die Position zu verlieren.
    final current = _state;
    if (current == null) {
      _state = StudyState.atStart(tree, orientation: widget.side);
    } else if (current.tree != tree) {
      _state = current.withTree(tree);
    }
    final state = _state!;

    if (tree.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: EmptyState(
          icon: PhIcons.treeStructure,
          title: l10n.learnEmptyTitle,
          message: l10n.learnEmptyMessage,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          // Aus dem Ansehen direkt ins Üben: der Zug, auf dem man steht,
          // bestimmt die Variante.
          if (state.current case final node?)
            IconButton(
              icon: const Icon(PhIcons.play),
              tooltip: l10n.modeVariation,
              onPressed: () {
                _stopAutoplay();
                unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => TrainingScreen(
                        mode: TrainingMode.variation,
                        repertoireId: widget.repertoireId,
                        pathHash: node.pathHash,
                      ),
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(PhIcons.arrowsClockwise),
            tooltip: l10n.learnFlipBoard,
            onPressed: () => _apply((s) => s.flipped()),
          ),
        ],
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Column(
          children: [
            _Board(state: state, onMove: _onBoardMove),
            // Wischen wechselt den Zug — die naheliegende Geste, wenn eine
            // Hand das Gerät hält. Bewusst unterhalb des Bretts: dort würde
            // sie mit dem Ziehen der Figuren kollidieren.
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: _onSwipe,
                child: Column(
                  children: [
                    _ContextStrip(state: state),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                      ),
                      child: StudyControls(
                        canGoBack: state.canGoBack,
                        canGoForward: state.canGoForward,
                        isPlaying: _isPlaying,
                        onStart: () {
                          _stopAutoplay();
                          _apply((s) => s.toStart());
                        },
                        onBack: () {
                          _stopAutoplay();
                          _apply((s) => s.back());
                        },
                        onTogglePlay: _toggleAutoplay,
                        onForward: () {
                          _stopAutoplay();
                          _apply((s) => s.forward());
                        },
                        onEnd: () {
                          _stopAutoplay();
                          _apply((s) => s.toEnd());
                        },
                      ),
                    ),
                    const FadingDivider(),
                    Expanded(
                      child: MoveListView(
                        rows: MoveListLayout.build(tree),
                        languageCode: Localizations.localeOf(
                          context,
                        ).languageCode,
                        currentPathHash: state.current?.pathHash,
                        onSelect: (node) {
                          _stopAutoplay();
                          _apply((s) => s.goTo(node.pathHash));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Board extends ConsumerWidget {
  const _Board({required this.state, required this.onMove});

  final StudyState state;
  final void Function(Move move) onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = context.tokens.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Das Brett bekommt die Breite, aber höchstens gut die halbe Höhe —
        // sonst bleibt auf kleinen Geräten kein Platz für die Zugliste.
        final size = constraints.maxWidth.clamp(
          0.0,
          MediaQuery.sizeOf(context).height * 0.52,
        );

        return Center(
          child: AppChessboard(
            size: size,
            position: state.position,
            orientation: state.orientation,
            lastMove: state.lastMove,
            interactableSide: PlayerSide.both,
            settings: BoardTheming.settings(settings, isDark: isDark),
            onMove: onMove,
          ),
        );
      },
    );
  }
}

/// Der Streifen zwischen Brett und Zugleiste: Kommentar zum aktuellen Zug,
/// Hinweis auf eine Verzweigung oder auf das Ende der Variante.
class _ContextStrip extends StatelessWidget {
  const _ContextStrip({required this.state});

  final StudyState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    final comment = state.comment;
    final String text;
    final Color color;

    if (comment != null) {
      text = comment;
      color = tokens.textAlpha(0.75);
    } else if (state.isBranchPoint) {
      text = l10n.learnBranchHint(state.continuations.length);
      color = tokens.accent;
    } else if (!state.canGoForward) {
      text = l10n.learnLineEnd;
      color = tokens.textAlpha(0.5);
    } else if (state.isAtStart) {
      text = l10n.learnStartPosition;
      color = tokens.textAlpha(0.5);
    } else {
      text = SanNotation.localize(state.current!.san, language);
      color = tokens.textAlpha(0.5);
    }

    return AnimatedSize(
      duration: AppDurations.fast,
      curve: AppCurves.enter,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.md,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
