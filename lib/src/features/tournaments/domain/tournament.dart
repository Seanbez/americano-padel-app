import 'package:uuid/uuid.dart';

import '../../../core/enums.dart';
import '../../players/domain/player.dart';
import 'match.dart';

/// Winner summary for completed tournaments
class WinnerSummary {
  const WinnerSummary({
    this.overallWinnerPlayerId,
    this.top3PlayerIds = const [],
    this.mixedTopMalePlayerId,
    this.mixedTopFemalePlayerId,
    this.finalizedAt,
  });

  final String? overallWinnerPlayerId;
  final List<String> top3PlayerIds;
  final String? mixedTopMalePlayerId;
  final String? mixedTopFemalePlayerId;
  final DateTime? finalizedAt;

  WinnerSummary copyWith({
    String? overallWinnerPlayerId,
    List<String>? top3PlayerIds,
    String? mixedTopMalePlayerId,
    String? mixedTopFemalePlayerId,
    DateTime? finalizedAt,
  }) {
    return WinnerSummary(
      overallWinnerPlayerId: overallWinnerPlayerId ?? this.overallWinnerPlayerId,
      top3PlayerIds: top3PlayerIds ?? this.top3PlayerIds,
      mixedTopMalePlayerId: mixedTopMalePlayerId ?? this.mixedTopMalePlayerId,
      mixedTopFemalePlayerId: mixedTopFemalePlayerId ?? this.mixedTopFemalePlayerId,
      finalizedAt: finalizedAt ?? this.finalizedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallWinnerPlayerId': overallWinnerPlayerId,
      'top3PlayerIds': top3PlayerIds,
      'mixedTopMalePlayerId': mixedTopMalePlayerId,
      'mixedTopFemalePlayerId': mixedTopFemalePlayerId,
      'finalizedAt': finalizedAt?.toIso8601String(),
    };
  }

  factory WinnerSummary.fromJson(Map<String, dynamic> json) {
    return WinnerSummary(
      overallWinnerPlayerId: json['overallWinnerPlayerId'] as String?,
      top3PlayerIds: (json['top3PlayerIds'] as List?)?.cast<String>() ?? [],
      mixedTopMalePlayerId: json['mixedTopMalePlayerId'] as String?,
      mixedTopFemalePlayerId: json['mixedTopFemalePlayerId'] as String?,
      finalizedAt: json['finalizedAt'] != null
          ? DateTime.parse(json['finalizedAt'] as String)
          : null,
    );
  }
}

/// Tournament settings with extended planning options
class TournamentSettings {
  const TournamentSettings({
    this.courtsCount = 2,
    this.pointsPerMatch = 24,
    this.matchDurationMinutes = 15,
    this.mode = TournamentMode.openEnded,
    this.plannedRounds,
    this.totalMinutes,
    this.matchMinutesEstimate = 12,
    this.changeoverMinutes = 3,
    this.recommendedServesPerPlayer,
    this.recommendedTotalPointsPerMatch,
    this.lockTotalPoints = true,
    this.allowEditsAfterEnd = false,
  });

  final int courtsCount;
  final int pointsPerMatch;
  final int matchDurationMinutes;
  
  // Planning mode
  final TournamentMode mode;
  final int? plannedRounds;
  final int? totalMinutes;
  final int matchMinutesEstimate;
  final int changeoverMinutes;
  
  // Recommendations from time-based planning
  final int? recommendedServesPerPlayer;
  final int? recommendedTotalPointsPerMatch;
  
  // Score entry behavior
  final bool lockTotalPoints;
  
  // Post-tournament edits
  final bool allowEditsAfterEnd;

  /// Effective match duration including changeover
  int get effectiveMatchDuration => matchMinutesEstimate + changeoverMinutes;

  TournamentSettings copyWith({
    int? courtsCount,
    int? pointsPerMatch,
    int? matchDurationMinutes,
    TournamentMode? mode,
    int? plannedRounds,
    int? totalMinutes,
    int? matchMinutesEstimate,
    int? changeoverMinutes,
    int? recommendedServesPerPlayer,
    int? recommendedTotalPointsPerMatch,
    bool? lockTotalPoints,
    bool? allowEditsAfterEnd,
  }) {
    return TournamentSettings(
      courtsCount: courtsCount ?? this.courtsCount,
      pointsPerMatch: pointsPerMatch ?? this.pointsPerMatch,
      matchDurationMinutes: matchDurationMinutes ?? this.matchDurationMinutes,
      mode: mode ?? this.mode,
      plannedRounds: plannedRounds ?? this.plannedRounds,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      matchMinutesEstimate: matchMinutesEstimate ?? this.matchMinutesEstimate,
      changeoverMinutes: changeoverMinutes ?? this.changeoverMinutes,
      recommendedServesPerPlayer: recommendedServesPerPlayer ?? this.recommendedServesPerPlayer,
      recommendedTotalPointsPerMatch: recommendedTotalPointsPerMatch ?? this.recommendedTotalPointsPerMatch,
      lockTotalPoints: lockTotalPoints ?? this.lockTotalPoints,
      allowEditsAfterEnd: allowEditsAfterEnd ?? this.allowEditsAfterEnd,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courtsCount': courtsCount,
      'pointsPerMatch': pointsPerMatch,
      'matchDurationMinutes': matchDurationMinutes,
      'mode': mode.name,
      'plannedRounds': plannedRounds,
      'totalMinutes': totalMinutes,
      'matchMinutesEstimate': matchMinutesEstimate,
      'changeoverMinutes': changeoverMinutes,
      'recommendedServesPerPlayer': recommendedServesPerPlayer,
      'recommendedTotalPointsPerMatch': recommendedTotalPointsPerMatch,
      'lockTotalPoints': lockTotalPoints,
      'allowEditsAfterEnd': allowEditsAfterEnd,
    };
  }

