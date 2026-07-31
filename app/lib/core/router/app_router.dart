import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:masteropening/core/router/app_routes.dart';
import 'package:masteropening/core/router/app_shell.dart';
import 'package:masteropening/features/analysis/presentation/repair_screen.dart';
import 'package:masteropening/features/antiprep/presentation/antiprep_screen.dart';
import 'package:masteropening/features/gamification/presentation/achievements_screen.dart';
import 'package:masteropening/features/gamification/presentation/stats_screen.dart';
import 'package:masteropening/features/home/presentation/home_screen.dart';
import 'package:masteropening/features/learn/presentation/study_screen.dart';
import 'package:masteropening/features/library/presentation/library_screen.dart';
import 'package:masteropening/features/library/presentation/opening_detail_screen.dart';
import 'package:masteropening/features/lichess/presentation/lichess_screen.dart';
import 'package:masteropening/features/repertoire/presentation/import_pgn_screen.dart';
import 'package:masteropening/features/repertoire/presentation/repertoire_edit_screen.dart';
import 'package:masteropening/features/settings/presentation/settings_screen.dart';
import 'package:masteropening/features/style/presentation/style_screen.dart';
import 'package:masteropening/features/training/presentation/mode_picker_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'import',
                    name: Routes.repertoireImportName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ImportPgnScreen(),
                  ),
                  GoRoute(
                    path: 'repertoire/:id/edit',
                    name: Routes.repertoireEditName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) return const _RouteErrorScreen();
                      return RepertoireEditScreen(repertoireId: id);
                    },
                  ),
                  GoRoute(
                    path: 'repertoire/:id/train',
                    name: Routes.trainingSetupName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) return const _RouteErrorScreen();
                      return ModePickerScreen(repertoireId: id);
                    },
                  ),
                  GoRoute(
                    path: 'stats',
                    name: Routes.statsName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const StatsScreen(),
                  ),
                  GoRoute(
                    path: 'achievements',
                    name: Routes.achievementsName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AchievementsScreen(),
                  ),
                  GoRoute(
                    path: 'repertoire/:id/learn',
                    name: Routes.repertoireLearnName,
                    // Ausserhalb der Shell: der Lern-Modus füllt den ganzen
                    // Bildschirm, die Tab-Leiste würde nur Platz kosten.
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = int.tryParse(
                        state.pathParameters['id'] ?? '',
                      );
                      if (id == null) {
                        return const _RouteErrorScreen();
                      }
                      return StudyScreen(repertoireId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.library,
                builder: (context, state) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: ':openingId',
                    name: Routes.libraryDetailName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => OpeningDetailScreen(
                      openingId: state.pathParameters['openingId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.lichess,
                builder: (context, state) => const LichessScreen(),
                routes: [
                  GoRoute(
                    path: 'gaps',
                    name: Routes.lichessGapsName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const RepairScreen(),
                  ),
                  GoRoute(
                    path: 'anti-prep',
                    name: Routes.antiPrepName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AntiPrepScreen(),
                  ),
                  GoRoute(
                    path: 'style',
                    name: Routes.styleAdviceName,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const StyleScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
  );

  ref.onDispose(router.dispose);
  return router;
});

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Diese Seite gibt es nicht.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (error != null)
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Zum Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
