import 'dart:async';

import 'package:chessground/chessground.dart' show PlayerSide;
import 'package:dartchess/dartchess.dart' show Move;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/chess/san_notation.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/chess_board.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/training/data/training_providers.dart';
import 'package:masteropening/features/training/domain/training_plan.dart';
import 'package:masteropening/features/training/domain/training_session.dart';
import 'package:masteropening/features/training/presentation/training_report_screen.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Lädt den Plan und startet die Einheit.
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({required this.mode, this.repertoireId, super.key});

  final TrainingMode mode;
  final int? repertoireId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final request = TrainingRequest(mode: mode, repertoireId: repertoireId);

    return ref
        .watch(trainingPlanProvider(request))
        .when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: Text(l10n.trainingTitle)),
            body: EmptyState(
              icon: PhIcons.warning,
              title: l10n.learnLoadError,
              message: '$error',
            ),
          ),
          data: (lines) => lines.isEmpty
              ? Scaffold(
                  appBar: AppBar(title: Text(l10n.trainingTitle)),
                  body: EmptyState(
                    icon: PhIcons.check,
                    title: l10n.trainingNothingDueTitle,
                    message: l10n.trainingNothingDueMessage,
                  ),
                )
              : TrainingRunner(mode: mode, lines: lines),
        );
  }
}

/// Der Ablauf selbst. Nimmt den fertigen Plan entgegen — dadurch lässt sich
/// der Bildschirm ohne Datenbank prüfen.
class TrainingRunner extends ConsumerStatefulWidget {
  const TrainingRunner({required this.mode, required this.lines, super.key});

  final TrainingMode mode;
  final List<TrainingLine> lines;

  @override
  ConsumerState<TrainingRunner> createState() => _TrainingRunnerState();
}

class _TrainingRunnerState extends ConsumerState<TrainingRunner> {
  late TrainingSessionState _session;

  /// Wann die aktuelle Frage gestellt wurde — daraus wird die Bedenkzeit.
  late DateTime _askedAt;

  Timer? _advanceTimer;
  bool _saved = false;

  /// Wie lange die Rückmeldung stehen bleibt, bevor es weitergeht.
  static const _correctPause = Duration(milliseconds: 550);
  static const _wrongPause = Duration(milliseconds: 1600);

  @override
  void initState() {
    super.initState();
    _session = TrainingSessionState.start(
      mode: widget.mode,
      lines: widget.lines,
      now: DateTime.now(),
    );
    _askedAt = DateTime.now();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  void _onMove(Move move) {
    if (_session.phase != TrainingPhase.awaitingMove) return;

    final millis = DateTime.now().difference(_askedAt).inMilliseconds;
    final next = _session.submitMove(move, millis: millis);
    if (next == _session) return;

    final settings = ref.read(settingsProvider);
    if (settings.hapticFeedback) {
      unawaited(
        next.phase == TrainingPhase.correct
            ? HapticFeedback.lightImpact()
            : HapticFeedback.heavyImpact(),
      );
    }

    setState(() => _session = next);

    _advanceTimer?.cancel();
    _advanceTimer = Timer(
      next.phase == TrainingPhase.correct ? _correctPause : _wrongPause,
      _advance,
    );
  }

  void _advance() {
    if (!mounted) return;
    setState(() {
      _session = _session.advance();
      _askedAt = DateTime.now();
    });
    if (_session.phase == TrainingPhase.lineComplete) {
      _advanceTimer = Timer(_correctPause, _nextLine);
    }
  }

  void _nextLine() {
    if (!mounted) return;
    setState(() {
      _session = _session.nextLine();
      _askedAt = DateTime.now();
    });
    if (_session.isFinished) unawaited(_finish());
  }

  Future<void> _finish() async {
    if (_saved) return;
    _saved = true;

    final now = DateTime.now();
    final report = _session.report(now);
    final navigator = Navigator.of(context);

    await ref
        .read(trainingRepositoryProvider)
        .saveSession(session: _session, report: report, now: now);

    if (!mounted) return;
    await navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => TrainingReportScreen(report: report),
      ),
    );
  }

  Future<void> _confirmAbort() async {
    final l10n = AppL10n.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.trainingAbortConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.trainingAbort),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (_session.movesTotal == 0) {
      navigator.pop();
      return;
    }
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final settings = ref.watch(settingsProvider);
    final line = _session.currentLine;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmAbort());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(line?.repertoireName ?? l10n.trainingTitle),
          leading: IconButton(
            icon: const Icon(PhIcons.x),
            tooltip: l10n.trainingAbort,
            onPressed: () => unawaited(_confirmAbort()),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: AppProgressBar(value: _session.progress),
          ),
        ),
        body: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth.clamp(
                  0.0,
                  MediaQuery.sizeOf(context).height * 0.5,
                );
                return Center(
                  child: AppChessboard(
                    size: size,
                    position: _session.position,
                    orientation: line?.side ?? _session.position.turn,
                    lastMove: _session.lastMove,
                    interactableSide:
                        _session.phase == TrainingPhase.awaitingMove
                        ? PlayerSide.both
                        : PlayerSide.none,
                    settings: BoardTheming.settings(
                      settings,
                      isDark: tokens.isDark,
                      // Die möglichen Zielfelder zu zeigen wäre im Training
                      // eine Hilfe zu viel.
                      showValidMoves: false,
                    ),
                    onMove: _onMove,
                  ),
                );
              },
            ),
            Expanded(child: _Feedback(session: _session)),
          ],
        ),
      ),
    );
  }
}

/// Die Rückmeldung unter dem Brett.
class _Feedback extends StatelessWidget {
  const _Feedback({required this.session});

  final TrainingSessionState session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    final (icon, color, text) = switch (session.phase) {
      TrainingPhase.awaitingMove => (
        null,
        tokens.textAlpha(0.6),
        l10n.trainingYourMove,
      ),
      TrainingPhase.correct => (
        PhIcons.check,
        tokens.success,
        l10n.trainingCorrect,
      ),
      TrainingPhase.wrong => (
        PhIcons.x,
        tokens.danger,
        session.lastPlayedSan == null
            ? l10n.trainingTimeUp(
                SanNotation.localize(
                  session.attempts.last.expectedSan,
                  language,
                ),
              )
            : l10n.trainingWrong(
                SanNotation.localize(
                  session.attempts.last.expectedSan,
                  language,
                ),
              ),
      ),
      TrainingPhase.lineComplete => (
        PhIcons.check,
        tokens.accent,
        l10n.trainingLineDone,
      ),
      TrainingPhase.finished => (null, tokens.accent, l10n.reportTitle),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                      ),
                    ),
                  ),
                ],
              )
              .animate(key: ValueKey(session.phase))
              .fadeIn(
                duration: AppDurations.fast,
              ),
          const Spacer(),
          Text(
            l10n.trainingLineOf(
              session.results.length + 1,
              session.lines.length,
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.textAlpha(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
