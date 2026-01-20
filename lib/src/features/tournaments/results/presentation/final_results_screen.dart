import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums.dart';
import '../../../players/domain/player.dart';
import '../../data/tournament_repository.dart';
import '../../domain/tournament.dart';

/// Final results screen shown after tournament ends
class FinalResultsScreen extends ConsumerWidget {
  const FinalResultsScreen({
    super.key,
    required this.tournamentId,
  });

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));

    return tournamentAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (tournament) {
        if (tournament == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Tournament not found')),
          );
        }

        return _FinalResultsContent(tournament: tournament);
      },
    );
  }
}

class _FinalResultsContent extends StatelessWidget {
  const _FinalResultsContent({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winnerSummary = tournament.winnerSummary;
    final leaderboard = tournament.leaderboard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResults(context),
            tooltip: 'Share Results',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tournament header
            _TournamentHeader(tournament: tournament),
            const SizedBox(height: 24),

            // Winner cards
            if (winnerSummary != null) ...[
              _WinnerSection(
                tournament: tournament,
                winnerSummary: winnerSummary,
              ),
              const SizedBox(height: 24),
            ],

            // Leaderboard
            Text(
              'Final Leaderboard',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _LeaderboardList(
              tournament: tournament,
              leaderboard: leaderboard,
            ),
            const SizedBox(height: 24),

            // Share button
            FilledButton.icon(
              onPressed: () => _shareResults(context),
              icon: const Icon(Icons.copy),
              label: const Text('Copy Results to Clipboard'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  void _shareResults(BuildContext context) {
    final text = _buildShareableText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results copied to clipboard!')),
    );
  }

  String _buildShareableText() {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');

    buffer.writeln('🏆 ${tournament.name}');
    buffer.writeln('📅 ${dateFormat.format(tournament.date)}');
    buffer.writeln('🎾 ${tournament.format.displayName}');
    buffer.writeln('🏟️ ${tournament.courtsCount} Courts');
    buffer.writeln('📊 ${tournament.pointsPerMatch} Points/Match');
    buffer.writeln();

    // Stats
    buffer.writeln('📈 Tournament Stats:');
    buffer.writeln('   Completed: ${tournament.totalCompletedMatches}/${tournament.totalScheduledMatches} matches');
    buffer.writeln('   Rounds: ${tournament.completedRounds}/${tournament.totalRounds}');
    buffer.writeln();

    // Winners
    final winnerSummary = tournament.winnerSummary;
    if (winnerSummary != null) {
      buffer.writeln('🏆 WINNERS:');

      // Overall winner
      if (winnerSummary.overallWinnerPlayerId != null) {
        final winner = tournament.getPlayer(winnerSummary.overallWinnerPlayerId!);
        final standing = tournament.getStanding(winnerSummary.overallWinnerPlayerId!);
        if (winner != null && standing != null) {
          buffer.writeln('   🥇 Overall: ${winner.name} (${standing.pointsTotal} pts)');
        }
      }

      // Mixed winners
      if (tournament.format == TournamentFormat.mixedAmericano) {
        if (winnerSummary.mixedTopMalePlayerId != null) {
          final player = tournament.getPlayer(winnerSummary.mixedTopMalePlayerId!);
          final standing = tournament.getStanding(winnerSummary.mixedTopMalePlayerId!);
          if (player != null && standing != null) {
            buffer.writeln('   🥇 Top Male: ${player.name} (${standing.pointsTotal} pts)');
          }
        }
        if (winnerSummary.mixedTopFemalePlayerId != null) {
          final player = tournament.getPlayer(winnerSummary.mixedTopFemalePlayerId!);
          final standing = tournament.getStanding(winnerSummary.mixedTopFemalePlayerId!);
          if (player != null && standing != null) {
            buffer.writeln('   🥇 Top Female: ${player.name} (${standing.pointsTotal} pts)');
          }
        }
      }
      buffer.writeln();
    }

    // Top 10 leaderboard
    buffer.writeln('📊 LEADERBOARD (Top 10):');
    final leaderboard = tournament.leaderboard.take(10);
    int rank = 1;
    for (final standing in leaderboard) {
      final player = tournament.getPlayer(standing.playerId);
      if (player != null) {
        final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '  ';
        buffer.writeln('$medal $rank. ${player.name}: ${standing.pointsTotal} pts (W:${standing.wins} L:${standing.losses})');
      }
      rank++;
    }

    return buffer.toString();
  }
}

class _TournamentHeader extends StatelessWidget {
  const _TournamentHeader({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tournament.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: dateFormat.format(tournament.date),
                ),
                _InfoChip(
                  icon: Icons.sports_tennis,
                  label: tournament.format.displayName,
                ),
                _InfoChip(
                  icon: Icons.grid_view,
                  label: '${tournament.courtsCount} Courts',
                ),
                _InfoChip(
                  icon: Icons.scoreboard,
                  label: '${tournament.totalCompletedMatches}/${tournament.totalScheduledMatches} Matches',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _WinnerSection extends StatelessWidget {
  const _WinnerSection({
    required this.tournament,
    required this.winnerSummary,
  });

  final Tournament tournament;
  final WinnerSummary winnerSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMixed = tournament.format == TournamentFormat.mixedAmericano;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Winners',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Overall winner
        if (winnerSummary.overallWinnerPlayerId != null)
          _WinnerCard(
            tournament: tournament,
            playerId: winnerSummary.overallWinnerPlayerId!,
            title: 'Overall Champion',
            icon: Icons.emoji_events,
            color: Colors.amber,
          ),

        // Mixed format winners
        if (isMixed) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (winnerSummary.mixedTopMalePlayerId != null)
                Expanded(
                  child: _WinnerCard(
                    tournament: tournament,
                    playerId: winnerSummary.mixedTopMalePlayerId!,
                    title: 'Top Male',
                    icon: Icons.male,
                    color: Colors.blue,
                    compact: true,
                  ),
                ),
              const SizedBox(width: 8),
              if (winnerSummary.mixedTopFemalePlayerId != null)
                Expanded(
                  child: _WinnerCard(
                    tournament: tournament,
                    playerId: winnerSummary.mixedTopFemalePlayerId!,
                    title: 'Top Female',
                    icon: Icons.female,
                    color: Colors.pink,
                    compact: true,
                  ),
                ),
            ],
          ),
        ],

        // Top 3 (if more than just winner)
        if (winnerSummary.top3PlayerIds.length > 1) ...[
          const SizedBox(height: 16),
          Text(
            'Podium',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < winnerSummary.top3PlayerIds.length && i < 3; i++)
                _PodiumCard(
                  tournament: tournament,
                  playerId: winnerSummary.top3PlayerIds[i],
                  rank: i + 1,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({
    required this.tournament,
    required this.playerId,
    required this.title,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  final Tournament tournament;
  final String playerId;
  final String title;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = tournament.getPlayer(playerId);
    final standing = tournament.getStanding(playerId);

    if (player == null) return const SizedBox();

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: compact ? 28 : 40),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              player.name,
              style: compact
                  ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                  : theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (standing != null) ...[
              const SizedBox(height: 4),
              Text(
                '${standing.pointsTotal} points',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'W: ${standing.wins} | L: ${standing.losses}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.tournament,
    required this.playerId,
    required this.rank,
  });

  final Tournament tournament;
  final String playerId;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = tournament.getPlayer(playerId);
    final standing = tournament.getStanding(playerId);

    if (player == null) return const SizedBox();

    final color = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey
            : Colors.brown;
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';

    return Column(
      children: [
        Text(medal, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(
          player.name,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (standing != null)
          Text(
            '${standing.pointsTotal} pts',
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
      ],
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({
    required this.tournament,
    required this.leaderboard,
  });

  final Tournament tournament;
  final List<PlayerStanding> leaderboard;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: leaderboard.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final standing = leaderboard[index];
          final player = tournament.getPlayer(standing.playerId);
          final rank = index + 1;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(rank),
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(player?.name ?? 'Unknown'),
            subtitle: Text(
              'W: ${standing.wins} | L: ${standing.losses} | Diff: ${standing.pointsDifferential > 0 ? '+' : ''}${standing.pointsDifferential}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${standing.pointsTotal}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'points',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }
}
