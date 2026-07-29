import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';

@immutable
class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Die Segmentgruppe aus dem Entwurf (Weiß/Schwarz/Alle, Hell/Dunkel/System):
/// ein gemeinsamer Rahmen, senkrechte Trenner, und die aktive Option bekommt
/// einen Innenring in Akzentfarbe statt einer gefüllten Fläche.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.segments,
    required this.value,
    required this.onChanged,
    super.key,
    this.expand = false,
  });

  final List<AppSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Verteilt die Optionen über die volle Breite statt sie zu umschließen.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) Container(width: 1, height: 32, color: tokens.divider),
          if (expand)
            Expanded(child: _option(context, segments[i]))
          else
            _option(context, segments[i]),
        ],
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.allMd,
        border: Border.all(color: tokens.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(child: row),
    );
  }

  Widget _option(BuildContext context, AppSegment<T> segment) {
    final tokens = context.tokens;
    final selected = segment.value == value;
    final foreground = selected ? tokens.accent : tokens.textAlpha(0.7);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selected
          ? null
          : () {
              HapticFeedback.selectionClick().ignore();
              onChanged(segment.value);
            },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.enter,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          // Der Innenring: `inset 0 0 0 1px accent` aus dem CSS.
          border: Border.all(
            color: selected ? tokens.accent : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (segment.icon != null) ...[
              Icon(segment.icon, size: 15, color: foreground),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              segment.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
