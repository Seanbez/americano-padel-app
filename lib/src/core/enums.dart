/// Tournament format types
enum TournamentFormat {
  americano('Americano', 'Open format - any player can partner with anyone'),
  mixedAmericano('Mixed Americano', 'Teams must be one male + one female'),
  sameSexMale('Same Sex (Male)', 'All male players'),
  sameSexFemale('Same Sex (Female)', 'All female players');

  const TournamentFormat(this.displayName, this.description);

  final String displayName;
  final String description;

  bool get requiresGender => this == TournamentFormat.mixedAmericano;
  bool get isMixed => this == TournamentFormat.mixedAmericano;
}

/// Tournament mode - determines planning strategy
enum TournamentMode {
  openEnded('Open Ended', 'No fixed end - organizer ends manually'),
  roundsPlanned('Rounds Planned', 'Plan specific number of rounds'),
  timePlanned('Time Planned', 'Plan based on available time');

  const TournamentMode(this.displayName, this.description);

  final String displayName;
  final String description;

  bool get hasPlannedEnd => this != TournamentMode.openEnded;
  bool get isTimeBased => this == TournamentMode.timePlanned;
  bool get isRoundsBased => this == TournamentMode.roundsPlanned;
}

/// Tournament status
enum TournamentStatus {
  draft('Draft'),
  ready('Ready'),
  scheduled('Scheduled'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  const TournamentStatus(this.displayName);

  final String displayName;

  bool get canEdit => this == TournamentStatus.draft;
  bool get canStart => this == TournamentStatus.ready || this == TournamentStatus.scheduled;
  bool get isActive => this == TournamentStatus.inProgress;
  bool get isFinished => this == TournamentStatus.completed || this == TournamentStatus.cancelled;
}

/// Player gender
enum Gender {
  male('Male', 'M'),
  female('Female', 'F'),
  unspecified('Unspecified', '-');

  const Gender(this.displayName, this.shortName);

  final String displayName;
  final String shortName;
}

/// Match status
enum MatchStatus {
  scheduled('Scheduled'),
  inProgress('In Progress'),
  completed('Completed'),
  bye('Bye');

  const MatchStatus(this.displayName);

  final String displayName;
}

/// Round status
enum RoundStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed');

  const RoundStatus(this.displayName);

  final String displayName;
}
