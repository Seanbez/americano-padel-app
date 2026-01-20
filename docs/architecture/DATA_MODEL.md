# Americano App - Data Model

**Document Class:** Architecture  
**Lifecycle State:** ACTIVE  
**Version:** 2.0  
**Last Updated:** 2026-01-20

---

## Core Entities

### Tournament
```dart
class Tournament {
  final String id;
  final String name;
  final DateTime date;
  final TournamentFormat format;
  final TournamentStatus status;
  final TournamentSettings? settings;
  final WinnerSummary? winnerSummary;
  final List<Player> players;
  final List<Round> rounds;
  final List<PlayerStanding> standings;
  final int? seed;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? completedAt;
}
```

### TournamentSettings
```dart
class TournamentSettings {
  final int courtsCount;
  final int pointsPerMatch;
  final int matchDurationMinutes;
  final TournamentMode mode;
  final int? plannedRounds;
  final int? totalMinutes;
  final bool lockTotalPoints;
  final bool allowEditsAfterEnd;
}
```

### WinnerSummary
```dart
class WinnerSummary {
  final String overallWinnerPlayerId;
  final List<String> top3PlayerIds;
  final String? mixedTopMalePlayerId;
  final String? mixedTopFemalePlayerId;
  final DateTime finalizedAt;
}
```

## Enumerations

### TournamentMode
- `openEnded` - Organizer decides when to end
- `roundsPlanned` - Fixed number of rounds
- `timePlanned` - Based on available time

### TournamentStatus
- `draft` - Creating
- `scheduled` - Scheduled for future
- `ready` - Ready to begin
- `inProgress` - Running
- `completed` - Winners determined
- `cancelled` - Cancelled

### TournamentFormat
- `americano` - Open format
- `mixedAmericano` - Teams must be 1M + 1F
- `sameSexMale` - All male
- `sameSexFemale` - All female

---

## Related Documents

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [ALGORITHMS.md](ALGORITHMS.md)
