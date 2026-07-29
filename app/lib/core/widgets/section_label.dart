import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/app_typography.dart';

/// Die versale Mini-Überschrift über jedem Abschnitt, optional mit einer
/// Textaktion rechts („Alle ansehen").
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.label, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.accent = false,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Manche Abschnittsköpfe stehen in Akzentfarbe („AUS DEINEN PARTIEN"),
  /// die meisten gedämpft.
  final bool accent;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: context.kickerStyle.copyWith(
                color: accent ? tokens.accent : tokens.textAlpha(0.55),
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(
                  actionLabel!,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: tokens.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Der große Bildschirmtitel („Bibliothek", „Einstellungen").
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.kicker, this.trailing});

  final String title;

  /// Kleine Zeile darüber, z. B. das Datum auf dem Start-Tab.
  final String? kicker;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kicker != null) ...[
                Text(
                  kicker!.toUpperCase(),
                  style: context.kickerStyle.copyWith(
                    color: context.tokens.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
              ],
              Text(title, style: theme.textTheme.displaySmall),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.lg),
          trailing!,
        ],
      ],
    );
  }
}
