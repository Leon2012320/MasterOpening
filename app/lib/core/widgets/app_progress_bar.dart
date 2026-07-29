import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';

/// Der schmale Fortschrittsbalken aus dem Entwurf: 4 px hoch, vertiefte Spur,
/// Füllung in Akzentfarbe. Wächst animiert, damit ein Trainingserfolg sichtbar
/// wird statt nur zu erscheinen.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    super.key,
    this.height = 4,
    this.color,
    this.trackColor,
    this.animate = true,
  });

  /// 0…1. Werte außerhalb werden gekappt.
  final double value;

  final double height;
  final Color? color;
  final Color? trackColor;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final clamped = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: trackColor ?? tokens.textAlpha(0.12),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: animate
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: clamped),
                      duration: AppDurations.slow,
                      curve: AppCurves.enter,
                      builder: (context, animated, _) => FractionallySizedBox(
                        widthFactor: animated,
                        child: ColoredBox(
                          color: color ?? tokens.accent,
                          child: SizedBox(height: height),
                        ),
                      ),
                    )
                  : FractionallySizedBox(
                      widthFactor: clamped,
                      child: ColoredBox(
                        color: color ?? tokens.accent,
                        child: SizedBox(height: height),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ring-Fortschritt für den Blitz-Countdown und die Level-Anzeige.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    required this.value,
    required this.size,
    super.key,
    this.strokeWidth = 3,
    this.color,
    this.trackColor,
    this.child,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              value: value.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              color: color ?? tokens.accent,
              trackColor: trackColor ?? tokens.textAlpha(0.12),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas
      ..drawCircle(center, radius, track)
      ..drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start bei 12 Uhr
        2 * math.pi * value,
        false,
        arc,
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
