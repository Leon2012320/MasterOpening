import 'dart:async';

import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masteropening/chess/pgn_io.dart';
import 'package:masteropening/chess/san_notation.dart';
import 'package:masteropening/core/db/enums.dart';
import 'package:masteropening/core/router/app_routes.dart';
import 'package:masteropening/core/theme/app_dimens.dart';
import 'package:masteropening/core/theme/app_tokens.dart';
import 'package:masteropening/core/theme/ph_icons.dart';
import 'package:masteropening/core/widgets/widgets.dart';
import 'package:masteropening/features/repertoire/data/repertoire_providers.dart';
import 'package:masteropening/l10n/generated/app_localizations.dart';

/// PGN einfügen und als Repertoire übernehmen.
///
/// Die Vorschau läuft mit: sobald Text im Feld steht, zeigt der Bildschirm,
/// wie viele Züge und Varianten erkannt wurden und welche Züge übersprungen
/// werden mussten. Erst danach lässt sich importieren.
class ImportPgnScreen extends ConsumerStatefulWidget {
  const ImportPgnScreen({super.key});

  @override
  ConsumerState<ImportPgnScreen> createState() => _ImportPgnScreenState();
}

class _ImportPgnScreenState extends ConsumerState<ImportPgnScreen> {
  final _pgnController = TextEditingController();
  final _nameController = TextEditingController();

  Side _side = Side.white;
  PgnImportResult? _preview;
  bool _importing = false;

  /// Ob der Name von Hand gesetzt wurde — dann überschreibt ihn die Vorschau
  /// nicht mehr.
  bool _nameTouched = false;

  @override
  void dispose() {
    _pgnController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onPgnChanged(String text) {
    if (text.trim().isEmpty) {
      setState(() => _preview = null);
      return;
    }

    final result = PgnIo.parseStudy(text);
    setState(() {
      _preview = result;
      if (!_nameTouched) _nameController.text = result.suggestedName;
    });
  }

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null || preview.tree.isEmpty) return;

    final router = GoRouter.of(context);
    final name = _nameController.text.trim();

    setState(() => _importing = true);
    try {
      final id = await ref
          .read(repertoireRepositoryProvider)
          .create(
            name: name.isEmpty ? preview.suggestedName : name,
            side: _side,
            tree: preview.tree,
            source: RepertoireSource.pgnImport,
            ecoCodes: preview.eco ?? '',
          );
      router.pop();
      unawaited(router.push(Routes.repertoireLearn(id)));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    final preview = _preview;
    final tree = preview?.tree;
    final canImport = tree != null && tree.isNotEmpty && !_importing;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xl,
          AppSpacing.screen,
          AppSpacing.huge,
        ),
        children: [
          TextField(
            controller: _pgnController,
            onChanged: _onPgnChanged,
            maxLines: 8,
            minLines: 5,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              hintText: l10n.importPaste,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          if (tree == null)
            Text(
              l10n.importEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textAlpha(0.55),
              ),
            )
          else ...[
            Row(
              children: [
                Icon(
                  tree.isEmpty ? PhIcons.warning : PhIcons.check,
                  size: 15,
                  color: tree.isEmpty ? tokens.warning : tokens.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    tree.isEmpty
                        ? l10n.importEmpty
                        : l10n.importMovesFound(
                            tree.nodeCount,
                            tree.lines().length,
                          ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (preview!.warnings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.importWarnings(preview.warnings.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.warning,
                ),
              ),
            ],
            if (tree.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                SanNotation.localizeAll(
                  [for (final node in tree.lines().first.nodes) node.san],
                  language,
                ).take(12).join(' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textAlpha(0.55),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],

          const SizedBox(height: AppSpacing.xxl),
          SectionLabel(l10n.importName),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _nameController,
            onChanged: (_) => _nameTouched = true,
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: AppSpacing.xl),
          SectionLabel(l10n.importSide),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: AppSegmentedControl<Side>(
              value: _side,
              onChanged: (value) => setState(() => _side = value),
              segments: [
                AppSegment(
                  value: Side.white,
                  label: SanNotation.sideLabel(Side.white, language),
                ),
                AppSegment(
                  value: Side.black,
                  label: SanNotation.sideLabel(Side.black, language),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.huge),
          AppButton.block(
            label: l10n.importAction,
            icon: PhIcons.plus,
            busy: _importing,
            onPressed: canImport ? _import : null,
          ),
        ],
      ),
    );
  }
}
