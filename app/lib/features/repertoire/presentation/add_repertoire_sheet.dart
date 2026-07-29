import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:masteropening/core/router/app_routes.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Die drei Wege, ein Repertoire anzulegen.
///
/// Als Blatt von unten statt als eigener Bildschirm: es ist eine Auswahl mit
/// drei Möglichkeiten, kein Schritt in einem Ablauf.
Future<void> showAddRepertoireSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _AddRepertoireSheet(),
  );
}

class _AddRepertoireSheet extends StatelessWidget {
  const _AddRepertoireSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.addRepertoireTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            _Option(
              icon: PhIcons.books,
              title: l10n.addFromLibrary,
              subtitle: l10n.addFromLibraryHint,
              onTap: () {
                Navigator.of(context).pop();
                context.go(Routes.library);
              },
            ),
            _Option(
              icon: PhIcons.clipboardText,
              title: l10n.addFromPgn,
              subtitle: l10n.addFromPgnHint,
              onTap: () {
                Navigator.of(context).pop();
                unawaited(context.push(Routes.repertoireImport));
              },
            ),
            _Option(
              icon: PhIcons.userCircle,
              title: l10n.addFromLichess,
              subtitle: l10n.addFromLichessHint,
              onTap: () {
                Navigator.of(context).pop();
                context.go(Routes.lichess);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allLg,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: AppRadius.allMd,
                border: Border.all(color: tokens.accent),
              ),
              child: Icon(icon, size: 19, color: tokens.accent),
            ),
            const SizedBox(width: AppSpacing.card),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textAlpha(0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhIcons.caretRight,
              size: 15,
              color: tokens.textAlpha(0.35),
            ),
          ],
        ),
      ),
    );
  }
}
