import '../../../core/enums.dart';
import '../../tournaments/domain/match.dart';
import '../../tournaments/domain/tournament.dart';

/// Health status DTO for tournament monitoring
class TournamentHealth {
  const TournamentHealth({
    required this.scheduledMatches,
    required this.completedMatches,
    required this.incompleteMatchesInCurrentRound,
    required this.scheduledRounds,
    required this.completedRounds,
    required this.roundsWithIncompleteMatches,
    required this.currentRoundIndex,
    required this.playersWithoutMatch,
  });

  final int scheduledMatches;
  final int completedMatches;
  final int incompleteMatchesInCurrentRound;
  final int scheduledRounds;
  final int completedRounds;
  final int roundsWithIncompleteMatches;
  final int currentRoundIndex;
  final int playersWithoutMatch;

  /// Percentage of matches completed
  double get completionPercentage =>
      scheduledMatches > 0 ? (completedMatches / scheduledMatches) * 100 : 0;

  /// Check if tournament is fully complete
  bool get isFullyComplete =>
      completedMatches == scheduledMatches && scheduledMatches > 0;

  /// Check if current round is complete
  bool get isCurrentRoundComplete => incompleteMatchesInCurrentRound == 0;

  /// Incomplete matches total
  int get incompleteMatches => scheduledMatches - completedMatches;

  /// Health status level
  HealthLevel get healthLevel {
    if (isFullyComplete) return HealthLevel.complete;
    if (completionPercentage >= 80) return HealthLevel.good;
    if (completionPercentage >= 50) return HealthLevel.moderate;
    return HealthLevel.low;
  }

  /// Create a summary string for confirmation dialogs
  String toSummary() {
    final buffer = StringBuffer();
    buffer.writeln('Completed: $completedMatches / $scheduledMatches matches');
    buffer.writeln('Completion: ${completionPercentage.toStringAsFixed(1)}%');
    if (incompleteMatchesInCurrentRound > 0) {
      buffer.writeln('Incomplete in current round: $incompleteMatchesInCurrentRound');
    }
    buffer.writeln('Rounds: $completedRounds / $scheduledRounds completed');
    return buffer.toString();
  }

  @override
  String toString() =>
      'TournamentHealth(completed: $completedMatches/$scheduledMatches, '
      'currentRound: $currentRoundIndex, incomplete: $incompleteMatchesInCurrentRound)';
}

/// Health level indicator
enum HealthLevel {
  complete('Complete', '✓'),
  good('Good', '●'),
  moderate('Moderate', '◐'),
  low('Low', '○');

  const HealthLevel(this.displayName, this.indicator);

  final String displayName;
  final String indicator;
}

/// Service for computing tournament health metrics
class TournamentHealthService {
  const TournamentHealthService();

  /// Compute comprehensive health metrics for a tournament
  TournamentHealth computeHealth(Tournament tournament) {
    final rounds = tournament.rounds;
    
    // Count scheduled and completed matches
    int scheduledMatches = 0;
    int completedMatches = 0;
    int roundsWithIncomplete = 0;

    for (final round in rounds) {
      for (final match in round.matches) {
        scheduledMatches++;
        if (match.status == MatchStatus.completed || match.status == MatchStatus.bye) {
          completedMatches++;
        }
      }
      
      // Check if this round has any incomplete matches
      final roundIncomplete = round.matches.any(
        (m) => m.status != MatchStatus.completed && m.status != MatchStatus.bye,
      );
      if (roundIncomplete) {
        roundsWithIncomplete++;
      }
    }

    // Find current round (first round with incomplete matches)
    int currentRoundIndex = _findCurrentRoundIndex(rounds);

    // Count incomplete matches in current round
    int incompleteInCurrentRound = 0;
    if (currentRoundIndex >= 0 && currentRoundIndex < rounds.length) {
      incompleteInCurrentRound = rounds[currentRoundIndex].matches.where(
        (m) => m.status != MatchStatus.completed && m.status != MatchStatus.bye,
      ).length;
    }

    // Count completed rounds
    final completedRounds = rounds.where(
      (r) => r.status == RoundStatus.completed,
    ).length;

    // Players without any match in schedule (edge case)
    final playersWithoutMatch = _countPlayersWithoutMatch(tournament);

    return TournamentHealth(
      scheduledMatches: scheduledMatches,
      completedMatches: completedMatches,
      incompleteMatchesInCurrentRound: incompleteInCurrentRound,
      scheduledRounds: rounds.length,
      completedRounds: completedRounds,
      roundsWithIncompleteMatches: roundsWithIncomplete,
      currentRoundIndex: currentRoundIndex,
      playersWithoutMatch: playersWithoutMatch,
    );
  }

  /// Find the index of the current round (first with incomplete matches)
  int _findCurrentRoundIndex(List<Round> rounds) {
    for (int i = 0; i < rounds.length; i++) {
      final round = rounds[i];
      final hasIncomplete = round.matches.any(
        (m) => m.status != MatchStatus.completed && m.status != MatchStatus.bye,
      );
      if (hasIncomplete) {
        return i;
      }
    }
    // All complete, return last round index
    return rounds.isNotEmpty ? rounds.length - 1 : -1;
  }

  /// Count players who have no matches scheduled
  int _countPlayersWithoutMatch(Tournament tournament) {
    final playerIds = tournament.activePlayers.map((p) => p.id).toSet();
    final playersInMatches = <String>{};

    for (final round in tournament.rounds) {
      for (final match in round.matches) {
        playersInMatches.addAll(match.teamA.playerIds);
        playersInMatches.addAll(match.teamB.playerIds);
      }
    }

    return playerIds.difference(playersInMatches).length;
  }

  /// Check if tournament is ready to be ended
  bool canEndTournament(Tournament tournament) {
    // Must have at least one completed match
    final health = computeHealth(tournament);
    return health.completedMatches > 0;
  }

  /// Get warning messages for ending tournament
  List<String> getEndWarnings(Tournament tournament) {
    final warnings = <String>[];
    final health = computeHealth(tournament);

    if (health.incompleteMatches > 0) {
      warnings.add('${health.incompleteMatches} matches are incomplete and will not count');
    }

    if (health.incompleteMatchesInCurrentRound > 0) {
      warnings.add('${health.incompleteMatchesInCurrentRound} matches in current round are unfinished');
    }

    if (health.completionPercentage < 50) {
      warnings.add('Less than 50% of matches completed');
    }

    return warnings;
  }
}