  factory TournamentSettings.fromJson(Map<String, dynamic> json) {
    return TournamentSettings(
      courtsCount: json['courtsCount'] as int? ?? 2,
      pointsPerMatch: json['pointsPerMatch'] as int? ?? 24,
      matchDurationMinutes: json['matchDurationMinutes'] as int? ?? 15,
      mode: TournamentMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => TournamentMode.openEnded,
      ),
      plannedRounds: json['plannedRounds'] as int?,
      totalMinutes: json['totalMinutes'] as int?,
      matchMinutesEstimate: json['matchMinutesEstimate'] as int? ?? 12,
      changeoverMinutes: json['changeoverMinutes'] as int? ?? 3,
      recommendedServesPerPlayer: json['recommendedServesPerPlayer'] as int?,
      recommendedTotalPointsPerMatch: json['recommendedTotalPointsPerMatch'] as int?,
      lockTotalPoints: json['lockTotalPoints'] as bool? ?? true,
      allowEditsAfterEnd: json['allowEditsAfterEnd'] as bool? ?? false,
    );
  }
}

/// Player standings in a tournament
class PlayerStanding {
  const PlayerStanding({
    required this.playerId,
    this.pointsTotal = 0,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.pointsFor = 0,
    this.pointsAgainst = 0,
    this.byeCount = 0,
  });

  final String playerId;
  final int pointsTotal;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int pointsFor;
  final int pointsAgainst;
  final int byeCount;

  int get pointsDifferential => pointsFor - pointsAgainst;

  double get averagePointsPerMatch =>
      matchesPlayed > 0 ? pointsTotal / matchesPlayed : 0;

  PlayerStanding copyWith({
    String? playerId,
    int? pointsTotal,
    int? matchesPlayed,
    int? wins,
    int? losses,
    int? pointsFor,
    int? pointsAgainst,
    int? byeCount,
  }) {
    return PlayerStanding(
      playerId: playerId ?? this.playerId,
      pointsTotal: pointsTotal ?? this.pointsTotal,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      pointsFor: pointsFor ?? this.pointsFor,
      pointsAgainst: pointsAgainst ?? this.pointsAgainst,
      byeCount: byeCount ?? this.byeCount,
    );
  }

  /// Add match result to standing
  PlayerStanding addMatchResult({
    required int pointsScored,
    required int pointsConceded,
    required bool won,
  }) {
    return copyWith(
      pointsTotal: pointsTotal + pointsScored,
      matchesPlayed: matchesPlayed + 1,
      wins: won ? wins + 1 : wins,
      losses: won ? losses : losses + 1,
      pointsFor: pointsFor + pointsScored,
      pointsAgainst: pointsAgainst + pointsConceded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'pointsTotal': pointsTotal,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'losses': losses,
      'pointsFor': pointsFor,
      'pointsAgainst': pointsAgainst,
      'byeCount': byeCount,
    };
  }

