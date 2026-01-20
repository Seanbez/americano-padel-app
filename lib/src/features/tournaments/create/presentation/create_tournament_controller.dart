import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums.dart';
import '../../../players/domain/player.dart';
import '../../../scheduling/application/time_recommendation_service.dart';
import '../../domain/tournament.dart';

/// State for the tournament creation wizard
class CreateTournamentState {
  const CreateTournamentState({
    this.currentStep = 0,
    this.name = '',
    this.date,
    this.format = TournamentFormat.americano,
    this.mode = TournamentMode.openEnded,
    this.courtsCount = 2,
    this.pointsPerMatch = 24,
    this.plannedRounds,
    this.totalMinutes,
    this.matchMinutesEstimate = 12,
    this.changeoverMinutes = 3,
    this.lockTotalPoints = true,
    this.players = const [],
    this.isGeneratingSchedule = false,
    this.generatedTournament,
    this.timeRecommendation,
    this.error,
  });

  final int currentStep;
  final String name;
  final DateTime? date;
  final TournamentFormat format;
  final TournamentMode mode;
  final int courtsCount;
  final int pointsPerMatch;
  final int? plannedRounds;
  final int? totalMinutes;
  final int matchMinutesEstimate;
  final int changeoverMinutes;
  final bool lockTotalPoints;
  final List<Player> players;
  final bool isGeneratingSchedule;
  final Tournament? generatedTournament;
  final TimeRecommendation? timeRecommendation;
  final String? error;

  bool get isStep1Valid => name.trim().isNotEmpty && date != null;

  bool get isStep2Valid => true; // Format is always selected

  bool get isStep3Valid {
    if (courtsCount < 2 || courtsCount > 10) return false;
    if (mode == TournamentMode.roundsPlanned && (plannedRounds == null || plannedRounds! < 1)) {
      return false;
    }
    if (mode == TournamentMode.timePlanned && (totalMinutes == null || totalMinutes! < 15)) {
      return false;
    }
    return true;
  }

  bool get isStep4Valid {
    final activePlayers = players.where((p) => p.isActive).toList();
    if (activePlayers.length < 4) return false;

    if (format == TournamentFormat.mixedAmericano) {
      final males = activePlayers.where((p) => p.gender == Gender.male).length;
      final females =
          activePlayers.where((p) => p.gender == Gender.female).length;
      return males == females && males >= 2;
    }

    return true;
  }

  bool get canProceed {
    switch (currentStep) {
      case 0:
        return isStep1Valid;
      case 1:
        return isStep2Valid;
      case 2:
        return isStep3Valid;
      case 3:
        return isStep4Valid;
      case 4:
        return generatedTournament != null;
      default:
        return false;
    }
  }

  int get totalSteps => 5;

  String get stepTitle {
    switch (currentStep) {
      case 0:
        return 'Tournament Info';
      case 1:
        return 'Format';
      case 2:
        return 'Settings';
      case 3:
        return 'Players';
      case 4:
        return 'Review & Confirm';
      default:
        return '';
    }
  }

  /// Build tournament settings from current state
  TournamentSettings toSettings() {
    return TournamentSettings(
      courtsCount: courtsCount,
      pointsPerMatch: pointsPerMatch,
      matchDurationMinutes: matchMinutesEstimate,
      mode: mode,
      plannedRounds: plannedRounds,
      totalMinutes: totalMinutes,
      matchMinutesEstimate: matchMinutesEstimate,
      changeoverMinutes: changeoverMinutes,
      recommendedServesPerPlayer: timeRecommendation?.recommendedServesPerPlayer,
      recommendedTotalPointsPerMatch: timeRecommendation?.recommendedTotalPointsPerMatch,
      lockTotalPoints: lockTotalPoints,
      allowEditsAfterEnd: false,
    );
  }

