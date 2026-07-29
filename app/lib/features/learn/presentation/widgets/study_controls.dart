import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Die Zugleiste unter dem Brett: Anfang, zurück, abspielen, vor, Ende.
class StudyControls extends StatelessWidget {
  const StudyControls({
    required this.canGoBack,
    required this.canGoForward,
    required this.isPlaying,
    required this.onStart,
    required this.onBack,
    required this.onTogglePlay,
    required this.onForward,
    required this.onEnd,
    super.key,
  });

  final bool canGoBack;
  final bool canGoForward;
  final bool isPlaying;

  final VoidCallback onStart;
  final VoidCallback onBack;
  final VoidCallback onTogglePlay;
  final VoidCallback onForward;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: PhIcons.skipBack,
          tooltip: l10n.learnToStart,
          onPressed: canGoBack ? onStart : null,
        ),
        _ControlButton(
          icon: PhIcons.caretLeft,
          tooltip: l10n.learnPrevious,
          onPressed: canGoBack ? onBack : null,
        ),
        _ControlButton(
          icon: isPlaying ? PhIcons.pause : PhIcons.play,
          tooltip: isPlaying ? l10n.learnAutoplayStop : l10n.learnAutoplay,
          emphasised: true,
          onPressed: canGoForward || isPlaying ? onTogglePlay : null,
        ),
        _ControlButton(
          icon: PhIcons.caretRight,
          tooltip: l10n.learnNext,
          onPressed: canGoForward ? onForward : null,
        ),
        _ControlButton(
          icon: PhIcons.skipForward,
          tooltip: l10n.learnToEnd,
          onPressed: canGoForward ? onEnd : null,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.emphasised = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        enabled: enabled,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.allPill,
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Der hervorgehobene Knopf trägt eine Akzentkontur, keine
              // Füllung — dieselbe Regel wie bei den Buttons.
              border: emphasised
                  ? Border.all(
                      color: enabled ? tokens.accent : tokens.textAlpha(0.2),
                    )
                  : null,
            ),
            child: Icon(
              icon,
              size: 22,
              color: enabled
                  ? (emphasised ? tokens.accent : tokens.textAlpha(0.8))
                  : tokens.textAlpha(0.25),
            ),
          ),
        ),
      ),
    );
  }
}
