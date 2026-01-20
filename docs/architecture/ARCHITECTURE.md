# Americano App - Architecture Document

**Document Class:** Architecture  
**Lifecycle State:** ACTIVE  
**Version:** 2.0  
**Last Updated:** 2026-01-20

---

## Overview

Americano App is a cross-platform mobile application for organizing Padel Americana tournaments. Built with Flutter, it supports iOS, Android, and Web platforms with a clean, professional UI using Material Design 3.

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| UI Framework | Flutter 3.16+ | Cross-platform development |
| State Management | Riverpod 2.x | Reactive state management |
| Navigation | GoRouter | Declarative routing |
| Local Storage | SharedPreferences | Tournament data persistence |
| Hosting | Firebase Hosting | Web deployment |
| Serialization | JSON | Data interchange format |

## Tournament Lifecycle

### Tournament Status Flow

```
                ┌──────────┐
                │  draft   │  Creating tournament
                └────┬─────┘
                     │ Complete wizard
                     ▼
                ┌──────────┐
                │ scheduled│  Scheduled for future date
                └────┬─────┘
                     │ Schedule generated
                     ▼
                ┌──────────┐
                │  ready   │  Ready to start
                └────┬─────┘
                     │ Start button pressed
                     ▼
              ┌────────────┐
              │ inProgress │  Tournament running
              └────┬───────┘
                   │ End button pressed
                   ▼
              ┌────────────┐
              │ completed  │  Winners determined
              └────────────┘
```

### Tournament Modes

| Mode | Description | End Condition |
|------|-------------|---------------|
| `openEnded` | Organizer decides when to end | End button anytime |
| `roundsPlanned` | Fixed number of rounds | Auto-prompt after rounds |
| `timePlanned` | Time-based tournament | Timer recommendations |

## Project Structure

```
lib/
├── main.dart
├── app.dart
└── src/
    ├── core/
    │   └── enums.dart
    ├── routing/
    │   └── app_router.dart
    ├── theme/
    │   └── app_theme.dart
    ├── services/
    │   └── branding_service.dart      # B-Bot Cloud branding
    ├── utils/
    │   └── url_utils.dart             # URL launcher utilities
    └── features/
        ├── home/
        ├── settings/
        ├── players/
        ├── tournaments/
        │   ├── domain/
        │   ├── data/
        │   ├── application/
        │   ├── create/
        │   ├── manage/
        │   ├── results/
        │   ├── settings/
        │   └── scoring/
        ├── scheduling/
        │   └── application/
        └── scoring/
            └── application/
```

## Key Services

### BrandingService
B-Bot Cloud logo and attribution. Uses static Firebase Storage URL.

### TimeRecommendationService
Time-based tournament planning with serves→points mapping.

### TournamentHealthService
Monitors tournament completion and health levels.

### ScoringService
Score validation, standings calculation, winner computation with tie-breakers.

### TournamentRepository
CRUD operations with local persistence, reset flows.

## State Management

| Provider | Type | Purpose |
|----------|------|---------|
| `tournamentRepositoryProvider` | Provider | Repository instance |
| `tournamentsProvider` | FutureProvider | All tournaments |
| `tournamentProvider` | FutureProvider.family | Single tournament |
| `createTournamentProvider` | StateNotifierProvider | Wizard state |
| `bbotLogoUrlProvider` | FutureProvider | B-Bot logo URL |
| `brandingServiceProvider` | Provider | Branding service instance |

---

## Deployment

| Platform | URL | Status |
|----------|-----|--------|
| Web (Production) | https://americano-padel-app.web.app | ✅ Live |
| GitHub | https://github.com/Seanbez/americano-padel-app | ✅ Public |

---

## Related Documents

- [ALGORITHMS.md](ALGORITHMS.md) - Scheduling algorithms
- [DATA_MODEL.md](DATA_MODEL.md) - Data structures
- [../operations/QA_TESTS.md](../operations/QA_TESTS.md) - Test cases
