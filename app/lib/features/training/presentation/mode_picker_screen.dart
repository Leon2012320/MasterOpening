import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/settings/settings_controller.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/features/training/presentation/training_screen.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Die Auswahl des Trainingsmodus.
///
/// Ein eigener Bildschirm und kein Blatt von unten: die vier Modi sind
/// unterschiedlich genug, dass die Erklärung dazugehört — und wer trainieren
/// will, hat sowieso schon entschieden, dass er hier ist.
class ModePickerScreen extends ConsumerWidget {
  const ModePickerScreen({required this.repertoireId, super.key});

  /// `null` heisst: über alle Repertoires hinweg.
  final int? repertoireId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final blitzSeconds = ref.watch(settingsProvider).blitzSecondsPerMove;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainingTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xl,
          AppSpacing.screen,
          AppSpacing.huge,
        ),
        children: [
          Text(
            l10n.modePickTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xxl),

          _ModeTile(
            icon: PhIcons.sparkle,
            title: l10n.modeSmart,
            subtitle: l10n.modeSmartHint,
            onTap: () => _start(context, TrainingMode.smart),
          ),
          _ModeTile(
            icon: PhIcons.lightning,
            title: l10n.modeBlitz,
            subtitle: l10n.modeBlitzHint(blitzSeconds),
            onTap: () => _start(context, TrainingMode.blitz),
          ),
          _ModeTile(
            icon: PhIcons.puzzlePiece,
            title: l10n.modePuzzle,
            subtitle: l10n.modePuzzleHint,
            onTap: () => _start(context, TrainingMode.puzzle),
          ),
          _ModeTile(
            icon: PhIcons.warning,
            title: l10n.modeTrap,
            subtitle: l10n.modeTrapHint,
            onTap: () => _start(context, TrainingMode.trap),
          ),
        ],
      ),
    );
  }

  void _start(BuildContext context, TrainingMode mode) {
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) =>
              TrainingScreen(mode: mode, repertoireId: repertoireId),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allLg,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.card),
          decoration: BoxDecoration(
            borderRadius: AppRadius.allLg,
            color: tokens.surface,
            boxShadow: tokens.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.allMd,
                  border: Border.all(color: tokens.accent),
                ),
                child: Icon(icon, size: 20, color: tokens.accent),
              ),
              const SizedBox(width: AppSpacing.card),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textAlpha(0.6),
                        height: 1.35,
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
      ),
    );
  }
}
