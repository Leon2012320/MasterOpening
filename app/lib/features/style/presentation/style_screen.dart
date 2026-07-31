import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masteropening/core/router/app_routes.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/library/domain/library_opening.dart';
import 'package:masteropening/features/style/data/style_providers.dart';
import 'package:masteropening/features/style/domain/style_profile.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Vorschlag: welche Eröffnungen zum eigenen Geschmack passen.
typedef StyleSuggestion = ({LibraryOpeningSummary opening, double match});

class StyleScreen extends ConsumerWidget {
  const StyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StyleView(
      profile: ref.watch(styleProfileProvider),
      suggestions: ref.watch(styleSuggestionsProvider),
      onOpen: (id) => unawaited(context.push(Routes.libraryDetail(id))),
    );
  }
}

/// Das Stilbild und die daraus abgeleiteten Vorschläge.
class StyleView extends StatelessWidget {
  const StyleView({
    required this.profile,
    required this.suggestions,
    super.key,
    this.onOpen,
  });

  final StyleProfile profile;
  final List<StyleSuggestion> suggestions;
  final void Function(String openingId)? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final language = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.styleTitle)),
      body: profile.isEmpty
          ? EmptyState(
              icon: PhIcons.compass,
              title: l10n.styleNoDataTitle,
              message: l10n.styleNoDataMessage,
            )
          : ListView(
              padding: const EdgeInsets.only(
                top: AppSpacing.xl,
                bottom: AppSpacing.huge,
              ),
              children: [
                ScreenPadding(
                  child: Text(
                    l10n.styleBasis(profile.gamesAnalysed),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textAlpha(0.55),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                ScreenPadding(child: SectionLabel(l10n.styleSectionProfile)),
                for (final axis in StyleAxis.values)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      0,
                      AppSpacing.screen,
                      AppSpacing.card,
                    ),
                    child: _AxisBar(
                      score:
                          profile.scores[axis] ??
                          StyleScore(axis: axis, value: 0, samples: 0),
                      labels: _labelsFor(l10n, axis),
                    ),
                  ),

                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  ScreenPadding(
                    child: SectionLabel(l10n.styleSectionSuggestions),
                  ),
                  for (final suggestion in suggestions)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        0,
                        AppSpacing.screen,
                        AppSpacing.md,
                      ),
                      child: AppCard(
                        onTap: onOpen == null
                            ? null
                            : () => onOpen!(suggestion.opening.id),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    language == 'de'
                                        ? suggestion.opening.nameDe
                                        : suggestion.opening.nameEn,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    l10n.styleMatch(
                                      (suggestion.match * 100).round(),
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: tokens.accent),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              PhIcons.caretRight,
                              size: 14,
                              color: tokens.textAlpha(0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  static (String, String) _labelsFor(AppL10n l10n, StyleAxis axis) {
    return switch (axis) {
      StyleAxis.aggression => (l10n.styleAxisSolid, l10n.styleAxisAggressive),
      StyleAxis.tactics => (l10n.styleAxisPositional, l10n.styleAxisTactical),
      StyleAxis.openness => (l10n.styleAxisClosed, l10n.styleAxisOpen),
    };
  }
}

/// Eine Achse als Balken zwischen zwei Polen.
///
/// Kein Wert in der Mitte bedeutet „ausgewogen": er bedeutet auch „zu wenige
/// Partien". Deshalb wird ein unsicherer Wert blasser gezeichnet.
class _AxisBar extends StatelessWidget {
  const _AxisBar({required this.score, required this.labels});

  final StyleScore score;
  final (String, String) labels;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final opacity = score.isReliable ? 1.0 : 0.45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              labels.$1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textAlpha(0.5),
              ),
            ),
            const Spacer(),
            Text(
              labels.$2,
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textAlpha(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 14,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.surfaceSunken,
                      borderRadius: AppRadius.allPill,
                    ),
                  ),
                  // Die Mitte als feiner Strich: ohne sie liesse sich die
                  // Auslenkung nicht ablesen.
                  Positioned(
                    left: width / 2 - 0.5,
                    child: Container(
                      width: 1,
                      height: 10,
                      color: tokens.textAlpha(0.2),
                    ),
                  ),
                  Positioned(
                    left: (width * score.position - 5).clamp(0.0, width - 10),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
