import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masteropening/core/router/app_routes.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/library/data/library_repository.dart';
import 'package:masteropening/features/library/domain/library_filter.dart';
import 'package:masteropening/features/library/domain/library_opening.dart';
import 'package:masteropening/features/library/presentation/library_l10n.dart';
import 'package:masteropening/features/library/presentation/widgets/opening_row.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Der Filterzustand der Bibliothek.
///
/// Liegt in einem Provider und nicht im Widget: so überlebt eine Suche den
/// Wechsel auf einen anderen Tab und zurück.
final libraryFilterProvider =
    NotifierProvider<LibraryFilterController, LibraryFilter>(
      LibraryFilterController.new,
    );

class LibraryFilterController extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => const LibraryFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSide(Side? side) =>
      state = state.copyWith(side: side, clearSide: side == null);

  void toggleTag(OpeningTag tag) => state = state.toggleTag(tag);

  void reset() => state = const LibraryFilter();
}

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(libraryIndexProvider);

    return TabScaffold(
      slivers: [
        SliverBox(bottom: AppSpacing.xl, child: ScreenTitle(l10n.libraryTitle)),
        ...async.when(
          loading: () => const [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
          ],
          error: (error, _) => [
            SliverToBoxAdapter(
              child: EmptyState(
                icon: PhIcons.warning,
                title: l10n.libraryLoadError,
                message: '$error',
              ),
            ),
          ],
          data: (openings) => _slivers(context, ref, openings),
        ),
      ],
    );
  }

  List<Widget> _slivers(
    BuildContext context,
    WidgetRef ref,
    List<LibraryOpeningSummary> openings,
  ) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final filter = ref.watch(libraryFilterProvider);
    final controller = ref.read(libraryFilterProvider.notifier);
    final visible = filter.apply(openings);

    // Welche Einträge schon im Repertoire stehen — die Zeile zeigt dafür
    // einen Haken statt der Variantenzahl.
    final installed = ref
        .watch(repertoiresProvider)
        .maybeWhen(
          data: (rows) => rows.map((r) => r.sourceRef).nonNulls.toSet(),
          orElse: () => const <String>{},
        );

    return [
      SliverBox(
        bottom: AppSpacing.lg,
        child: _SearchField(
          query: filter.query,
          onChanged: controller.setQuery,
        ),
      ),
      SliverBox(
        bottom: AppSpacing.lg,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AppSegmentedControl<Side?>(
            value: filter.side,
            onChanged: controller.setSide,
            segments: [
              AppSegment(value: Side.white, label: l10n.libraryFilterWhite),
              AppSegment(value: Side.black, label: l10n.libraryFilterBlack),
              AppSegment(value: null, label: l10n.libraryFilterAll),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: _TagBar(
          selected: filter.tags,
          onToggle: controller.toggleTag,
        ),
      ),
      SliverBox(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.libraryResultCount(visible.length),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.textAlpha(0.45)),
            ),
            if (filter.isActive)
              AppButton(
                label: l10n.libraryFilterReset,
                variant: AppButtonVariant.ghost,
                onPressed: controller.reset,
              ),
          ],
        ),
      ),
      if (visible.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: PhIcons.magnifyingGlass,
            title: l10n.libraryNoResultsTitle,
            message: l10n.libraryNoResultsMessage,
          ),
        )
      else
        SliverList.builder(
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final opening = visible[index];
            return OpeningRow(
              opening: opening,
              isInRepertoire: installed.contains(opening.id),
              onTap: () => context.push(Routes.libraryDetail(opening.id)),
            );
          },
        ),
    ];
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.librarySearchHint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.sm,
          ),
          child: Icon(
            PhIcons.magnifyingGlass,
            size: 16,
            color: tokens.textAlpha(0.5),
          ),
        ),
        suffixIcon: widget.query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(PhIcons.x, size: 15),
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              ),
      ),
    );
  }
}

/// Waagerecht scrollende Merkmalsfilter.
class _TagBar extends StatelessWidget {
  const _TagBar({required this.selected, required this.onToggle});

  final Set<OpeningTag> selected;
  final void Function(OpeningTag tag) onToggle;

  /// Nicht alle fünfzehn Merkmale: eine Leiste, durch die man dreimal wischen
  /// muss, filtert niemand mehr.
  static const List<OpeningTag> _tags = [
    OpeningTag.beginnerFriendly,
    OpeningTag.theoryLight,
    OpeningTag.attacking,
    OpeningTag.solid,
    OpeningTag.tactical,
    OpeningTag.positional,
    OpeningTag.gambit,
    OpeningTag.system,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        itemCount: _tags.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final tag = _tags[index];
          return _TagChip(
            label: l10n.openingTag(tag),
            selected: selected.contains(tag),
            onTap: () => onToggle(tag),
          );
        },
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allSm,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.allSm,
          // Akzent als Kontur, nicht als Fläche — die Regel des Entwurfs.
          border: Border.all(color: selected ? tokens.accent : tokens.divider),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? tokens.accent : tokens.textAlpha(0.7),
          ),
        ),
      ),
    );
  }
}
