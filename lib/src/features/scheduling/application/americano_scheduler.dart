import 'dart:math';

import '../../../core/enums.dart';
import '../../players/domain/player.dart';
import '../../tournaments/domain/match.dart';
import '../../tournaments/domain/tournament.dart';

/// Result of schedule generation
class ScheduleResult {
  const ScheduleResult({
    required this.rounds,
    required this.seed,
    required this.score,
    required this.stats,
  });

  final List<Round> rounds;
  final int seed;
  final double score;
  final ScheduleStats stats;
}

/// Statistics about the generated schedule
class ScheduleStats {
  const ScheduleStats({
    required this.partnerRepeatCount,
    required this.opponentRepeatCount,
    required this.courtVariance,
    required this.byeVariance,
    required this.totalMatches,
    required this.totalRounds,
  });

  final int partnerRepeatCount;
  final int opponentRepeatCount;
  final double courtVariance;
  final double byeVariance;
  final int totalMatches;
  final int totalRounds;

  @override
  String toString() =>
      'Stats(partners: $partnerRepeatCount, opponents: $opponentRepeatCount, '
      'courtVar: ${courtVariance.toStringAsFixed(2)}, byeVar: ${byeVariance.toStringAsFixed(2)})';
}

/// Americano tournament scheduler with fairness optimization
class AmericanoScheduler {
  AmericanoScheduler({
    this.candidateCount = 200,
    this.partnerWeight = 1000,
    this.opponentWeight = 300,
    this.courtWeight = 50,
    this.byeWeight = 200,
  });

  final int candidateCount;
  final double partnerWeight;
  final double opponentWeight;
  final double courtWeight;
  final double byeWeight;

  /// Generate optimal schedule
  ScheduleResult generateSchedule({
    required List<Player> players,
    required int courtsCount,
    required TournamentFormat format,
    int? seed,
  }) {
    final activePlayers = players.where((p) => p.isActive).toList();

    // Validate player count
    if (activePlayers.length < 4) {
      throw ScheduleException('Need at least 4 players to create a schedule');
    }

    // For mixed format, validate gender balance
    if (format == TournamentFormat.mixedAmericano) {
      return _generateMixedSchedule(
        players: activePlayers,
        courtsCount: courtsCount,
        seed: seed,
      );
    }

    return _generateOpenSchedule(
      players: activePlayers,
      courtsCount: courtsCount,
      seed: seed,
    );
  }

  /// Generate schedule for open/same-sex format
  ScheduleResult _generateOpenSchedule({
    required List<Player> players,
    required int courtsCount,
    int? seed,
  }) {
    final baseSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    ScheduleResult? bestResult;

    for (var i = 0; i < candidateCount; i++) {
      final candidateSeed = baseSeed + i;
      final result = _generateCandidate(
        players: players,
        courtsCount: courtsCount,
        seed: candidateSeed,
        isMixed: false,
      );

      if (bestResult == null || result.score < bestResult.score) {
        bestResult = result;
      }
    }

    return bestResult!;
  }

  /// Generate schedule for mixed format (M+F teams)
  ScheduleResult _generateMixedSchedule({
    required List<Player> players,
    required int courtsCount,
    int? seed,
  }) {
    final males = players.where((p) => p.gender == Gender.male).toList();
    final females = players.where((p) => p.gender == Gender.female).toList();

    if (males.isEmpty || females.isEmpty) {
      throw ScheduleException(
        'Mixed format requires at least one male and one female player',
      );
    }

    if (males.length != females.length) {
      throw ScheduleException(
        'Mixed format requires equal number of male (${males.length}) '
        'and female (${females.length}) players',
      );
    }

    final baseSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    ScheduleResult? bestResult;

    for (var i = 0; i < candidateCount; i++) {
      final candidateSeed = baseSeed + i;
      final result = _generateMixedCandidate(
        males: males,
        females: females,
        courtsCount: courtsCount,
        seed: candidateSeed,
      );

      if (bestResult == null || result.score < bestResult.score) {
        bestResult = result;
      }
    }

    return bestResult!;
  }