  factory PlayerStanding.fromJson(Map<String, dynamic> json) {
    return PlayerStanding(
      playerId: json['playerId'] as String,
      pointsTotal: json['pointsTotal'] as int? ?? 0,
      matchesPlayed: json['matchesPlayed'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      pointsFor: json['pointsFor'] as int? ?? 0,
      pointsAgainst: json['pointsAgainst'] as int? ?? 0,
      byeCount: json['byeCount'] as int? ?? 0,
    );
  }
}

/// Main Tournament model
class Tournament {
  Tournament({
    String? id,
    required this.name,
    required this.date,
    this.format = TournamentFormat.americano,
    this.status = TournamentStatus.draft,
    this.settings = const TournamentSettings(),
    this.players = const [],
    this.rounds = const [],
    this.standings = const [],
    this.winnerSummary,
    this.seed,
    this.createdBy,
    DateTime? createdAt,
    this.startedAt,
    this.endedAt,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final DateTime date;
  final TournamentFormat format;
  final TournamentStatus status;
  final TournamentSettings settings;
  final List<Player> players;
  final List<Round> rounds;
  final List<PlayerStanding> standings;
  final WinnerSummary? winnerSummary;
  final int? seed;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? completedAt;

  // Computed properties
  int get playerCount => players.length;
  int get activePlayerCount => players.where((p) => p.isActive).length;
  int get courtsCount => settings.courtsCount;
  int get pointsPerMatch => settings.pointsPerMatch;

  List<Player> get activePlayers => players.where((p) => p.isActive).toList();

  List<Player> get malePlayers =>
      activePlayers.where((p) => p.gender == Gender.male).toList();

  List<Player> get femalePlayers =>
      activePlayers.where((p) => p.gender == Gender.female).toList();

  int get totalRounds => rounds.length;

  int get completedRounds =>
      rounds.where((r) => r.status == RoundStatus.completed).length;

  /// Total scheduled matches across all rounds
  int get totalScheduledMatches =>
      rounds.fold(0, (sum, r) => sum + r.matches.length);

  /// Total completed matches across all rounds
  int get totalCompletedMatches =>
      rounds.fold(0, (sum, r) => sum + r.matches.where((m) => m.isComplete).length);

  /// Check if scoring is allowed
  bool get canScore {
    if (status == TournamentStatus.inProgress) return true;
    if (status == TournamentStatus.completed && settings.allowEditsAfterEnd) return true;
    return false;
  }

  Round? get currentRound {
    try {
      return rounds.firstWhere((r) => r.status == RoundStatus.inProgress);
    } catch (_) {
      // Return first pending round if no in-progress round
      try {
        return rounds.firstWhere((r) => r.status == RoundStatus.pending);
      } catch (_) {
        return null;
      }
    }
  }

  /// Check if tournament can start (has enough players and schedule)
  bool get canStart =>
      status == TournamentStatus.ready &&
      rounds.isNotEmpty &&
      activePlayerCount >= 4;

  /// Validate mixed format requirements
  bool get isValidMixedSetup {
    if (format != TournamentFormat.mixedAmericano) return true;
    return malePlayers.length == femalePlayers.length && malePlayers.isNotEmpty;
  }

  /// Get player by ID
  Player? getPlayer(String playerId) {
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (_) {
      return null;
    }
  }

  /// Get standing for a player
  PlayerStanding? getStanding(String playerId) {
    try {
      return standings.firstWhere((s) => s.playerId == playerId);
    } catch (_) {
      return null;
    }
  }

  /// Get sorted leaderboard
  List<PlayerStanding> get leaderboard {
    final sorted = List<PlayerStanding>.from(standings);
    sorted.sort((a, b) {
      // Primary: total points (descending)
      final pointsDiff = b.pointsTotal.compareTo(a.pointsTotal);
      if (pointsDiff != 0) return pointsDiff;

      // Secondary: wins (descending)
      final winsDiff = b.wins.compareTo(a.wins);
      if (winsDiff != 0) return winsDiff;

      // Tertiary: point differential (descending)
      final diffDiff = b.pointsDifferential.compareTo(a.pointsDifferential);
      if (diffDiff != 0) return diffDiff;

      // Quaternary: alphabetical by player name (stable sort)
      final playerA = getPlayer(a.playerId);
      final playerB = getPlayer(b.playerId);
      if (playerA != null && playerB != null) {
        return playerA.name.compareTo(playerB.name);
      }
      return 0;
    });
    return sorted;
  }

  Tournament copyWith({
    String? id,
    String? name,
    DateTime? date,
    TournamentFormat? format,
    TournamentStatus? status,
    TournamentSettings? settings,
    List<Player>? players,
    List<Round>? rounds,
    List<PlayerStanding>? standings,
    WinnerSummary? winnerSummary,
    int? seed,
    String? createdBy,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? completedAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      format: format ?? this.format,
      status: status ?? this.status,
      settings: settings ?? this.settings,
      players: players ?? this.players,
      rounds: rounds ?? this.rounds,
      standings: standings ?? this.standings,
      winnerSummary: winnerSummary ?? this.winnerSummary,
      seed: seed ?? this.seed,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'format': format.name,
      'status': status.name,
      'settings': settings.toJson(),
      'players': players.map((p) => p.toJson()).toList(),
      'rounds': rounds.map((r) => r.toJson()).toList(),
      'standings': standings.map((s) => s.toJson()).toList(),
      'winnerSummary': winnerSummary?.toJson(),
      'seed': seed,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      format: TournamentFormat.values.firstWhere(
        (e) => e.name == json['format'],
        orElse: () => TournamentFormat.americano,
      ),
      status: TournamentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TournamentStatus.draft,
      ),
      settings: json['settings'] != null
          ? TournamentSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const TournamentSettings(),
      players: (json['players'] as List?)
              ?.map((p) => Player.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      rounds: (json['rounds'] as List?)
              ?.map((r) => Round.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      standings: (json['standings'] as List?)
              ?.map((s) => PlayerStanding.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      winnerSummary: json['winnerSummary'] != null
          ? WinnerSummary.fromJson(json['winnerSummary'] as Map<String, dynamic>)
          : null,
      seed: json['seed'] as int?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'Tournament(id: $id, name: $name, players: $playerCount, status: $status)';
}
