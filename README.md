# Americano App

A professional mobile app for organizing Padel Americana tournaments.

## Features

- 🎾 **Tournament Management**: Create and manage Padel Americana tournaments
- 👥 **Player Roster**: Add players with gender and skill ratings
- 🏟️ **Multi-Court Support**: 2-10 courts
- 🔀 **Smart Scheduling**: Fair pairing algorithm minimizing partner/opponent repeats
- 📊 **Live Scoring**: Score entry with validation
- 🏆 **Leaderboard**: Real-time standings

## Tournament Formats

- **Americano**: Open format - any player can partner with anyone
- **Mixed Americano**: Teams must be 1 male + 1 female
- **Same Sex**: All male or all female tournaments

## Getting Started

### Prerequisites

- Flutter SDK 3.16+
- Dart 3.2+
- Android Studio / Xcode (for mobile development)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-repo/americano_app.git
cd americano_app

# Install dependencies
flutter pub get

# Run code generation (for Freezed/Riverpod)
dart run build_runner build

# Run the app
flutter run
```

### Running Tests

```bash
flutter test
```

## Project Structure

```
lib/
├── main.dart              # Entry point
├── app.dart               # App configuration
└── src/
    ├── core/              # Shared utilities
    ├── routing/           # Navigation
    ├── theme/             # Material 3 theme
    └── features/
        ├── home/          # Home screen
        ├── players/       # Player domain
        ├── tournaments/   # Tournament CRUD
        ├── scheduling/    # Pairing algorithm
        └── scoring/       # Score management
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Scheduling Algorithms](docs/ALGORITHMS.md)
- [Data Model](docs/DATA_MODEL.md)
- [QA Test Cases](docs/QA_TESTS.md)

## Points System

Each match has a fixed total (e.g., 24 points). If match ends 14-10:
- Team A players: +14 points each
- Team B players: +10 points each

## License

MIT License