  /// Generate a single candidate schedule (open format)
  ScheduleResult _generateCandidate({
    required List<Player> players,
    required int courtsCount,
    required int seed,
    required bool isMixed,
  }) {
    final random = Random(seed);
    final playerIds = players.map((p) => p.id).toList();
    final n = playerIds.length;

    // Tracking matrices
    final partnerCount = <String, Map<String, int>>{};
    final opponentCount = <String, Map<String, int>>{};
    final courtCount = <String, Map<int, int>>{};
    final byeCount = <String, int>{};

    for (final id in playerIds) {
      partnerCount[id] = {};
      opponentCount[id] = {};
      courtCount[id] = {};
      byeCount[id] = 0;
    }

    // Calculate number of rounds
    // Each match needs 4 players, each court runs 1 match
    // Players per round = min(4 * courtsCount, n)
    final playersPerRound = min(4 * courtsCount, n);
    final byesPerRound = n - playersPerRound;

    // Rounds needed for fair play: aim for each player to play similar number
    final roundsNeeded = _calculateRoundsNeeded(n, courtsCount);

    final rounds = <Round>[];
    final shuffledPlayers = List<String>.from(playerIds);

    for (var roundIndex = 0; roundIndex < roundsNeeded; roundIndex++) {
      // Shuffle for randomness
      shuffledPlayers.shuffle(random);

      // Sort by bye count (players with fewer byes should play)
      shuffledPlayers.sort((a, b) => byeCount[a]!.compareTo(byeCount[b]!));

      // Select players for this round (those with fewer byes first)
      final playingPlayers = shuffledPlayers.take(playersPerRound).toList();
      final restingPlayers = shuffledPlayers.skip(playersPerRound).toList();

      // Create matches for this round
      final matches = <Match>[];
      final matchCount = playingPlayers.length ~/ 4;

      // Try to form optimal teams
      final availablePlayers = List<String>.from(playingPlayers);

      for (var courtIndex = 0; courtIndex < matchCount; courtIndex++) {
        // Find best team pairing for this court
        final match = _selectBestMatch(
          availablePlayers: availablePlayers,
          courtIndex: courtIndex,
          roundIndex: roundIndex,
          partnerCount: partnerCount,
          opponentCount: opponentCount,
          courtCount: courtCount,
          random: random,
        );

        matches.add(match);

        // Remove used players
        for (final id in match.allPlayerIds) {
          availablePlayers.remove(id);
        }

        // Update tracking
        _updateTracking(
          match: match,
          partnerCount: partnerCount,
          opponentCount: opponentCount,
          courtCount: courtCount,
        );
      }

      // Add any remaining players to byes
      restingPlayers.addAll(availablePlayers);

      // Create byes
      final byes = restingPlayers
          .map((id) => Bye(playerId: id, roundIndex: roundIndex))
          .toList();

      // Update bye count
      for (final bye in byes) {
        byeCount[bye.playerId] = byeCount[bye.playerId]! + 1;
      }

      rounds.add(Round(
        index: roundIndex,
        matches: matches,
        byes: byes,
      ));
    }

    // Calculate statistics
    final stats = _calculateStats(
      partnerCount: partnerCount,
      opponentCount: opponentCount,
      courtCount: courtCount,
      byeCount: byeCount,
      rounds: rounds,
    );

    // Calculate score
    final score = _calculateScore(stats);

    return ScheduleResult(
      rounds: rounds,
      seed: seed,
      score: score,
      stats: stats,
    );
  }

