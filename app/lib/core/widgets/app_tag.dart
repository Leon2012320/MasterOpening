import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';

enum AppTagVariant {
  /// Getönte Akzentfläche — für Status, der Aufmerksamkeit verdient
  /// („Fällig heute").
  accent,

  /// Neutral getönt — für sachliche Angaben wie ECO-Codes.
  neutral,

  /// Nur Kontur — für Filter und wählbare Merkmale.
  outline,

  /// Erfolg, z. B. „Gemeistert".
  success,

  /// Warnung, z. B. „Lücke".
  warning,

  /// Fehler, z. B. „Häufiger Fehler".
  danger,
}

/// Die kleine Pille aus dem Entwurf: 11 px, enge Innenabstände, 6-px-Radius.
class AppTag extends StatelessWidget {
  const AppTag(
    this.label, {
    super.key,
    this.variant = AppTagVariant.neutral,
    this.icon,
  });

  final String label;
  final AppTagVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final (background, foreground, border) = switch (variant) {
      AppTagVariant.accent => (
        tokens.tagAccentBg,
        tokens.tagAccentFg,
        Colors.transparent,
      ),
      AppTagVariant.neutral => (
        tokens.tagNeutralBg,
        tokens.tagNeutralFg,
        Colors.transparent,
      ),
      AppTagVariant.outline => (
        Colors.transparent,
        tokens.accent,
        tokens.accent,
      ),
      AppTagVariant.success => (
        tokens.success.withValues(alpha: 0.18),
        tokens.success,
        Colors.transparent,
      ),
      AppTagVariant.warning => (
        tokens.warning.withValues(alpha: 0.18),
        tokens.warning,
        Colors.transparent,
      ),
      AppTagVariant.danger => (
        tokens.danger.withValues(alpha: 0.18),
        tokens.danger,
        Colors.transparent,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.allSm,
        border: border == Colors.transparent ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              letterSpacing: 0.22,
            ),
          ),
        ],
      ),
    );
  }
}
