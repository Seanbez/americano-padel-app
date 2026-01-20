import '../../../core/enums.dart';

/// Result DTO for time-based tournament recommendations
class TimeRecommendation {
  const TimeRecommendation({
    required this.estimatedRounds,
    required this.estimatedMatches,
    required this.recommendedServesPerPlayer,
    required this.recommendedTotalPointsPerMatch,
    required this.estimatedDurationMinutes,
    required this.matchesPerRound,
  });

  final int estimatedRounds;
  final int estimatedMatches;
  final int recommendedServesPerPlayer;
  final int recommendedTotalPointsPerMatch;
  final int estimatedDurationMinutes;
  final int matchesPerRound;

  /// Check if recommendation fits within time budget
  bool get fitsWithinTime => estimatedDurationMinutes > 0;

  @override
  String toString() =>
      'TimeRecommendation(rounds: $estimatedRounds, matches: $estimatedMatches, '
      'serves: $recommendedServesPerPlayer, points: $recommendedTotalPointsPerMatch, '
      'duration: ${estimatedDurationMinutes}min)';
}

/// Service for generating time-based tournament recommendations
class TimeRecommendationService {
  const TimeRecommendationService();

  /// Points per match options with associated serve counts
  /// 4 serves -> 16 points, 6 serves -> 24 points, 8 serves -> 32 points
  static const Map<int, int> servePointsMapping = {
    4: 16,
    6: 24,
    8: 32,
  };

  /// Duration multipliers for different point totals
  /// Lower points = faster matches
  static const Map<int, double> durationMultipliers = {
    16: 0.75,
    24: 1.0,
    32: 1.25,
  };

  /// Generate recommendation based on time constraints
  /// 
  /// [totalMinutes] - Total available time for tournament
  /// [matchMinutesEstimate] - Estimated base duration per match
  /// [changeoverMinutes] - Time between matches for court changes
  /// [courtsCount] - Number of courts available
  /// [playerCount] - Total number of players
  TimeRecommendation generateRecommendation({
    required int totalMinutes,
    required int matchMinutesEstimate,
    required int changeoverMinutes,
    required int courtsCount,
    required int playerCount,
  }) {
    // Calculate matches per round (number of courts, capped by player pairs)
    final maxMatchesPerRound = courtsCount;
    final playersPerMatch = 4;
    final maxActivePlayersPerRound = maxMatchesPerRound * playersPerMatch;
    
    // Actual matches per round considering player count
    final matchesPerRound = (playerCount >= maxActivePlayersPerRound)
        ? maxMatchesPerRound
        : (playerCount ~/ playersPerMatch).clamp(1, maxMatchesPerRound);

    // Effective time per round
    final effectiveMatchTime = matchMinutesEstimate + changeoverMinutes;

    // Calculate how many rounds fit in available time
    final estimatedRounds = totalMinutes ~/ effectiveMatchTime;

    // Pick best serves/points combo
    final recommendation = _selectBestPointsOption(
      totalMinutes: totalMinutes,
      matchMinutesEstimate: matchMinutesEstimate,
      changeoverMinutes: changeoverMinutes,
    );

    final totalMatches = estimatedRounds * matchesPerRound;
    final actualDuration = estimatedRounds * effectiveMatchTime;

    return TimeRecommendation(
      estimatedRounds: estimatedRounds,
      estimatedMatches: totalMatches,
      recommendedServesPerPlayer: recommendation.serves,
      recommendedTotalPointsPerMatch: recommendation.points,
      estimatedDurationMinutes: actualDuration,
      matchesPerRound: matchesPerRound,
    );
  }

  /// Select the best points/serves option based on time constraints
  _PointsRecommendation _selectBestPointsOption({
    required int totalMinutes,
    required int matchMinutesEstimate,
    required int changeoverMinutes,
  }) {
    // Default to 24 points (6 serves)
    var bestServes = 6;
    var bestPoints = 24;

    // If match estimate is short (< 10 min), prefer 16 points for faster games
    if (matchMinutesEstimate < 10) {
      return _PointsRecommendation(serves: 4, points: 16);
    }

    // If match estimate is long (> 18 min), prefer 32 points for longer games
    if (matchMinutesEstimate > 18) {
      return _PointsRecommendation(serves: 8, points: 32);
    }

    // For moderate times, calculate which option fits best
    for (final entry in servePointsMapping.entries) {
      final serves = entry.key;
      final points = entry.value;
      final multiplier = durationMultipliers[points] ?? 1.0;
      final adjustedTime = (matchMinutesEstimate * multiplier).round();

      // Pick the highest points option that fits within reasonable time
      if (adjustedTime <= matchMinutesEstimate + 3) {
        bestServes = serves;
        bestPoints = points;
      }
    }

    return _PointsRecommendation(serves: bestServes, points: bestPoints);
  }

  /// Calculate rounds needed for planned round-based tournament
  int calculateRoundsForPlayerCount({
    required int playerCount,
    required int courtsCount,
    required TournamentFormat format,
  }) {
    // Each player should ideally play with all other players at least once
    // In Americano, minimum rounds = (playerCount - 1) for round-robin style
    // But we adjust based on court availability
    
    final playersPerMatch = 4;
    final matchesPerRound = courtsCount;
    final activePlayersPerRound = matchesPerRound * playersPerMatch;

    // If all players fit on courts each round
    if (playerCount <= activePlayersPerRound) {
      return playerCount - 1; // Round-robin style
    }

    // Otherwise, need more rounds to cycle through all players
    final roundsToPlayOnce = (playerCount / activePlayersPerRound).ceil();
    return roundsToPlayOnce * 2; // Double to allow partner mixing
  }

  /// Validate that settings are achievable
  bool validateSettings({
    required int totalMinutes,
    required int matchMinutesEstimate,
    required int changeoverMinutes,
    required int playerCount,
  }) {
    if (totalMinutes < matchMinutesEstimate + changeoverMinutes) {
      return false; // Not enough time for even one round
    }
    if (playerCount < 4) {
      return false; // Need at least 4 players
    }
    return true;
  }
}

/// Internal helper class for points recommendation
class _PointsRecommendation {
  const _PointsRecommendation({
    required this.serves,
    required this.points,
  });

  final int serves;
  final int points;
}
