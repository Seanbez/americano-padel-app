import '../../../core/enums.dart';
import '../../players/domain/player.dart';
import '../../tournaments/domain/match.dart';
import '../../tournaments/domain/tournament.dart';

/// Service for calculating and updating tournament scores
class ScoringService {
  const ScoringService();

  /// Validate that scores sum to the total points per match
  bool validateScores(int scoreA, int scoreB, int totalPointsPerMatch) {
    return scoreA >= 0 &&
        scoreB >= 0 &&
        scoreA + scoreB == totalPointsPerMatch;
  }

  /// Auto-balance score: given one score, calculate the other
  /// Returns clamped value between 0 and totalPoints
  int autoBalanceScore(int enteredScore, int totalPointsPerMatch) {
    final calculated = totalPointsPerMatch - enteredScore;
    return calculated.clamp(0, totalPointsPerMatch);
  }

  /// Calculate standings from all completed matches
  List<PlayerStanding> calculateStandings(Tournament tournament) {
    return recalculateStandingsFromAllMatches(tournament);
  }

  /// Recalculate all standings from scratch based on completed matches only
  List<PlayerStanding> recalculateStandingsFromAllMatches(Tournament tournament) {
    final standingsMap = <String, PlayerStanding>{};

    // Initialize standings for all players
    for (final player in tournament.players) {
      standingsMap[player.id] = PlayerStanding(playerId: player.id);
    }

    // Process all completed matches
    for (final round in tournament.rounds) {
      // Process matches
      for (final match in round.matches) {
        if (match.status == MatchStatus.completed &&
            match.scoreA != null &&
            match.scoreB != null) {
          // Update Team A players
          for (final playerId in match.teamA.playerIds) {
            final current = standingsMap[playerId];
            if (current != null) {
              standingsMap[playerId] = current.addMatchResult(
                pointsScored: match.scoreA!,
                pointsConceded: match.scoreB!,
                won: match.scoreA! > match.scoreB!,
              );
            }
          }

          // Update Team B players
          for (final playerId in match.teamB.playerIds) {
            final current = standingsMap[playerId];
            if (current != null) {
              standingsMap[playerId] = current.addMatchResult(
                pointsScored: match.scoreB!,
                pointsConceded: match.scoreA!,
                won: match.scoreB! > match.scoreA!,
              );
            }
          }
        }
      }

      // Process byes
      for (final bye in round.byes) {
        final current = standingsMap[bye.playerId];
        if (current != null) {
          standingsMap[bye.playerId] = current.copyWith(
            byeCount: current.byeCount + 1,
          );
        }
      }
    }

    return standingsMap.values.toList();
  }

  /// Compute winner summary from standings and player list
  WinnerSummary computeWinnerSummary({
    required List<Player> players,
    required List<PlayerStanding> standings,
    required TournamentFormat format,
  }) {
    if (standings.isEmpty) {
      return const WinnerSummary();
    }

    // Sort standings by ranking criteria
    final sorted = _sortStandings(standings, players);

    // Overall winner and top 3
    final overallWinnerId = sorted.isNotEmpty ? sorted[0].playerId : null;
    final top3Ids = sorted.take(3).map((s) => s.playerId).toList();

    // Mixed format: find top male and female
    String? topMaleId;
    String? topFemaleId;

    if (format == TournamentFormat.mixedAmericano) {
      final playerMap = {for (final p in players) p.id: p};
      
      for (final standing in sorted) {
        final player = playerMap[standing.playerId];
        if (player == null) continue;

        if (topMaleId == null && player.gender == Gender.male) {
          topMaleId = player.id;
        }
        if (topFemaleId == null && player.gender == Gender.female) {
          topFemaleId = player.id;
        }

        if (topMaleId != null && topFemaleId != null) break;
      }
    }

    return WinnerSummary(
      overallWinnerPlayerId: overallWinnerId,
      top3PlayerIds: top3Ids,
      mixedTopMalePlayerId: topMaleId,
      mixedTopFemalePlayerId: topFemaleId,
      finalizedAt: DateTime.now(),
    );
  }

  /// Sort standings by tie-breaker rules:
  /// 1) pointsTotal desc
  /// 2) wins desc
  /// 3) pointsDifferential desc
  /// 4) name asc (stable)
  List<PlayerStanding> _sortStandings(
    List<PlayerStanding> standings,
    List<Player> players,
  ) {
    final playerMap = {for (final p in players) p.id: p};
    final sorted = List<PlayerStanding>.from(standings);

    sorted.sort((a, b) {
      // 1) Total points (desc)
      final pointsDiff = b.pointsTotal.compareTo(a.pointsTotal);
      if (pointsDiff != 0) return pointsDiff;

      // 2) Wins (desc)
      final winsDiff = b.wins.compareTo(a.wins);
      if (winsDiff != 0) return winsDiff;

      // 3) Point differential (desc)
      final diffDiff = b.pointsDifferential.compareTo(a.pointsDifferential);
      if (diffDiff != 0) return diffDiff;

      // 4) Name (asc) for stability
      final playerA = playerMap[a.playerId];
      final playerB = playerMap[b.playerId];
      if (playerA != null && playerB != null) {
        return playerA.name.compareTo(playerB.name);
      }
      return 0;
    });

    return sorted;
  }

