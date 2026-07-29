import 'package:flutter/material.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/app_button.dart';

/// Leerer Zustand mit Symbol, Erklärung und — wichtig — genau einem nächsten
/// Schritt. Ein leerer Bildschirm ohne Ausweg ist ein Fehler, kein Zustand.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Für leere Abschnitte innerhalb eines sonst gefüllten Bildschirms.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: compact ? AppSpacing.xxl : AppSpacing.huge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 44 : 60,
            height: compact ? 44 : 60,
            decoration: BoxDecoration(
              color: tokens.accentAlpha(0.12),
              borderRadius: AppRadius.allXl,
            ),
            child: Center(
              child: Icon(
                icon,
                size: compact ? 22 : 30,
                color: tokens.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: compact
                ? theme.textTheme.titleMedium
                : theme.textTheme.headlineSmall,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textAlpha(0.6),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              icon: PhIcons.plus,
            ),
          ],
        ],
      ),
    );
  }
}
