import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/app_card.dart';
import 'package:masteropening/core/widgets/fading_divider.dart';

/// Eine Karte mit Einstellungszeilen, durch dünne Linien getrennt — das
/// Zeilenmuster aus dem Entwurf (`padding: 4px 12px`, Trenner zwischen den
/// Zeilen, keiner nach der letzten).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SolidDivider(),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Eine Zeile darin: Titel, optionaler erklärender Untertitel, rechts der
/// Wert oder ein Bedienelement.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    super.key,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;

  /// Kurzer Wert rechts, z. B. „30" oder „@marek_kn".
  final String? value;

  /// Ein Bedienelement rechts — schließt [value] aus.
  final Widget? trailing;

  final VoidCallback? onTap;
  final bool showChevron;

  /// Färbt den Titel in Fehlerfarbe — für „Konto löschen".
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: destructive ? tokens.danger : tokens.text,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: tokens.textAlpha(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: AppSpacing.lg),
            Text(
              value!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: tokens.accent,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.lg),
            trailing!,
          ],
          if (showChevron) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              PhIcons.caretRight,
              size: 14,
              color: tokens.textAlpha(0.4),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: tokens.textAlpha(0.04),
      child: row,
    );
  }
}
