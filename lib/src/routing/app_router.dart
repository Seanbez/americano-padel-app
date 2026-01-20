import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/app_settings_screen.dart';
import '../features/tournaments/create/presentation/create_tournament_screen.dart';
import '../features/tournaments/manage/presentation/tournament_dashboard_screen.dart';
import '../features/tournaments/results/presentation/final_results_screen.dart';
import '../features/tournaments/scoring/presentation/score_entry_screen.dart';
import '../features/tournaments/settings/presentation/tournament_settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'appSettings',
        builder: (context, state) => const AppSettingsScreen(),
      ),
      GoRoute(
        path: '/tournament/create',
        name: 'createTournament',
        builder: (context, state) => const CreateTournamentScreen(),
      ),
      GoRoute(
        path: '/tournament/:id',
        name: 'tournamentDashboard',
        builder: (context, state) {
          final tournamentId = state.pathParameters['id']!;
          return TournamentDashboardScreen(tournamentId: tournamentId);
        },
        routes: [
          GoRoute(
            path: 'match/:matchId/score',
            name: 'scoreEntry',
            builder: (context, state) {
              final tournamentId = state.pathParameters['id']!;
              final matchId = state.pathParameters['matchId']!;
              return ScoreEntryScreen(
                tournamentId: tournamentId,
                matchId: matchId,
              );
            },
          ),
          GoRoute(
            path: 'settings',
            name: 'tournamentSettings',
            builder: (context, state) {
              final tournamentId = state.pathParameters['id']!;
              return TournamentSettingsScreen(tournamentId: tournamentId);
            },
          ),
          GoRoute(
            path: 'results',
            name: 'finalResults',
            builder: (context, state) {
              final tournamentId = state.pathParameters['id']!;
              return FinalResultsScreen(tournamentId: tournamentId);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
