import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums.dart';
import '../../../../theme/app_theme.dart';
import '../../../scoring/application/scoring_service.dart';
import '../../application/tournament_health_service.dart';
import '../../data/tournament_repository.dart';
import '../../domain/match.dart';
import '../../domain/tournament.dart';

class TournamentDashboardScreen extends ConsumerStatefulWidget {
  const TournamentDashboardScreen({
    super.key,
    required this.tournamentId,
  });

  final String tournamentId;

  @override
  ConsumerState<TournamentDashboardScreen> createState() =>
      _TournamentDashboardScreenState();
}

class _TournamentDashboardScreenState
    extends ConsumerState<TournamentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return tournamentAsync.when(
      data: (tournament) {
        if (tournament == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Tournament')),
            body: const Center(child: Text('Tournament not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(tournament.name),
            actions: [
              if (tournament.status == TournamentStatus.ready)
                FilledButton.icon(
                  onPressed: () => _startTournament(tournament),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
              if (tournament.status == TournamentStatus.inProgress)
                FilledButton.icon(
                  onPressed: () => _endTournament(tournament),
                  icon: const Icon(Icons.stop),
                  label: const Text('End'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (tournament.status == TournamentStatus.completed)
                FilledButton.icon(
                  onPressed: () => context.go('/tournament/${tournament.id}/results'),
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('Results'),
                ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareTournament(tournament),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.sports_tennis), text: 'Rounds'),
                Tab(icon: Icon(Icons.leaderboard), text: 'Standings'),
                Tab(icon: Icon(Icons.people), text: 'Players'),
                Tab(icon: Icon(Icons.settings), text: 'Settings'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _RoundsTab(tournament: tournament, onMatchTap: _onMatchTap),
              _StandingsTab(tournament: tournament),
              _PlayersTab(tournament: tournament),
              _SettingsTab(tournament: tournament),
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

  Future<void> _startTournament(Tournament tournament) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Tournament?'),
        content: const Text(
          'Once started, you cannot modify players or the schedule. '
          'Are you ready to begin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Update first round to in-progress
      final updatedRounds = tournament.rounds.asMap().map((index, round) {
        if (index == 0) {
          return MapEntry(
            index,
            round.copyWith(
              status: RoundStatus.inProgress,
              startedAt: DateTime.now(),
            ),
          );
        }
        return MapEntry(index, round);
      }).values.toList();

      final updated = tournament.copyWith(
        status: TournamentStatus.inProgress,
        startedAt: DateTime.now(),
        rounds: updatedRounds,
      );

      final repository = ref.read(tournamentRepositoryProvider);
      await repository.saveTournament(updated);
      ref.invalidate(tournamentProvider(widget.tournamentId));
    }
  }

  Future<void> _endTournament(Tournament tournament) async {
    final healthService = const TournamentHealthService();
    final health = healthService.computeHealth(tournament);
    final warnings = healthService.getEndWarnings(tournament);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Tournament?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health summary card
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tournament Health',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      _HealthRow(
                        label: 'Completed Matches',
                        value: '${health.completedMatches} / ${health.scheduledMatches}',
                      ),
                      _HealthRow(
                        label: 'Completion',
                        value: '${health.completionPercentage.toStringAsFixed(1)}%',
                      ),
                      _HealthRow(
                        label: 'Incomplete in Current Round',
                        value: '${health.incompleteMatchesInCurrentRound}',
                      ),
                      _HealthRow(
                        label: 'Rounds Completed',
                        value: '${health.completedRounds} / ${health.scheduledRounds}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Warnings
              if (warnings.isNotEmpty) ...[
                Text(
                  'Warnings:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 4),
                ...warnings.map((w) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.warning, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(w, style: Theme.of(context).textTheme.bodySmall)),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              const Text(
                'Ending the tournament will:\n'
                '• Calculate final standings from completed matches\n'
                '• Determine winners\n'
                '• Lock further score edits (unless allowed in settings)',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End Tournament'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(tournamentRepositoryProvider);
      await repository.endTournament(tournament.id);
      ref.invalidate(tournamentProvider(widget.tournamentId));
      if (mounted) {
        context.go('/tournament/${tournament.id}/results');
      }
    }
  }

  void _onMatchTap(Tournament tournament, Match match) {
    if (tournament.status == TournamentStatus.inProgress ||
        tournament.status == TournamentStatus.completed) {
      context.go('/tournament/${tournament.id}/match/${match.id}/score');
    }
  }

  void _shareTournament(Tournament tournament) {
    // Generate shareable text summary
    final buffer = StringBuffer();
    buffer.writeln('🏆 ${tournament.name}');
    buffer.writeln('📅 ${tournament.date.day}/${tournament.date.month}/${tournament.date.year}');
    buffer.writeln('🎾 ${tournament.format.displayName}');
    buffer.writeln('');
    buffer.writeln('📊 Standings:');

    final leaderboard = tournament.leaderboard;
    for (var i = 0; i < leaderboard.length && i < 5; i++) {
      final standing = leaderboard[i];
      final player = tournament.getPlayer(standing.playerId);
      if (player != null) {
        buffer.writeln('${i + 1}. ${player.name} - ${standing.pointsTotal} pts');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Results copied to clipboard'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}

// Rounds Tab
class _RoundsTab extends StatelessWidget {
  const _RoundsTab({
    required this.tournament,
    required this.onMatchTap,
  });

  final Tournament tournament;
  final void Function(Tournament, Match) onMatchTap;

  @override
  Widget build(BuildContext context) {
    if (tournament.rounds.isEmpty) {
      return const Center(
        child: Text('No rounds scheduled'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournament.rounds.length,
      itemBuilder: (context, index) {
        final round = tournament.rounds[index];
        return _RoundCard(
          round: round,
          tournament: tournament,
          onMatchTap: (match) => onMatchTap(tournament, match),
        );
      },
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({
    required this.round,
    required this.tournament,
    required this.onMatchTap,
  });

  final Round round;
  final Tournament tournament;
  final void Function(Match) onMatchTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = round.status == RoundStatus.inProgress;
    final isCompleted = round.status == RoundStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primaryContainer
                  : isCompleted
                      ? colorScheme.surfaceContainerHighest
                      : null,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isActive
                          ? Icons.play_circle
                          : Icons.schedule,
                  color: isCompleted
                      ? Colors.green
                      : isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Round ${round.index + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '${round.completedMatchesCount}/${round.matches.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          // Matches
          ...round.matches.map((match) {
            return _MatchTile(
              match: match,
              tournament: tournament,
              onTap: () => onMatchTap(match),
            );
          }),
          // Byes
          if (round.byes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.pause_circle_outline,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bye: ${round.byes.map((b) => tournament.getPlayer(b.playerId)?.name ?? "?").join(", ")}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.match,
    required this.tournament,
    required this.onTap,
  });

  final Match match;
  final Tournament tournament;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final courtColor = match.courtIndex.courtColor;

    final p1 = tournament.getPlayer(match.teamA.player1Id);
    final p2 = tournament.getPlayer(match.teamA.player2Id);
    final p3 = tournament.getPlayer(match.teamB.player1Id);
    final p4 = tournament.getPlayer(match.teamB.player2Id);

    final teamAName = '${p1?.name ?? "?"} & ${p2?.name ?? "?"}';
    final teamBName = '${p3?.name ?? "?"} & ${p4?.name ?? "?"}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Court indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: courtColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${match.courtIndex + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: courtColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Teams
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamAName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: match.isComplete && match.scoreA! > match.scoreB!
                              ? FontWeight.bold
                              : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teamBName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: match.isComplete && match.scoreB! > match.scoreA!
                              ? FontWeight.bold
                              : null,
                        ),
                  ),
                ],
              ),
            ),
            // Score
            if (match.isComplete)
              Column(
                children: [
                  Text(
                    '${match.scoreA}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: match.scoreA! > match.scoreB!
                              ? Colors.green
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '${match.scoreB}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: match.scoreB! > match.scoreA!
                              ? Colors.green
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              )
            else
              Icon(
                Icons.edit,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

// Standings Tab
class _StandingsTab extends StatelessWidget {
  const _StandingsTab({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final leaderboard = tournament.leaderboard;

    if (leaderboard.isEmpty) {
      return const Center(
        child: Text('No standings yet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final standing = leaderboard[index];
        final player = tournament.getPlayer(standing.playerId);

        return _StandingTile(
          rank: index + 1,
          player: player,
          standing: standing,
          isTopMale: tournament.format == TournamentFormat.mixedAmericano &&
              player?.gender == Gender.male &&
              _isTopOfGender(leaderboard, standing, Gender.male, tournament),
          isTopFemale: tournament.format == TournamentFormat.mixedAmericano &&
              player?.gender == Gender.female &&
              _isTopOfGender(leaderboard, standing, Gender.female, tournament),
        );
      },
    );
  }

  bool _isTopOfGender(
    List<PlayerStanding> leaderboard,
    PlayerStanding standing,
    Gender gender,
    Tournament tournament,
  ) {
    for (final s in leaderboard) {
      final p = tournament.getPlayer(s.playerId);
      if (p?.gender == gender) {
        return s.playerId == standing.playerId;
      }
    }
    return false;
  }
}

class _StandingTile extends StatelessWidget {
  const _StandingTile({
    required this.rank,
    required this.player,
    required this.standing,
    this.isTopMale = false,
    this.isTopFemale = false,
  });

  final int rank;
  final dynamic player;
  final PlayerStanding standing;
  final bool isTopMale;
  final bool isTopFemale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color? backgroundColor;
    if (rank == 1) {
      backgroundColor = Colors.amber.withOpacity(0.1);
    } else if (rank == 2) {
      backgroundColor = Colors.grey.shade300.withOpacity(0.3);
    } else if (rank == 3) {
      backgroundColor = Colors.brown.withOpacity(0.1);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: backgroundColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rank <= 3
              ? [Colors.amber, Colors.grey, Colors.brown][rank - 1]
              : colorScheme.surfaceContainerHighest,
          foregroundColor: rank <= 3 ? Colors.white : null,
          child: Text('$rank'),
        ),
        title: Row(
          children: [
            Text(player?.name ?? 'Unknown'),
            if (isTopMale) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '👑 Top Male',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
            if (isTopFemale) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '👑 Top Female',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${standing.matchesPlayed} matches • W${standing.wins} L${standing.losses}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${standing.pointsTotal}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
            Text(
              'pts',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Players Tab
class _PlayersTab extends StatelessWidget {
  const _PlayersTab({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final players = tournament.players;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final standing = tournament.getStanding(player.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getGenderColor(player.gender).withOpacity(0.2),
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: _getGenderColor(player.gender),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(player.name),
            subtitle: Text(
              player.gender != Gender.unspecified
                  ? player.gender.displayName
                  : 'No gender specified',
            ),
            trailing: standing != null
                ? Text(
                    '${standing.pointsTotal} pts',
                    style: Theme.of(context).textTheme.titleMedium,
                  )
                : null,
          ),
        );
      },
    );
  }

  Color _getGenderColor(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Colors.blue;
      case Gender.female:
        return Colors.pink;
      case Gender.unspecified:
        return Colors.grey;
    }
  }
}

// Settings Tab
class _SettingsTab extends ConsumerWidget {
  const _SettingsTab({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tournament Info',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Name', value: tournament.name),
                _InfoRow(
                  label: 'Date',
                  value:
                      '${tournament.date.day}/${tournament.date.month}/${tournament.date.year}',
                ),
                _InfoRow(label: 'Mode', value: tournament.settings?.mode.displayName ?? 'Open-Ended'),
                _InfoRow(label: 'Format', value: tournament.format.displayName),
                _InfoRow(label: 'Courts', value: '${tournament.courtsCount}'),
                _InfoRow(
                  label: 'Points per Match',
                  value: '${tournament.pointsPerMatch}',
                ),
                _InfoRow(label: 'Status', value: tournament.status.displayName),
                _InfoRow(label: 'Players', value: '${tournament.activePlayerCount}'),
                _InfoRow(label: 'Rounds', value: '${tournament.totalRounds}'),
                if (tournament.settings?.plannedRounds != null)
                  _InfoRow(label: 'Planned Rounds', value: '${tournament.settings!.plannedRounds}'),
                if (tournament.settings?.totalMinutes != null)
                  _InfoRow(label: 'Planned Duration', value: '${tournament.settings!.totalMinutes} min'),
                if (tournament.seed != null)
                  _InfoRow(label: 'Seed', value: '${tournament.seed}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Quick Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (tournament.status != TournamentStatus.completed) ...[
                  ListTile(
                    leading: const Icon(Icons.refresh, color: Colors.orange),
                    title: const Text('Reset All Scores'),
                    subtitle: const Text('Clear scores but keep schedule'),
                    onTap: () => _resetTournament(context, ref),
                  ),
                ],
                ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Advanced Settings'),
                  subtitle: const Text('Danger zone, export options'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/tournament/${tournament.id}/settings'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _resetTournament(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Scores?'),
        content: const Text(
          'This will clear all match scores and standings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Reset all matches and standings
      final resetRounds = tournament.rounds.map((round) {
        final resetMatches = round.matches.map((match) {
          return match.copyWith(
            scoreA: null,
            scoreB: null,
            status: MatchStatus.scheduled,
            startedAt: null,
            completedAt: null,
          );
        }).toList();

        return round.copyWith(
          matches: resetMatches,
          status: RoundStatus.pending,
          startedAt: null,
          completedAt: null,
        );
      }).toList();

      final resetStandings = tournament.players
          .map((p) => PlayerStanding(playerId: p.id))
          .toList();

      final updated = tournament.copyWith(
        rounds: resetRounds,
        standings: resetStandings,
        status: TournamentStatus.ready,
        startedAt: null,
        completedAt: null,
      );

      final repository = ref.read(tournamentRepositoryProvider);
      await repository.saveTournament(updated);
      ref.invalidate(tournamentProvider(tournament.id));
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