  /// Generate mixed format candidate
  ScheduleResult _generateMixedCandidate({
    required List<Player> males,
    required List<Player> females,
    required int courtsCount,
    required int seed,
  }) {
    final random = Random(seed);
    final maleIds = males.map((p) => p.id).toList();
    final femaleIds = females.map((p) => p.id).toList();
    final n = maleIds.length; // Same as females.length

    // Tracking matrices
    final partnerCount = <String, Map<String, int>>{};
    final opponentCount = <String, Map<String, int>>{};
    final courtCount = <String, Map<int, int>>{};
    final byeCount = <String, int>{};

    for (final id in [...maleIds, ...femaleIds]) {
      partnerCount[id] = {};
      opponentCount[id] = {};
      courtCount[id] = {};
      byeCount[id] = 0;
    }

    // Each match needs 2 teams, each team is 1M+1F = 4 players (2M+2F)
    final teamsPerRound = min(courtsCount * 2, n);
    final matchesPerRound = teamsPerRound ~/ 2;

    // Calculate rounds using circle method
    final roundsNeeded = n > 1 ? n - 1 : 1;

    final rounds = <Round>[];

    // Use circle method for rotation
    final fixedMale = maleIds.first;
    final rotatingMales = maleIds.skip(1).toList();
    final rotatingFemales = List<String>.from(femaleIds);

    for (var roundIndex = 0; roundIndex < roundsNeeded; roundIndex++) {
      // Current rotation state
      final currentMales = [fixedMale, ...rotatingMales];
      final currentFemales = rotatingFemales;

      // Shuffle females for partner variety (within constraint)
      final shuffledFemales = List<String>.from(currentFemales);
      shuffledFemales.shuffle(random);

      // Form teams: male[i] + female[i]
      final teams = <Team>[];
      for (var i = 0; i < min(teamsPerRound, n); i++) {
        teams.add(Team(
          player1Id: currentMales[i],
          player2Id: shuffledFemales[i],
        ));
      }

      // Sort teams by partner history
      teams.shuffle(random);
      teams.sort((a, b) {
        final aCount = (partnerCount[a.player1Id]?[a.player2Id] ?? 0) +
            (partnerCount[a.player2Id]?[a.player1Id] ?? 0);
        final bCount = (partnerCount[b.player1Id]?[b.player2Id] ?? 0) +
            (partnerCount[b.player2Id]?[b.player1Id] ?? 0);
        return aCount.compareTo(bCount);
      });

      // Pair teams into matches
      final matches = <Match>[];
      final usedTeams = <Team>[];

      for (var courtIndex = 0; courtIndex < matchesPerRound; courtIndex++) {
        if (teams.length - usedTeams.length < 2) break;

        final availableTeams =
            teams.where((t) => !usedTeams.contains(t)).toList();
        if (availableTeams.length < 2) break;

        // Select best two teams (minimize opponent repeats)
        Team? teamA;
        Team? teamB;
        var bestScore = double.infinity;

        for (var i = 0; i < availableTeams.length; i++) {
          for (var j = i + 1; j < availableTeams.length; j++) {
            final tA = availableTeams[i];
            final tB = availableTeams[j];
            final score = _calculateOpponentScore(tA, tB, opponentCount);
            if (score < bestScore) {
              bestScore = score;
              teamA = tA;
              teamB = tB;
            }
          }
        }

        if (teamA != null && teamB != null) {
          final match = Match(
            roundIndex: roundIndex,
            courtIndex: courtIndex,
            teamA: teamA,
            teamB: teamB,
          );
          matches.add(match);
          usedTeams.addAll([teamA, teamB]);

          // Update tracking
          _updateTracking(
            match: match,
            partnerCount: partnerCount,
            opponentCount: opponentCount,
            courtCount: courtCount,
          );
        }
      }

      // Determine byes (teams not used)
      final playingIds =
          matches.expand((m) => m.allPlayerIds).toSet();
      final allIds = {...maleIds, ...femaleIds};
      final restingIds = allIds.difference(playingIds);

      final byes = restingIds
          .map((id) => Bye(playerId: id, roundIndex: roundIndex))
          .toList();

      for (final bye in byes) {
        byeCount[bye.playerId] = byeCount[bye.playerId]! + 1;
      }

      rounds.add(Round(
        index: roundIndex,
        matches: matches,
        byes: byes,
      ));

      // Rotate for next round (circle method)
      if (rotatingMales.isNotEmpty) {
        final lastMale = rotatingMales.removeLast();
        rotatingMales.insert(0, lastMale);
      }
      if (rotatingFemales.isNotEmpty) {
        final lastFemale = rotatingFemales.removeLast();
        rotatingFemales.insert(0, lastFemale);
      }
    }

    // Calculate statistics
    final stats = _calculateStats(
      partnerCount: partnerCount,
      opponentCount: opponentCount,
      courtCount: courtCount,
      byeCount: byeCount,
      rounds: rounds,
    );

    final score = _calculateScore(stats);

    return ScheduleResult(
      rounds: rounds,
      seed: seed,
      score: score,
      stats: stats,
    );
  }

