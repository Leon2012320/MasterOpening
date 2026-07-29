import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';

enum AppButtonVariant {
  /// Akzent als Kontur, nicht als Fläche — die Kernentscheidung des Entwurfs.
  primary,

  /// Neutrale Kontur für Zweitaktionen.
  secondary,

  /// Nur Text in Akzentfarbe, ohne Rahmen.
  ghost,

  /// Kontur in Fehlerfarbe, für Löschen und Trennen.
  danger,
}

enum AppButtonSize {
  /// 32 px — in Listenzeilen und Kartenköpfen.
  small,

  /// 38 px — der Normalfall.
  medium,

  /// 44 px — die Hauptaktion eines Bildschirms.
  large,
}

class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.expand = false,
    this.busy = false,
  });

  /// Füllt die verfügbare Breite — der `btn-block`-Fall aus dem Entwurf.
  const AppButton.block({
    required this.label,
    super.key,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.busy = false,
  }) : expand = true;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool expand;

  /// Zeigt einen Spinner statt des Labels und sperrt die Schaltfläche.
  final bool busy;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.busy;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final (foreground, borderColor) = switch (widget.variant) {
      AppButtonVariant.primary => (tokens.accent, tokens.accent),
      AppButtonVariant.secondary => (tokens.text, tokens.divider),
      AppButtonVariant.ghost => (tokens.accent, Colors.transparent),
      AppButtonVariant.danger => (tokens.danger, tokens.danger),
    };

    final height = switch (widget.size) {
      AppButtonSize.small => 32.0,
      AppButtonSize.medium => 38.0,
      AppButtonSize.large => 44.0,
    };

    final fontSize = switch (widget.size) {
      AppButtonSize.small => 13.0,
      AppButtonSize.medium => 14.0,
      AppButtonSize.large => 15.0,
    };

    // Die Füllung erscheint erst beim Drücken — im Ruhezustand ist der Akzent
    // reine Linie.
    final fill = _pressed && _enabled
        ? foreground.withValues(alpha: 0.18)
        : Colors.transparent;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.busy)
          SizedBox(
            width: fontSize,
            height: fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon, size: fontSize + 2, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: foreground,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: Opacity(
        opacity: _enabled ? 1 : 0.45,
        child: GestureDetector(
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: _enabled
              ? () {
                  unawaitedHaptic();
                  widget.onPressed!.call();
                }
              : null,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.enter,
            height: height,
            width: widget.expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.expand ? AppSpacing.lg : AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: AppRadius.allMd,
              border: borderColor == Colors.transparent
                  ? null
                  : Border.all(color: borderColor),
            ),
            child: Center(
              widthFactor: widget.expand ? null : 1,
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  void unawaitedHaptic() {
    // Die Rückmeldung ist Beiwerk: schlägt sie fehl (Desktop, kein Motor),
    // darf das den Tastendruck nicht verschlucken.
    HapticFeedback.selectionClick().ignore();
  }
}
