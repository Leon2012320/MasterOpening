import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_tokens.dart';

/// Die Signatur-Trennlinie des Nocturne-Systems: sie läuft an beiden Enden
/// über 48 Pixel ins Transparente aus, statt hart abzubrechen.
///
/// Nur für freistehende Linien. Rahmen von Kästen, Trenner innerhalb eines
/// Bedienelements und kurze Akzentstriche bleiben durchgezogen — dafür ist
/// [SolidDivider] da.
class FadingDivider extends StatelessWidget {
  const FadingDivider({
    super.key,
    this.margin = EdgeInsets.zero,
    this.color,
  });

  final EdgeInsetsGeometry margin;
  final Color? color;

  /// Länge der Ausblendung an jedem Ende, in logischen Pixeln.
  static const double _fade = 48;

  @override
  Widget build(BuildContext context) {
    final lineColor = color ?? context.tokens.divider;

    return Padding(
      padding: margin,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // Bei schmalen Elementen würden sich die beiden Ausblendungen
          // überlappen; dann wird daraus ein durchgehender Verlauf zur Mitte.
          final stop = width.isFinite && width > 0
              ? (_fade / width).clamp(0.0, 0.5)
              : 0.5;

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  lineColor.withValues(alpha: 0),
                  lineColor,
                  lineColor,
                  lineColor.withValues(alpha: 0),
                ],
                stops: [0, stop, 1 - stop, 1],
              ),
            ),
            child: const SizedBox(height: 1, width: double.infinity),
          );
        },
      ),
    );
  }
}

/// Durchgezogene Trennlinie für Listenzeilen und Bedienelemente.
class SolidDivider extends StatelessWidget {
  const SolidDivider({super.key, this.margin = EdgeInsets.zero, this.color});

  final EdgeInsetsGeometry margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        height: 1,
        width: double.infinity,
        color: color ?? context.tokens.divider,
      ),
    );
  }
}
