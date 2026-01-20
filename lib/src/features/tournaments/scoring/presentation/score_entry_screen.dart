import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums.dart';
import '../../../scoring/application/scoring_service.dart';
import '../../data/tournament_repository.dart';
import '../../domain/match.dart';
import '../../domain/tournament.dart';

class ScoreEntryScreen extends ConsumerStatefulWidget {
  const ScoreEntryScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  final String tournamentId;
  final String matchId;

  @override
  ConsumerState<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

class _ScoreEntryScreenState extends ConsumerState<ScoreEntryScreen> {
  late int _scoreA;
  late int _scoreB;
  bool _isSaving = false;
  late bool _lockTotalPoints;
  bool _isUpdating = false; // Guard against infinite loops

  @override
  void initState() {
    super.initState();
    _scoreA = 0;
    _scoreB = 0;
    _lockTotalPoints = true; // Will be updated from settings
  }

  void _updateScoreA(int score, int totalPoints) {
    if (_isUpdating) return;
    _isUpdating = true;
    setState(() {
      _scoreA = score;
      if (_lockTotalPoints) {
        _scoreB = (totalPoints - _scoreA).clamp(0, totalPoints);
      }
    });
    _isUpdating = false;
    HapticFeedback.selectionClick();
  }

  void _updateScoreB(int score, int totalPoints) {
    if (_isUpdating) return;
    _isUpdating = true;
    setState(() {
      _scoreB = score;
      if (_lockTotalPoints) {
        _scoreA = (totalPoints - _scoreB).clamp(0, totalPoints);
      }
    });
    _isUpdating = false;
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return tournamentAsync.when(
      data: (tournament) {
        if (tournament == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Score Entry')),
            body: const Center(child: Text('Tournament not found')),
          );
        }

        final scoringService = const ScoringService();
        final match = scoringService.getMatch(tournament, widget.matchId);

        if (match == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Score Entry')),
            body: const Center(child: Text('Match not found')),
          );
        }

        // Initialize scores from existing match data
        if (match.scoreA != null && _scoreA == 0 && _scoreB == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _scoreA = match.scoreA!;
              _scoreB = match.scoreB!;
            });
          });
        }

        final isValid =
            scoringService.validateScores(_scoreA, _scoreB, tournament.pointsPerMatch);
        final remaining = tournament.pointsPerMatch - _scoreA - _scoreB;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Court ${match.courtIndex + 1}'),
                Text(
                  'Round ${match.roundIndex + 1}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Score display
                Expanded(
                  child: Row(
                    children: [
                      // Team A
                      Expanded(
                        child: _TeamScorePanel(
                          teamLabel: 'Team A',
                          players: [
                            tournament.getPlayer(match.teamA.player1Id),
                            tournament.getPlayer(match.teamA.player2Id),
                          ],
                          score: _scoreA,
                          maxScore: tournament.pointsPerMatch,
                          color: Theme.of(context).colorScheme.primary,
                          onScoreChanged: (score) => _updateScoreA(score, tournament.pointsPerMatch),
                        ),
                      ),
                      // Divider
                      Container(
                        width: 2,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      // Team B
                      Expanded(
                        child: _TeamScorePanel(
                          teamLabel: 'Team B',
                          players: [
                            tournament.getPlayer(match.teamB.player1Id),
                            tournament.getPlayer(match.teamB.player2Id),
                          ],
                          score: _scoreB,
                          maxScore: tournament.pointsPerMatch,
                          color: Theme.of(context).colorScheme.secondary,
                          onScoreChanged: (score) => _updateScoreB(score, tournament.pointsPerMatch),
                        ),
                      ),
                    ],
                  ),
                ),
                // Lock toggle and validation message
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 20),
                      const SizedBox(width: 8),
                      const Text('Lock total points'),
                      const SizedBox(width: 8),
                      Switch(
                        value: _lockTotalPoints,
                        onChanged: (value) => setState(() => _lockTotalPoints = value),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: _lockTotalPoints 
                            ? 'Adjusting one score will auto-set the other'
                            : 'Scores can be set independently',
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                // Validation banner
                Container(
                  padding: const EdgeInsets.all(16),
                  color: isValid
                      ? Colors.green.withOpacity(0.1)
                      : !_lockTotalPoints && remaining != 0
                          ? Theme.of(context).colorScheme.tertiaryContainer
                          : Theme.of(context).colorScheme.errorContainer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isValid 
                            ? Icons.check_circle 
                            : !_lockTotalPoints && remaining != 0
                                ? Icons.warning_amber
                                : Icons.info_outline,
                        color: isValid
                            ? Colors.green
                            : !_lockTotalPoints && remaining != 0
                                ? Theme.of(context).colorScheme.onTertiaryContainer
                                : Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isValid
                              ? 'Scores are valid ($_scoreA + $_scoreB = ${tournament.pointsPerMatch})'
                              : !_lockTotalPoints && remaining != 0
                                  ? 'Warning: Total ≠ ${tournament.pointsPerMatch} (${_scoreA + _scoreB} entered)'
                                  : remaining > 0
                                      ? '$remaining points remaining'
                                      : '${-remaining} points over limit',
                          style: TextStyle(
                            color: isValid
                                ? Colors.green
                                : !_lockTotalPoints && remaining != 0
                                    ? Theme.of(context).colorScheme.onTertiaryContainer
                                    : Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // Save button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isValid && !_isSaving
                          ? () => _saveScore(tournament, match)
                          : null,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Score'),
                    ),
                  ),
                ),
              ],
            ),
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

  Future<void> _saveScore(Tournament tournament, Match match) async {
    setState(() => _isSaving = true);

    try {
      final scoringService = const ScoringService();
      final updated = scoringService.updateMatchScore(
        tournament: tournament,
        matchId: match.id,
        scoreA: _scoreA,
        scoreB: _scoreB,
      );

      // Check if we need to start the next round
      final currentRoundIndex = match.roundIndex;
      var finalTournament = updated;

      // If current round is complete, start next round if available
      final currentRound = updated.rounds[currentRoundIndex];
      if (currentRound.status == RoundStatus.completed) {
        final nextRoundIndex = currentRoundIndex + 1;
        if (nextRoundIndex < updated.rounds.length) {
          final updatedRounds = updated.rounds.asMap().map((index, round) {
            if (index == nextRoundIndex) {
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

          finalTournament = updated.copyWith(rounds: updatedRounds);
        }
      }

      final repository = ref.read(tournamentRepositoryProvider);
      await repository.saveTournament(finalTournament);
      ref.invalidate(tournamentProvider(widget.tournamentId));

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save score: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _TeamScorePanel extends StatelessWidget {
  const _TeamScorePanel({
    required this.teamLabel,
    required this.players,
    required this.score,
    required this.maxScore,
    required this.color,
    required this.onScoreChanged,
  });

  final String teamLabel;
  final List<dynamic> players;
  final int score;
  final int maxScore;
  final Color color;
  final ValueChanged<int> onScoreChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.05),
      child: Column(
        children: [
          // Team header
          Container(
            padding: const EdgeInsets.all(16),
            color: color.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  teamLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  players[0]?.name ?? '?',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                Text(
                  players[1]?.name ?? '?',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Score
          Expanded(
            child: Center(
              child: Text(
                '$score',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ),
          ),
          // Score controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScoreButton(
                  icon: Icons.remove,
                  onPressed: score > 0 ? () => onScoreChanged(score - 1) : null,
                  color: color,
                ),
                _ScoreButton(
                  icon: Icons.add,
                  onPressed:
                      score < maxScore ? () => onScoreChanged(score + 1) : null,
                  color: color,
                ),
              ],
            ),
          ),
          // Quick score buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [0, 6, 8, 10, 12, 14, 16, 18].where((s) => s <= maxScore).map((s) {
                return ActionChip(
                  label: Text('$s'),
                  onPressed: () => onScoreChanged(s),
                  backgroundColor: score == s ? color.withOpacity(0.2) : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  const _ScoreButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: 32),
      ),
    );
  }
}

// Extension to add subtitle to AppBar
extension AppBarExtension on AppBar {
  AppBar copyWith({Widget? subtitle}) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (title != null) title!,
          if (subtitle != null)
            DefaultTextStyle(
              style: const TextStyle(fontSize: 12),
              child: subtitle,
            ),
        ],
      ),
      leading: leading,
      actions: actions,
    );
  }
}
