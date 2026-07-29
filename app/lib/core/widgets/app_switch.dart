import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';

/// Der Schalter aus dem Entwurf: 46 × 27, Knopf 21, Weg 19 px, 180 ms.
/// Bewusst kein `Switch.adaptive` — die Material-Variante bringt eigene
/// Größen, Wellen und Ränder mit, die neben den Nocturne-Flächen fremd wirken.
class AppSwitch extends StatelessWidget {
  const AppSwitch({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const double _width = 46;
  static const double _height = 27;
  static const double _knob = 21;
  static const double _inset = 3;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = onChanged != null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick().ignore();
                  onChanged!(!value);
                }
              : null,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.enter,
            width: _width,
            height: _height,
            padding: const EdgeInsets.all(_inset),
            decoration: BoxDecoration(
              color: value ? tokens.accent : tokens.textAlpha(0.18),
              borderRadius: AppRadius.allPill,
            ),
            child: AnimatedAlign(
              duration: AppDurations.fast,
              curve: AppCurves.enter,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _knob,
                height: _knob,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FE),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
