import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// Farbe, nach der die Bibliothek gefiltert wird.
enum LibrarySideFilter { white, black, all }

/// Bibliotheks-Tab. Suche und Filter stehen bereits; die Eröffnungsliste
/// kommt, sobald die Bibliotheksdaten erzeugt sind.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  LibrarySideFilter _side = LibrarySideFilter.white;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;

    return TabScaffold(
      slivers: [
        SliverBox(
          bottom: AppSpacing.xl,
          child: ScreenTitle(l10n.tabLibrary),
        ),
        SliverBox(
          bottom: AppSpacing.xl,
          child: TextField(
            controller: _searchController,
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
            ),
          ),
        ),
        SliverBox(
          bottom: AppSpacing.xl,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppSegmentedControl<LibrarySideFilter>(
              value: _side,
              onChanged: (value) => setState(() => _side = value),
              segments: [
                AppSegment(
                  value: LibrarySideFilter.white,
                  label: l10n.libraryFilterWhite,
                ),
                AppSegment(
                  value: LibrarySideFilter.black,
                  label: l10n.libraryFilterBlack,
                ),
                AppSegment(
                  value: LibrarySideFilter.all,
                  label: l10n.libraryFilterAll,
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: EmptyState(
            icon: PhIcons.books,
            title: l10n.libraryEmptyTitle,
            message: l10n.libraryEmptyMessage,
          ),
        ),
      ],
    );
  }
}