  /// Select best match for a court
  Match _selectBestMatch({
    required List<String> availablePlayers,
    required int courtIndex,
    required int roundIndex,
    required Map<String, Map<String, int>> partnerCount,
    required Map<String, Map<String, int>> opponentCount,
    required Map<String, Map<int, int>> courtCount,
    required Random random,
  }) {
    if (availablePlayers.length < 4) {
      throw ScheduleException('Not enough players for match');
    }

    // Generate possible team combinations
    Team? bestTeamA;
    Team? bestTeamB;
    var bestScore = double.infinity;

    // Try different combinations
    final shuffled = List<String>.from(availablePlayers);
    shuffled.shuffle(random);

    // Limited search for performance
    final searchLimit = min(20, availablePlayers.length);

    for (var i = 0; i < searchLimit; i++) {
      for (var j = i + 1; j < searchLimit; j++) {
        for (var k = j + 1; k < searchLimit; k++) {
          for (var l = k + 1; l < searchLimit; l++) {
            final p = [shuffled[i], shuffled[j], shuffled[k], shuffled[l]];

            // Try both team configurations
            for (final config in [
              [
                [0, 1],
                [2, 3]
              ],
              [
                [0, 2],
                [1, 3]
              ],
              [
                [0, 3],
                [1, 2]
              ],
            ]) {
              final teamA = Team(
                player1Id: p[config[0][0]],
                player2Id: p[config[0][1]],
              );
              final teamB = Team(
                player1Id: p[config[1][0]],
                player2Id: p[config[1][1]],
              );

              final score = _calculateMatchScore(
                teamA,
                teamB,
                courtIndex,
                partnerCount,
                opponentCount,
                courtCount,
              );

              if (score < bestScore) {
                bestScore = score;
                bestTeamA = teamA;
                bestTeamB = teamB;
              }
            }
          }
        }
      }
    }

    // Fallback if search didn't find optimal
    bestTeamA ??= Team(player1Id: shuffled[0], player2Id: shuffled[1]);
    bestTeamB ??= Team(player1Id: shuffled[2], player2Id: shuffled[3]);

    return Match(
      roundIndex: roundIndex,
      courtIndex: courtIndex,
      teamA: bestTeamA,
      teamB: bestTeamB,
    );
  }

  /// Calculate score for a potential match
  double _calculateMatchScore(
    Team teamA,
    Team teamB,
    int courtIndex,
    Map<String, Map<String, int>> partnerCount,
    Map<String, Map<String, int>> opponentCount,
    Map<String, Map<int, int>> courtCount,
  ) {
    var score = 0.0;

    // Partner repeats
    score += (partnerCount[teamA.player1Id]?[teamA.player2Id] ?? 0) *
        partnerWeight;
    score += (partnerCount[teamB.player1Id]?[teamB.player2Id] ?? 0) *
        partnerWeight;

    // Opponent repeats
    score += _calculateOpponentScore(teamA, teamB, opponentCount) *
        opponentWeight;

    // Court distribution
    for (final id in [...teamA.playerIds, ...teamB.playerIds]) {
      score += (courtCount[id]?[courtIndex] ?? 0) * courtWeight;
    }

    return score;
  }

  /// Calculate opponent repeat score
  double _calculateOpponentScore(
    Team teamA,
    Team teamB,
    Map<String, Map<String, int>> opponentCount,
  ) {
    var score = 0.0;
    for (final aId in teamA.playerIds) {
      for (final bId in teamB.playerIds) {
        score += opponentCount[aId]?[bId] ?? 0;
        score += opponentCount[bId]?[aId] ?? 0;
      }
    }
    return score;
  }

