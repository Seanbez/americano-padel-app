import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/tournament.dart';
import '../../data/tournament_repository.dart';

/// Tournament Settings screen with reset flows and danger zone operations.
class TournamentSettingsScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentSettingsScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentSettingsScreen> createState() =>
      _TournamentSettingsScreenState();
}

class _TournamentSettingsScreenState
    extends ConsumerState<TournamentSettingsScreen> {
  bool _allowEditsAfterEnd = true;

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return tournamentAsync.when(
      data: (tournament) {
        if (tournament == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: const Center(child: Text('Tournament not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tournament Settings'),
          ),
          body: ListView(
            children: [
              // General Settings Section
              _buildSectionHeader(context, 'General Settings'),
              SwitchListTile(
                title: const Text('Allow Edits After End'),
                subtitle: const Text(
                  'When enabled, scores can still be modified after tournament ends',
                ),
                value: _allowEditsAfterEnd,
                onChanged: (value) {
                  setState(() => _allowEditsAfterEnd = value);
                  // TODO: Persist to tournament settings
                },
              ),
              const Divider(),

              // Tournament Info Section
              _buildSectionHeader(context, 'Tournament Information'),
              ListTile(
                title: const Text('Tournament Mode'),
                subtitle: Text(tournament.settings?.mode.displayName ?? 'Open-Ended'),
                leading: const Icon(Icons.sports_tennis),
              ),
              ListTile(
                title: const Text('Status'),
                subtitle: Text(tournament.status.name.toUpperCase()),
                leading: const Icon(Icons.flag),
              ),
              ListTile(
                title: const Text('Matches'),
                subtitle: Text(
                  '${tournament.totalCompletedMatches} of ${tournament.totalScheduledMatches} completed',
                ),
                leading: const Icon(Icons.scoreboard),
              ),
              const Divider(),

              // Danger Zone Section
              _buildSectionHeader(context, 'Danger Zone', isWarning: true),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'These actions cannot be undone. Please proceed with caution.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              // Reset Tournament Results
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text('Reset Tournament Results'),
                subtitle: const Text(
                  'Clear all scores but keep the schedule intact',
                ),
                onTap: () => _showResetResultsDialog(context, tournament),
              ),

              // Clear All Data
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Clear All Tournament Data'),
                subtitle: const Text(
                  'Delete this tournament completely',
                ),
                onTap: () => _showClearAllDialog(context, tournament),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isWarning
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _showResetResultsDialog(
      BuildContext context, Tournament tournament) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reset Tournament Results'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will clear all scores from all matches while keeping the schedule intact.\n\n'
              'Player standings will be reset to zero.',
            ),
            const SizedBox(height: 16),
            Text(
              'Type RESET to confirm:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'RESET',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () {
              if (controller.text.trim().toUpperCase() == 'RESET') {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type RESET to confirm'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reset Results'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(tournamentRepositoryProvider);
        await repository.resetTournamentResultsKeepSchedule(tournament.id);
        ref.invalidate(tournamentProvider(widget.tournamentId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tournament results have been reset'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showClearAllDialog(
      BuildContext context, Tournament tournament) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Tournament'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete this tournament including:\n'
              '• All players\n'
              '• All matches and scores\n'
              '• All standings\n\n'
              'This action cannot be undone.',
            ),
            const SizedBox(height: 16),
            Text(
              'Type DELETE to confirm:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'DELETE',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              if (controller.text.trim().toUpperCase() == 'DELETE') {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type DELETE to confirm'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete Tournament'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(tournamentRepositoryProvider);
        await repository.clearAllLocalData();
        if (mounted) {
          context.go('/'); // Navigate to home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tournament has been deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
