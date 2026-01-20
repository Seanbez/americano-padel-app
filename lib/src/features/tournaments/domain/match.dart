import 'package:uuid/uuid.dart';

import '../../../core/enums.dart';
import '../../players/domain/player.dart';

/// Represents a team of two players
class Team {
  const Team({
    required this.player1Id,
    required this.player2Id,
  });

  final String player1Id;
  final String player2Id;

  List<String> get playerIds => [player1Id, player2Id];

  bool containsPlayer(String playerId) =>
      player1Id == playerId || player2Id == playerId;

  Map<String, dynamic> toJson() {
    return {
      'player1Id': player1Id,
      'player2Id': player2Id,
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      player1Id: json['player1Id'] as String,
      player2Id: json['player2Id'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team &&
          runtimeType == other.runtimeType &&
          ((player1Id == other.player1Id && player2Id == other.player2Id) ||
              (player1Id == other.player2Id && player2Id == other.player1Id));

  @override
  int get hashCode => player1Id.hashCode ^ player2Id.hashCode;
}

/// Represents a single match in a round
class Match {
  Match({
    String? id,
    required this.roundIndex,
    required this.courtIndex,
    required this.teamA,
    required this.teamB,
    this.scoreA,
    this.scoreB,
    this.status = MatchStatus.scheduled,
    this.startedAt,
    this.completedAt,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final int roundIndex;
  final int courtIndex;
  final Team teamA;
  final Team teamB;
  final int? scoreA;
  final int? scoreB;
  final MatchStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// All player IDs in this match
  List<String> get allPlayerIds => [...teamA.playerIds, ...teamB.playerIds];

  /// Check if a player is in this match
  bool containsPlayer(String playerId) =>
      teamA.containsPlayer(playerId) || teamB.containsPlayer(playerId);

  /// Check if match is complete
  bool get isComplete => status == MatchStatus.completed;

  /// Check if scores are valid
  bool hasValidScores(int totalPointsPerMatch) =>
      scoreA != null &&
      scoreB != null &&
      scoreA! >= 0 &&
      scoreB! >= 0 &&
      scoreA! + scoreB! == totalPointsPerMatch;

  Match copyWith({
    String? id,
    int? roundIndex,
    int? courtIndex,
    Team? teamA,
    Team? teamB,
    int? scoreA,
    int? scoreB,
    MatchStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return Match(
      id: id ?? this.id,
      roundIndex: roundIndex ?? this.roundIndex,
      courtIndex: courtIndex ?? this.courtIndex,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roundIndex': roundIndex,
      'courtIndex': courtIndex,
      'teamA': teamA.toJson(),
      'teamB': teamB.toJson(),
      'scoreA': scoreA,
      'scoreB': scoreB,
      'status': status.name,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      roundIndex: json['roundIndex'] as int,
      courtIndex: json['courtIndex'] as int,
      teamA: Team.fromJson(json['teamA'] as Map<String, dynamic>),
      teamB: Team.fromJson(json['teamB'] as Map<String, dynamic>),
      scoreA: json['scoreA'] as int?,
      scoreB: json['scoreB'] as int?,
      status: MatchStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MatchStatus.scheduled,
      ),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'Match(round: $roundIndex, court: $courtIndex, status: $status)';
}

/// Represents a bye (player sitting out a round)
class Bye {
  const Bye({
    required this.playerId,
    required this.roundIndex,
  });

  final String playerId;
  final int roundIndex;

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'roundIndex': roundIndex,
    };
  }

  factory Bye.fromJson(Map<String, dynamic> json) {
    return Bye(
      playerId: json['playerId'] as String,
      roundIndex: json['roundIndex'] as int,
    );
  }
}

/// Represents a round in the tournament
class Round {
  Round({
    required this.index,
    required this.matches,
    this.byes = const [],
    this.status = RoundStatus.pending,
    this.startedAt,
    this.completedAt,
  });

  final int index;
  final List<Match> matches;
  final List<Bye> byes;
  final RoundStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// Check if all matches in this round are complete
  bool get isComplete =>
      matches.every((m) => m.status == MatchStatus.completed);

  /// Get match by court index
  Match? getMatchByCourt(int courtIndex) {
    try {
      return matches.firstWhere((m) => m.courtIndex == courtIndex);
    } catch (_) {
      return null;
    }
  }

  /// Get matches count that are completed
  int get completedMatchesCount =>
      matches.where((m) => m.status == MatchStatus.completed).length;

  Round copyWith({
    int? index,
    List<Match>? matches,
    List<Bye>? byes,
    RoundStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return Round(
      index: index ?? this.index,
      matches: matches ?? this.matches,
      byes: byes ?? this.byes,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'matches': matches.map((m) => m.toJson()).toList(),
      'byes': byes.map((b) => b.toJson()).toList(),
      'status': status.name,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      index: json['index'] as int,
      matches: (json['matches'] as List)
          .map((m) => Match.fromJson(m as Map<String, dynamic>))
          .toList(),
      byes: (json['byes'] as List?)
              ?.map((b) => Bye.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      status: RoundStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RoundStatus.pending,
      ),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'Round(index: $index, matches: ${matches.length}, byes: ${byes.length})';
}
