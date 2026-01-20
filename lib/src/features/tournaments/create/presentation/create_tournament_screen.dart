import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums.dart';
import '../../../players/domain/player.dart';
import '../../../scheduling/application/americano_scheduler.dart';
import '../../data/tournament_repository.dart';
import '../../domain/tournament.dart';
import 'create_tournament_controller.dart';
import 'widgets/wizard_step_indicator.dart';

class CreateTournamentScreen extends ConsumerWidget {
  const CreateTournamentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createTournamentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(context, ref),
        ),
      ),
      body: Column(
        children: [
          WizardStepIndicator(
            currentStep: state.currentStep,
            totalSteps: state.totalSteps,
            stepTitles: const [
              'Info',
              'Format',
              'Courts',
              'Players',
              'Review',
            ],
          ),
          Expanded(
            child: _buildStepContent(context, ref, state),
          ),
          _buildBottomNavigation(context, ref, state),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    WidgetRef ref,
    CreateTournamentState state,
  ) {
    switch (state.currentStep) {
      case 0:
        return _Step1Info(state: state, ref: ref);
      case 1:
        return _Step2Format(state: state, ref: ref);
      case 2:
        return _Step3Courts(state: state, ref: ref);
      case 3:
        return _Step4Players(state: state, ref: ref);
      case 4:
        return _Step5Review(state: state, ref: ref);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    WidgetRef ref,
    CreateTournamentState state,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(createTournamentProvider.notifier).previousStep();
                  },
                  child: const Text('Back'),
                ),
              ),
            if (state.currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: state.currentStep == 0 ? 1 : 1,
              child: FilledButton(
                onPressed: state.canProceed
                    ? () => _handleNextOrComplete(context, ref, state)
                    : null,
                child: Text(
                  state.currentStep == state.totalSteps - 1
                      ? 'Create Tournament'
                      : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNextOrComplete(
    BuildContext context,
    WidgetRef ref,
    CreateTournamentState state,
  ) async {
    final notifier = ref.read(createTournamentProvider.notifier);

    if (state.currentStep == state.totalSteps - 1) {
      // Final step - save tournament
      if (state.generatedTournament != null) {
        final repository = ref.read(tournamentRepositoryProvider);
        await repository.saveTournament(state.generatedTournament!);
        if (context.mounted) {
          context.go('/tournament/${state.generatedTournament!.id}');
        }
      }
    } else if (state.currentStep == 3) {
      // Moving from players to review - generate schedule
      notifier.setGenerating(true);
      try {
        final scheduler = AmericanoScheduler();
        final result = scheduler.generateSchedule(
          players: state.players,
          courtsCount: state.courtsCount,
          format: state.format,
        );

        final tournament = Tournament(
          name: state.name,
          date: state.date!,
          format: state.format,
          status: TournamentStatus.ready,
          settings: TournamentSettings(
            courtsCount: state.courtsCount,
            pointsPerMatch: state.pointsPerMatch,
          ),
          players: state.players,
          rounds: result.rounds,
          standings: state.players
              .map((p) => PlayerStanding(playerId: p.id))
              .toList(),
          seed: result.seed,
        );

        notifier.setGeneratedTournament(tournament);
        notifier.nextStep();
      } on ScheduleException catch (e) {
        notifier.setError(e.message);
      } catch (e) {
        notifier.setError('Failed to generate schedule: $e');
      }
    } else {
      notifier.nextStep();
    }
  }

  Future<void> _showExitConfirmation(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Tournament?'),
        content: const Text(
          'Are you sure you want to exit? All entered data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      context.go('/');
    }
  }
}

// Step 1: Tournament Info
class _Step1Info extends StatelessWidget {
  const _Step1Info({required this.state, required this.ref});

  final CreateTournamentState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournament Details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: state.name,
            decoration: const InputDecoration(
              labelText: 'Tournament Name',
              hintText: 'e.g., Saturday Padel Fun',
              prefixIcon: Icon(Icons.emoji_events),
            ),
            onChanged: (value) {
              ref.read(createTournamentProvider.notifier).setName(value);
            },
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(
              state.date != null
                  ? '${state.date!.day}/${state.date!.month}/${state.date!.year}'
                  : 'Select date',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: state.date ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                ref.read(createTournamentProvider.notifier).setDate(date);
              }
            },
          ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Step 2: Format Selection
class _Step2Format extends StatelessWidget {
  const _Step2Format({required this.state, required this.ref});

  final CreateTournamentState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Format',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how teams will be formed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          ...TournamentFormat.values.map((format) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FormatCard(
                format: format,
                isSelected: state.format == format,
                onTap: () {
                  ref.read(createTournamentProvider.notifier).setFormat(format);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  final TournamentFormat format;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _getFormatIcon(format),
                size: 40,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      format.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      format.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                                : colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFormatIcon(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.americano:
        return Icons.shuffle;
      case TournamentFormat.mixedAmericano:
        return Icons.wc;
      case TournamentFormat.sameSexMale:
        return Icons.male;
      case TournamentFormat.sameSexFemale:
        return Icons.female;
    }
  }
}

// Step 3: Courts & Points
class _Step3Courts extends StatelessWidget {
  const _Step3Courts({required this.state, required this.ref});

  final CreateTournamentState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Court Configuration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Text(
            'Number of Courts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(9, (index) {
              final count = index + 2;
              return ChoiceChip(
                label: Text('$count'),
                selected: state.courtsCount == count,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(createTournamentProvider.notifier).setCourtsCount(count);
                  }
                },
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Up to ${state.courtsCount * 4} players can play simultaneously',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          Text(
            'Points per Match',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [16, 21, 24, 32].map((points) {
              return ChoiceChip(
                label: Text('$points'),
                selected: state.pointsPerMatch == points,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(createTournamentProvider.notifier).setPointsPerMatch(points);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Total points split between teams each match',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// Step 4: Players
class _Step4Players extends StatefulWidget {
  const _Step4Players({required this.state, required this.ref});

  final CreateTournamentState state;
  final WidgetRef ref;

  @override
  State<_Step4Players> createState() => _Step4PlayersState();
}

class _Step4PlayersState extends State<_Step4Players> {
  final _nameController = TextEditingController();
  Gender _selectedGender = Gender.unspecified;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePlayers =
        widget.state.players.where((p) => p.isActive).toList();
    final maleCount =
        activePlayers.where((p) => p.gender == Gender.male).length;
    final femaleCount =
        activePlayers.where((p) => p.gender == Gender.female).length;

    return Column(
      children: [
        // Player count summary
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CountBadge(
                label: 'Total',
                count: activePlayers.length,
                color: Theme.of(context).colorScheme.primary,
              ),
              if (widget.state.format == TournamentFormat.mixedAmericano) ...[
                _CountBadge(
                  label: 'Male',
                  count: maleCount,
                  color: Colors.blue,
                ),
                _CountBadge(
                  label: 'Female',
                  count: femaleCount,
                  color: Colors.pink,
                ),
              ],
            ],
          ),
        ),
        // Validation message
        if (widget.state.format == TournamentFormat.mixedAmericano &&
            maleCount != femaleCount)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Text(
              'Mixed format requires equal male and female players',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (activePlayers.length < 4)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Text(
              'Add at least 4 players to continue',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        // Add player form
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Player Name',
                    hintText: 'Enter name',
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _addPlayer(),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.state.format == TournamentFormat.mixedAmericano ||
                  widget.state.format.requiresGender)
                SegmentedButton<Gender>(
                  segments: const [
                    ButtonSegment(value: Gender.male, label: Text('M')),
                    ButtonSegment(value: Gender.female, label: Text('F')),
                  ],
                  selected: {_selectedGender == Gender.unspecified ? Gender.male : _selectedGender},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedGender = selection.first;
                    });
                  },
                ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addPlayer,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        // Player list
        Expanded(
          child: widget.state.players.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No players added yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.state.players.length,
                  itemBuilder: (context, index) {
                    final player = widget.state.players[index];
                    return _PlayerListTile(
                      player: player,
                      onToggleActive: () {
                        widget.ref
                            .read(createTournamentProvider.notifier)
                            .togglePlayerActive(player.id);
                      },
                      onDelete: () {
                        widget.ref
                            .read(createTournamentProvider.notifier)
                            .removePlayer(player.id);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final gender = widget.state.format == TournamentFormat.mixedAmericano
        ? (_selectedGender == Gender.unspecified ? Gender.male : _selectedGender)
        : Gender.unspecified;

    widget.ref.read(createTournamentProvider.notifier).addPlayer(
          Player(name: name, gender: gender),
        );

    _nameController.clear();
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _PlayerListTile extends StatelessWidget {
  const _PlayerListTile({
    required this.player,
    required this.onToggleActive,
    required this.onDelete,
  });

  final Player player;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: player.isActive
              ? _getGenderColor(player.gender).withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          child: Text(
            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: player.isActive ? _getGenderColor(player.gender) : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          player.name,
          style: TextStyle(
            decoration: player.isActive ? null : TextDecoration.lineThrough,
            color: player.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: player.gender != Gender.unspecified
            ? Text(player.gender.displayName)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                player.isActive ? Icons.check_circle : Icons.cancel,
                color: player.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: onToggleActive,
              tooltip: player.isActive ? 'Deactivate' : 'Activate',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Theme.of(context).colorScheme.error,
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  Color _getGenderColor(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Colors.blue;
      case Gender.female:
        return Colors.pink;
      case Gender.unspecified:
        return Colors.grey;
    }
  }
}

// Step 5: Review
class _Step5Review extends StatelessWidget {
  const _Step5Review({required this.state, required this.ref});

  final CreateTournamentState state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (state.isGeneratingSchedule) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating optimal schedule...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Schedule Generation Failed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.read(createTournamentProvider.notifier).goToStep(3);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final tournament = state.generatedTournament;
    if (tournament == null) {
      return const Center(child: Text('No schedule generated'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournament Summary',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow(label: 'Name', value: tournament.name),
                  _SummaryRow(
                    label: 'Date',
                    value:
                        '${tournament.date.day}/${tournament.date.month}/${tournament.date.year}',
                  ),
                  _SummaryRow(label: 'Format', value: tournament.format.displayName),
                  _SummaryRow(label: 'Courts', value: '${tournament.courtsCount}'),
                  _SummaryRow(
                    label: 'Points per Match',
                    value: '${tournament.pointsPerMatch}',
                  ),
                  _SummaryRow(
                    label: 'Players',
                    value: '${tournament.activePlayerCount}',
                  ),
                  _SummaryRow(
                    label: 'Rounds',
                    value: '${tournament.rounds.length}',
                  ),
                  _SummaryRow(
                    label: 'Total Matches',
                    value: '${tournament.rounds.fold<int>(0, (sum, r) => sum + r.matches.length)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Schedule Preview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...tournament.rounds.take(3).map((round) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text('Round ${round.index + 1}'),
                subtitle: Text(
                  '${round.matches.length} matches, ${round.byes.length} byes',
                ),
                children: round.matches.map((match) {
                  final p1 = tournament.getPlayer(match.teamA.player1Id);
                  final p2 = tournament.getPlayer(match.teamA.player2Id);
                  final p3 = tournament.getPlayer(match.teamB.player1Id);
                  final p4 = tournament.getPlayer(match.teamB.player2Id);

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text('${match.courtIndex + 1}'),
                    ),
                    title: Text(
                      '${p1?.name ?? "?"} & ${p2?.name ?? "?"}',
                    ),
                    subtitle: Text(
                      'vs ${p3?.name ?? "?"} & ${p4?.name ?? "?"}',
                    ),
                    dense: true,
                  );
                }).toList(),
              ),
            );
          }),
          if (tournament.rounds.length > 3)
            Center(
              child: Text(
                '+ ${tournament.rounds.length - 3} more rounds',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
