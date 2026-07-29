import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';

@immutable
class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;

  /// Gefüllte Variante desselben Symbols — die aktive Kachel ändert nicht nur
  /// die Farbe, sondern auch das Gewicht des Symbols.
  final IconData activeIcon;

  final String label;
}

/// Die Tab-Leiste aus dem Entwurf: Trennlinie oben, vier gleich breite
/// Kacheln, 23-px-Symbol über einer 10-px-Beschriftung.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Der Entwurf reserviert 26 px unter der Leiste für die Home-Anzeige;
    // auf Geräten mit Tasten-Navigation genügen 8.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bg,
        border: Border(top: BorderSide(color: tokens.divider)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
          bottomInset > 0 ? bottomInset : AppSpacing.sm,
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavTile(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () {
                    if (i != currentIndex) {
                      HapticFeedback.selectionClick().ignore();
                    }
                    onSelected(i);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = selected ? tokens.accent : tokens.textAlpha(0.45);

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ein kurzer Hüpfer beim Wechsel — genug, um den Wechsel zu
              // quittieren, zu wenig, um beim zehnten Mal zu nerven.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: selected ? 1.12 : 1),
                duration: AppDurations.fast,
                curve: AppCurves.emphasized,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 23,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: AppDurations.fast,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