  /// Finalize tournament: set status to completed and compute winner summary
  Tournament finalizeTournament(Tournament tournament) {
    // Recalculate standings
    final standings = recalculateStandingsFromAllMatches(tournament);

    // Compute winner summary
    final winnerSummary = computeWinnerSummary(
      players: tournament.players,
      standings: standings,
      format: tournament.format,
    );

    return tournament.copyWith(
      status: TournamentStatus.completed,
      standings: standings,
      winnerSummary: winnerSummary,
      endedAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  /// Re-finalize tournament after edits (when allowEditsAfterEnd is true)
  Tournament refinalizeTournament(Tournament tournament) {
    // Recalculate standings
    final standings = recalculateStandingsFromAllMatches(tournament);

    // Recompute winner summary
    final winnerSummary = computeWinnerSummary(
      players: tournament.players,
      standings: standings,
      format: tournament.format,
    );

    return tournament.copyWith(
      standings: standings,
      winnerSummary: winnerSummary,
    );
  }

  /// Update a single match score and recalculate affected standings
  Tournament updateMatchScore({
    required Tournament tournament,
    required String matchId,
    required int scoreA,
    required int scoreB,
  }) {
    // Validate scores
    if (!validateScores(scoreA, scoreB, tournament.pointsPerMatch)) {
      throw ScoringException(
        'Scores must be non-negative and sum to ${tournament.pointsPerMatch}',
      );
    }

    // Find and update the match
    final updatedRounds = tournament.rounds.map((round) {
      final updatedMatches = round.matches.map((match) {
        if (match.id == matchId) {
          return match.copyWith(
            scoreA: scoreA,
            scoreB: scoreB,
            status: MatchStatus.completed,
            completedAt: DateTime.now(),
          );
        }
        return match;
      }).toList();

      // Check if round is complete
      final roundComplete = updatedMatches.every(
        (m) => m.status == MatchStatus.completed,
      );

      return round.copyWith(
        matches: updatedMatches,
        status: roundComplete ? RoundStatus.completed : round.status,
        completedAt: roundComplete ? DateTime.now() : round.completedAt,
      );
    }).toList();

    // Create updated tournament with new rounds
    var updatedTournament = tournament.copyWith(rounds: updatedRounds);

    // Recalculate all standings
    final newStandings = calculateStandings(updatedTournament);
    updatedTournament = updatedTournament.copyWith(standings: newStandings);

    // Check if tournament is complete
    final allRoundsComplete = updatedRounds.every(
      (r) => r.status == RoundStatus.completed,
    );

    if (allRoundsComplete) {
      updatedTournament = updatedTournament.copyWith(
        status: TournamentStatus.completed,
        completedAt: DateTime.now(),
      );
    }

    return updatedTournament;
  }

  /// Get match by ID from tournament
  Match? getMatch(Tournament tournament, String matchId) {
    for (final round in tournament.rounds) {
      try {
        return round.matches.firstWhere((m) => m.id == matchId);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Get current round's progress
  RoundProgress getRoundProgress(Round round) {
    final total = round.matches.length;
    final completed =
        round.matches.where((m) => m.status == MatchStatus.completed).length;

    return RoundProgress(
      totalMatches: total,
      completedMatches: completed,
      percentage: total > 0 ? (completed / total * 100).round() : 0,
    );
  }

  /// Get overall tournament progress
  TournamentProgress getTournamentProgress(Tournament tournament) {
    final totalMatches = tournament.rounds.fold<int>(
      0,
      (sum, r) => sum + r.matches.length,
    );

    final completedMatches = tournament.rounds.fold<int>(
      0,
      (sum, r) =>
          sum + r.matches.where((m) => m.status == MatchStatus.completed).length,
    );

    final totalRounds = tournament.rounds.length;
    final completedRounds =
        tournament.rounds.where((r) => r.status == RoundStatus.completed).length;

    return TournamentProgress(
      totalMatches: totalMatches,
      completedMatches: completedMatches,
      totalRounds: totalRounds,
      completedRounds: completedRounds,
      matchPercentage:
          totalMatches > 0 ? (completedMatches / totalMatches * 100).round() : 0,
      roundPercentage:
          totalRounds > 0 ? (completedRounds / totalRounds * 100).round() : 0,
    );
  }
}

/// Progress of a single round
class RoundProgress {
  const RoundProgress({
    required this.totalMatches,
    required this.completedMatches,
    required this.percentage,
  });

  final int totalMatches;
  final int completedMatches;
  final int percentage;

  int get remainingMatches => totalMatches - completedMatches;
  bool get isComplete => completedMatches == totalMatches;
}

/// Overall tournament progress
class TournamentProgress {
  const TournamentProgress({
    required this.totalMatches,
    required this.completedMatches,
    required this.totalRounds,
    required this.completedRounds,
    required this.matchPercentage,
    required this.roundPercentage,
  });

  final int totalMatches;
  final int completedMatches;
  final int totalRounds;
  final int completedRounds;
  final int matchPercentage;
  final int roundPercentage;

  int get remainingMatches => totalMatches - completedMatches;
  int get remainingRounds => totalRounds - completedRounds;
  bool get isComplete => completedMatches == totalMatches;
}

/// Exception for scoring errors
class ScoringException implements Exception {
  ScoringException(this.message);
  final String message;

  @override
  String toString() => 'ScoringException: $message';
}
