import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/board_theme.dart';

/// Die Reihe kleiner Brett-Kacheln aus dem Entwurf: 26 × 26, ein 2 × 2-Muster,
/// die gewählte trägt einen Akzentring.
class BoardStylePicker extends StatelessWidget {
  const BoardStylePicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final BoardStyle value;
  final ValueChanged<BoardStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.tokens.isDark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final style in BoardStyle.values)
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: _Swatch(
              colors: BoardColors.of(style, isDark: isDark),
              selected: style == value,
              onTap: () {
                HapticFeedback.selectionClick().ignore();
                onChanged(style);
              },
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final BoardColors colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: AppRadius.allSm,
          border: Border.all(
            color: selected ? context.tokens.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: CustomPaint(
            painter: _CheckerPainter(
              light: colors.lightSquare,
              dark: colors.darkSquare,
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter({required this.light, required this.dark});

  final Color light;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    final half = Size(size.width / 2, size.height / 2);
    final lightPaint = Paint()..color = light;
    final darkPaint = Paint()..color = dark;

    canvas
      ..drawRect(Offset.zero & half, lightPaint)
      ..drawRect(Offset(half.width, 0) & half, darkPaint)
      ..drawRect(Offset(0, half.height) & half, darkPaint)
      ..drawRect(Offset(half.width, half.height) & half, lightPaint);
  }

  @override
  bool shouldRepaint(_CheckerPainter old) =>
      old.light != light || old.dark != dark;
}