  CreateTournamentState copyWith({
    int? currentStep,
    String? name,
    DateTime? date,
    TournamentFormat? format,
    TournamentMode? mode,
    int? courtsCount,
    int? pointsPerMatch,
    int? plannedRounds,
    int? totalMinutes,
    int? matchMinutesEstimate,
    int? changeoverMinutes,
    bool? lockTotalPoints,
    List<Player>? players,
    bool? isGeneratingSchedule,
    Tournament? generatedTournament,
    TimeRecommendation? timeRecommendation,
    String? error,
    bool clearError = false,
    bool clearGenerated = false,
    bool clearRecommendation = false,
  }) {
    return CreateTournamentState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      date: date ?? this.date,
      format: format ?? this.format,
      mode: mode ?? this.mode,
      courtsCount: courtsCount ?? this.courtsCount,
      pointsPerMatch: pointsPerMatch ?? this.pointsPerMatch,
      plannedRounds: plannedRounds ?? this.plannedRounds,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      matchMinutesEstimate: matchMinutesEstimate ?? this.matchMinutesEstimate,
      changeoverMinutes: changeoverMinutes ?? this.changeoverMinutes,
      lockTotalPoints: lockTotalPoints ?? this.lockTotalPoints,
      players: players ?? this.players,
      isGeneratingSchedule: isGeneratingSchedule ?? this.isGeneratingSchedule,
      generatedTournament:
          clearGenerated ? null : (generatedTournament ?? this.generatedTournament),
      timeRecommendation:
          clearRecommendation ? null : (timeRecommendation ?? this.timeRecommendation),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for managing tournament creation state
class CreateTournamentNotifier extends StateNotifier<CreateTournamentState> {
  CreateTournamentNotifier() : super(CreateTournamentState(date: DateTime.now()));

  final _timeService = const TimeRecommendationService();

  void setName(String name) {
    state = state.copyWith(name: name, clearError: true);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date, clearError: true);
  }

  void setFormat(TournamentFormat format) {
    state = state.copyWith(format: format, clearError: true, clearGenerated: true);
  }

  void setMode(TournamentMode mode) {
    state = state.copyWith(
      mode: mode,
      clearError: true,
      clearGenerated: true,
      clearRecommendation: true,
    );
  }

  void setCourtsCount(int count) {
    state = state.copyWith(courtsCount: count, clearError: true, clearGenerated: true);
    _updateTimeRecommendation();
  }

  void setPointsPerMatch(int points) {
    state = state.copyWith(pointsPerMatch: points, clearError: true);
  }

  void setPlannedRounds(int? rounds) {
    state = state.copyWith(plannedRounds: rounds, clearError: true, clearGenerated: true);
  }

  void setTotalMinutes(int? minutes) {
    state = state.copyWith(totalMinutes: minutes, clearError: true, clearGenerated: true);
    _updateTimeRecommendation();
  }

  void setMatchMinutesEstimate(int minutes) {
    state = state.copyWith(matchMinutesEstimate: minutes, clearError: true);
    _updateTimeRecommendation();
  }

  void setChangeoverMinutes(int minutes) {
    state = state.copyWith(changeoverMinutes: minutes, clearError: true);
    _updateTimeRecommendation();
  }

  void setLockTotalPoints(bool lock) {
    state = state.copyWith(lockTotalPoints: lock, clearError: true);
  }

  void _updateTimeRecommendation() {
    if (state.mode != TournamentMode.timePlanned || state.totalMinutes == null) {
      return;
    }

    final playerCount = state.players.where((p) => p.isActive).length;
    if (playerCount < 4) return;

    final recommendation = _timeService.generateRecommendation(
      totalMinutes: state.totalMinutes!,
      matchMinutesEstimate: state.matchMinutesEstimate,
      changeoverMinutes: state.changeoverMinutes,
      courtsCount: state.courtsCount,
      playerCount: playerCount,
    );

    state = state.copyWith(
      timeRecommendation: recommendation,
      // Auto-apply recommended points if not manually overridden
      pointsPerMatch: recommendation.recommendedTotalPointsPerMatch,
    );
  }

  void applyRecommendation() {
    if (state.timeRecommendation != null) {
      state = state.copyWith(
        pointsPerMatch: state.timeRecommendation!.recommendedTotalPointsPerMatch,
      );
    }
  }

  void addPlayer(Player player) {
    state = state.copyWith(
      players: [...state.players, player],
      clearError: true,
      clearGenerated: true,
    );
    _updateTimeRecommendation();
  }

  void updatePlayer(Player player) {
    state = state.copyWith(
      players: state.players.map((p) => p.id == player.id ? player : p).toList(),
      clearError: true,
      clearGenerated: true,
    );
    _updateTimeRecommendation();
  }

  void removePlayer(String playerId) {
    state = state.copyWith(
      players: state.players.where((p) => p.id != playerId).toList(),
      clearError: true,
      clearGenerated: true,
    );
    _updateTimeRecommendation();
  }

  void togglePlayerActive(String playerId) {
    state = state.copyWith(
      players: state.players.map((p) {
        if (p.id == playerId) {
          return p.copyWith(isActive: !p.isActive);
        }
        return p;
      }).toList(),
      clearError: true,
      clearGenerated: true,
    );
    _updateTimeRecommendation();
  }

  void nextStep() {
    if (state.canProceed && state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1, clearError: true);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  void setGeneratedTournament(Tournament tournament) {
    state = state.copyWith(
      generatedTournament: tournament,
      isGeneratingSchedule: false,
      clearError: true,
    );
  }

  void setGenerating(bool generating) {
    state = state.copyWith(isGeneratingSchedule: generating);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isGeneratingSchedule: false);
  }

  void reset() {
    state = CreateTournamentState(date: DateTime.now());
  }
}

/// Provider for tournament creation state
final createTournamentProvider =
    StateNotifierProvider.autoDispose<CreateTournamentNotifier, CreateTournamentState>(
  (ref) => CreateTournamentNotifier(),
);