  /// Update tracking matrices after a match
  void _updateTracking({
    required Match match,
    required Map<String, Map<String, int>> partnerCount,
    required Map<String, Map<String, int>> opponentCount,
    required Map<String, Map<int, int>> courtCount,
  }) {
    // Update partner counts
    _incrementCount(
        partnerCount, match.teamA.player1Id, match.teamA.player2Id);
    _incrementCount(
        partnerCount, match.teamA.player2Id, match.teamA.player1Id);
    _incrementCount(
        partnerCount, match.teamB.player1Id, match.teamB.player2Id);
    _incrementCount(
        partnerCount, match.teamB.player2Id, match.teamB.player1Id);

    // Update opponent counts
    for (final aId in match.teamA.playerIds) {
      for (final bId in match.teamB.playerIds) {
        _incrementCount(opponentCount, aId, bId);
        _incrementCount(opponentCount, bId, aId);
      }
    }

    // Update court counts
    for (final id in match.allPlayerIds) {
      courtCount[id] ??= {};
      courtCount[id]![match.courtIndex] =
          (courtCount[id]![match.courtIndex] ?? 0) + 1;
    }
  }

  void _incrementCount(
      Map<String, Map<String, int>> map, String key1, String key2) {
    map[key1] ??= {};
    map[key1]![key2] = (map[key1]![key2] ?? 0) + 1;
  }

  /// Calculate number of rounds needed
  int _calculateRoundsNeeded(int playerCount, int courtsCount) {
    // Aim for each player to play approximately the same number of matches
    // Each match has 4 players, so per round we can have min(courtsCount, playerCount/4) matches
    final matchesPerRound = min(courtsCount, playerCount ~/ 4);
    final playersPerRound = matchesPerRound * 4;

    // Each player should ideally play n-1 matches with different partners
    // But we limit to reasonable tournament length
    final idealRounds = playerCount - 1;
    final practicalMax = min(idealRounds, playerCount ~/ 2 + 2);

    return max(practicalMax, 3); // At least 3 rounds
  }

  /// Calculate schedule statistics
  ScheduleStats _calculateStats({
    required Map<String, Map<String, int>> partnerCount,
    required Map<String, Map<String, int>> opponentCount,
    required Map<String, Map<int, int>> courtCount,
    required Map<String, int> byeCount,
    required List<Round> rounds,
  }) {
    // Count partner repeats (more than once)
    var partnerRepeats = 0;
    for (final entry in partnerCount.entries) {
      for (final count in entry.value.values) {
        if (count > 1) partnerRepeats += count - 1;
      }
    }
    partnerRepeats ~/= 2; // Don't double count

    // Count opponent repeats
    var opponentRepeats = 0;
    for (final entry in opponentCount.entries) {
      for (final count in entry.value.values) {
        if (count > 1) opponentRepeats += count - 1;
      }
    }
    opponentRepeats ~/= 2;

    // Calculate court variance
    final courtVariance = _calculateVariance(
      courtCount.values.expand((m) => m.values).toList(),
    );

    // Calculate bye variance
    final byeVariance = _calculateVariance(byeCount.values.toList());

    // Total matches
    final totalMatches = rounds.fold<int>(
      0,
      (sum, r) => sum + r.matches.length,
    );

    return ScheduleStats(
      partnerRepeatCount: partnerRepeats,
      opponentRepeatCount: opponentRepeats,
      courtVariance: courtVariance,
      byeVariance: byeVariance,
      totalMatches: totalMatches,
      totalRounds: rounds.length,
    );
  }

  /// Calculate variance of a list of integers
  double _calculateVariance(List<int> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate total score for a schedule
  double _calculateScore(ScheduleStats stats) {
    return stats.partnerRepeatCount * partnerWeight +
        stats.opponentRepeatCount * opponentWeight +
        stats.courtVariance * courtWeight +
        stats.byeVariance * byeWeight;
  }
}

/// Exception for scheduling errors
class ScheduleException implements Exception {
  ScheduleException(this.message);
  final String message;

  @override
  String toString() => 'ScheduleException: $message';
}
