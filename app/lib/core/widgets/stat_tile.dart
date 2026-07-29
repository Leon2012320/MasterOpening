import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/app_typography.dart';
import 'package:masteropening/core/widgets/app_card.dart';

/// Die Kennzahl-Kachel: große tabellarische Zahl, kleine Beschriftung darunter.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    super.key,
    this.icon,
    this.accent = false,
    this.onTap,
    this.compact = false,
  });

  final String value;
  final String label;
  final IconData? icon;

  /// Hebt die Zahl in Akzentfarbe hervor — für die eine Kennzahl, auf die es
  /// auf dem Bildschirm gerade ankommt.
  final bool accent;

  final VoidCallback? onTap;

  /// Engere Variante für Viererreihen (Lichess-Wertungen).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AppCard(
      onTap: onTap,
      radius: AppRadius.lg,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.lg,
        vertical: compact ? AppSpacing.md : AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: tokens.textAlpha(0.55)),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (compact
                        ? Theme.of(context).textTheme.titleLarge
                        : context.statStyle)
                    ?.copyWith(
                      color: accent ? tokens.accent : tokens.text,
                      fontFeatures: const [AppTypography.tabular],
                    ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tokens.textAlpha(0.6),
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
