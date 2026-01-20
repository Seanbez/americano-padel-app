import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/enums.dart';
import '../../scoring/application/scoring_service.dart';
import '../domain/match.dart';
import '../domain/tournament.dart';

/// Repository for tournament data persistence
/// Currently uses SharedPreferences for local storage
/// Can be extended to use Firebase Firestore
class TournamentRepository {
  TournamentRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _tournamentsKey = 'tournaments';
  static const _playersKey = 'players';

  final _scoringService = const ScoringService();

  /// Get all tournaments
  Future<List<Tournament>> getTournaments() async {
    final jsonString = _prefs.getString(_tournamentsKey);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList
        .map((json) => Tournament.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single tournament by ID
  Future<Tournament?> getTournament(String id) async {
    final tournaments = await getTournaments();
    try {
      return tournaments.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Save a tournament (create or update)
  Future<void> saveTournament(Tournament tournament) async {
    final tournaments = await getTournaments();
    final index = tournaments.indexWhere((t) => t.id == tournament.id);

    if (index >= 0) {
      tournaments[index] = tournament;
    } else {
      tournaments.add(tournament);
    }

    await _saveTournaments(tournaments);
  }

  /// Delete a tournament
  Future<void> deleteTournament(String id) async {
    final tournaments = await getTournaments();
    tournaments.removeWhere((t) => t.id == id);
    await _saveTournaments(tournaments);
  }

  /// Save all tournaments
  Future<void> _saveTournaments(List<Tournament> tournaments) async {
    final jsonList = tournaments.map((t) => t.toJson()).toList();
    await _prefs.setString(_tournamentsKey, jsonEncode(jsonList));
  }

  // ========== RESET FLOWS ==========

  /// End tournament: finalize results and lock
  Future<Tournament> endTournament(String tournamentId) async {
    final tournament = await getTournament(tournamentId);
    if (tournament == null) {
      throw RepositoryException('Tournament not found: $tournamentId');
    }

    // Use scoring service to finalize
    final finalized = _scoringService.finalizeTournament(tournament);
    await saveTournament(finalized);
    return finalized;
  }

  /// Reset a single match: clear score and status
  Future<Tournament> resetMatch(String tournamentId, String matchId) async {
    var tournament = await getTournament(tournamentId);
    if (tournament == null) {
      throw RepositoryException('Tournament not found: $tournamentId');
    }

    // Find and reset the match
    final updatedRounds = tournament.rounds.map((round) {
      final updatedMatches = round.matches.map((match) {
        if (match.id == matchId) {
          return match.copyWith(
            scoreA: null,
            scoreB: null,
            status: MatchStatus.scheduled,
            completedAt: null,
          );
        }
        return match;
      }).toList();

      // Recalculate round status
      final allComplete = updatedMatches.every(
        (m) => m.status == MatchStatus.completed || m.status == MatchStatus.bye,
      );
      final anyInProgress = updatedMatches.any(
        (m) => m.status == MatchStatus.inProgress,
      );

      RoundStatus newStatus;
      if (allComplete) {
        newStatus = RoundStatus.completed;
      } else if (anyInProgress || updatedMatches.any((m) => m.status == MatchStatus.completed)) {
        newStatus = RoundStatus.inProgress;
      } else {
        newStatus = RoundStatus.pending;
      }

      return round.copyWith(
        matches: updatedMatches,
        status: newStatus,
      );
    }).toList();

    tournament = tournament.copyWith(rounds: updatedRounds);

    // Recalculate standings
    final standings = _scoringService.recalculateStandingsFromAllMatches(tournament);
    tournament = tournament.copyWith(standings: standings);

    // If tournament was finished and allows edits, re-finalize
    if (tournament.status == TournamentStatus.completed &&
        tournament.settings.allowEditsAfterEnd) {
      tournament = _scoringService.refinalizeTournament(tournament);
    }

    await saveTournament(tournament);
    return tournament;
  }

  /// Reset tournament results but keep schedule
  Future<Tournament> resetTournamentResultsKeepSchedule(String tournamentId) async {
    var tournament = await getTournament(tournamentId);
    if (tournament == null) {
      throw RepositoryException('Tournament not found: $tournamentId');
    }

    // Reset all matches to scheduled, clear scores
    final resetRounds = tournament.rounds.map((round) {
      final resetMatches = round.matches.map((match) {
        if (match.status == MatchStatus.bye) {
          return match; // Keep byes
        }
        return match.copyWith(
          scoreA: null,
          scoreB: null,
          status: MatchStatus.scheduled,
          completedAt: null,
        );
      }).toList();

      return round.copyWith(
        matches: resetMatches,
        status: RoundStatus.pending,
        completedAt: null,
      );
    }).toList();

    // Clear standings and winner summary
    tournament = tournament.copyWith(
      rounds: resetRounds,
      standings: [],
      winnerSummary: null,
      status: TournamentStatus.inProgress,
      endedAt: null,
      completedAt: null,
    );

    await saveTournament(tournament);
    return tournament;
  }

  /// Clear all local data (tournaments and saved players)
  Future<void> clearAllLocalData() async {
    await _prefs.remove(_tournamentsKey);
    await _prefs.remove(_playersKey);
    // Clear any other app data keys
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('tournament_') || key.startsWith('player_')) {
        await _prefs.remove(key);
      }
    }
  }

  /// Start tournament: set status to inProgress
  Future<Tournament> startTournament(String tournamentId) async {
    var tournament = await getTournament(tournamentId);
    if (tournament == null) {
      throw RepositoryException('Tournament not found: $tournamentId');
    }

    // Set first round to in progress
    final updatedRounds = tournament.rounds.asMap().map((index, round) {
      if (index == 0) {
        return MapEntry(index, round.copyWith(status: RoundStatus.inProgress));
      }
      return MapEntry(index, round);
    }).values.toList();

    tournament = tournament.copyWith(
      rounds: updatedRounds,
      status: TournamentStatus.inProgress,
      startedAt: DateTime.now(),
    );

    await saveTournament(tournament);
    return tournament;
  }
}

/// Repository exception
class RepositoryException implements Exception {
  RepositoryException(this.message);
  final String message;

  @override
  String toString() => 'RepositoryException: $message';
}

/// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

/// Provider for TournamentRepository
final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TournamentRepository(prefs);
});

/// Provider for all tournaments
final tournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getTournaments();
});

/// Provider for a single tournament
final tournamentProvider =
    FutureProvider.family<Tournament?, String>((ref, id) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getTournament(id);
});
