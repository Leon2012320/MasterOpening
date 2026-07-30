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
import 'package:masteropening/features/gamification/data/gamification_providers.dart';
import 'package:masteropening/features/training/data/training_providers.dart';
import 'package:masteropening/features/training/domain/training_plan.dart';
import 'package:masteropening/features/training/domain/training_session.dart';
import 'package:masteropening/features/training/presentation/training_report_screen.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Lädt den Plan und startet die Einheit.
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({
    required this.mode,
    this.repertoireId,
    this.pathHash,
    super.key,
  });

  final TrainingMode mode;
  final int? repertoireId;

  /// Nur im Modus „bestimmte Variante": welcher Zug gemeint ist.
  final String? pathHash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final request = TrainingRequest(
      mode: mode,
      repertoireId: repertoireId,
      pathHash: pathHash,
    );

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

  /// Läuft nur im Blitz-Modus: tickt die Bedenkzeit herunter.
  Timer? _clockTimer;

  /// Verbleibende Bedenkzeit in Millisekunden, `null` ausserhalb des
  /// Blitz-Modus.
  int? _remainingMillis;

  bool _saved = false;

  /// Wie lange die Rückmeldung stehen bleibt, bevor es weitergeht.
  static const _correctPause = Duration(milliseconds: 550);
  static const _wrongPause = Duration(milliseconds: 1600);

  /// Takt der Blitz-Uhr. Fein genug für einen flüssigen Ring, grob genug,
  /// um nicht jeden Frame neu zu bauen.
  static const _tick = Duration(milliseconds: 50);

  bool get _isBlitz => widget.mode == TrainingMode.blitz;

  int get _blitzMillis => ref.read(settingsProvider).blitzSecondsPerMove * 1000;

  @override
  void initState() {
    super.initState();
    _session = TrainingSessionState.start(
      mode: widget.mode,
      lines: widget.lines,
      now: DateTime.now(),
    );
    _askedAt = DateTime.now();
    if (_isBlitz) _startClock();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer?.cancel();
    if (!_isBlitz || _session.phase != TrainingPhase.awaitingMove) return;

    final total = _blitzMillis;
    setState(() => _remainingMillis = total);

    _clockTimer = Timer.periodic(_tick, (timer) {
      if (!mounted) return;
      final left = total - DateTime.now().difference(_askedAt).inMilliseconds;

      if (left <= 0) {
        timer.cancel();
        setState(() => _remainingMillis = 0);
        _onTimeOut(total);
        return;
      }
      setState(() => _remainingMillis = left);
    });
  }

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  void _onTimeOut(int millis) {
    if (_session.phase != TrainingPhase.awaitingMove) return;

    final settings = ref.read(settingsProvider);
    if (settings.hapticFeedback) unawaited(HapticFeedback.heavyImpact());

    setState(() => _session = _session.timeOut(millis: millis));
    _advanceTimer?.cancel();
    _advanceTimer = Timer(_wrongPause, _advance);
  }

  void _onMove(Move move) {
    if (_session.phase != TrainingPhase.awaitingMove) return;

    final millis = DateTime.now().difference(_askedAt).inMilliseconds;
    final next = _session.submitMove(move, millis: millis);
    if (next == _session) return;

    _stopClock();

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
    } else {
      _startClock();
    }
  }

  void _nextLine() {
    if (!mounted) return;
    setState(() {
      _session = _session.nextLine();
      _askedAt = DateTime.now();
    });
    if (_session.isFinished) {
      _stopClock();
      unawaited(_finish());
    } else {
      _startClock();
    }
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

    // Erst danach: die Belohnungen rechnen mit den eben verbuchten Tageswerten.
    final outcome = await ref
        .read(gamificationRepositoryProvider)
        .applySession(xpFromSession: report.xpEarned, now: now);

    if (!mounted) return;
    await navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) =>
            TrainingReportScreen(report: report, outcome: outcome),
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
            if (_isBlitz)
              _BlitzClock(
                remainingMillis: _remainingMillis,
                totalMillis: _blitzMillis,
              ),
            Expanded(child: _Feedback(session: _session)),
          ],
        ),
      ),
    );
  }
}

/// Der Countdown im Blitz-Modus: ein Ring, der sich leert, mit der
/// verbleibenden Zeit in der Mitte.
///
/// Bewusst kein Balken: ein Ring lässt sich mit dem Blick am Brett
/// mitverfolgen, weil die Restmenge als Winkel und nicht als Länge zu lesen
/// ist.
class _BlitzClock extends StatelessWidget {
  const _BlitzClock({required this.remainingMillis, required this.totalMillis});

  final int? remainingMillis;
  final int totalMillis;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final left = remainingMillis ?? totalMillis;
    final fraction = (left / totalMillis).clamp(0.0, 1.0);

    // Unter einem Viertel wird der Ring rot — die letzte Sekunde soll man
    // sehen, ohne hinzuschauen.
    final color = fraction < 0.25 ? tokens.danger : tokens.accent;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                backgroundColor: tokens.textAlpha(0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Text(
              (left / 1000).ceil().toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
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
          // Im Fallen-Modus steht über der Rückmeldung, welche Falle gerade
          // gestellt wurde — ohne den Namen wüsste man nicht, was man gelernt
          // hat.
          if (session.currentLine?.trapName case final trap?) ...[
            Text(
              l10n.trapNameLabel(trap),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textAlpha(0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
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
          // Nach einer widerlegten Falle die Erklärung — der Moment, in dem
          // sie hängen bleibt.
          if (session.phase == TrainingPhase.lineComplete)
            if (session.currentLine?.trapExplanation case final why?) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                why,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textAlpha(0.7),
                  height: 1.4,
                ),
              ),
            ],
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
