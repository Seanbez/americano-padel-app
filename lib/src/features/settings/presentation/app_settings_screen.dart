import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/branding_service.dart';
import '../../../utils/url_utils.dart';
import '../../tournaments/data/tournament_repository.dart';

/// Global application settings screen with data management options.
class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        children: [
          // About Section
          _buildSectionHeader(context, 'About'),
          
          // B-Bot Logo
          _BbotLogoWidget(),
          const SizedBox(height: 16),
          
          const ListTile(
            leading: Icon(Icons.sports_tennis),
            title: Text('Padel Americana'),
            subtitle: Text('Version 1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Open-source tournament management'),
            subtitle: Text('For Padel Americana format'),
          ),
          
          // B-Bot Branding Tiles
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
            title: const Text('Designed by B-Bot Cloud'),
            subtitle: const Text('Custom tournament apps & club tools'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => UrlUtils.launchExternalUrl(
              context,
              BrandingService.bbotWebsiteUrl,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.handshake, color: Colors.teal),
            title: const Text('Need a custom app?'),
            subtitle: const Text('Ask for Sean & Melanie Bezuidenhout • b-bot.cloud'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => UrlUtils.launchExternalUrl(
              context,
              BrandingService.bbotWebsiteUrl,
            ),
          ),
          const Divider(),

          // Data Management Section
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Local Storage'),
            subtitle: const Text('All data is stored locally on your device'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
            onTap: () {},
          ),
          const Divider(),

          // Danger Zone
          _buildSectionHeader(context, 'Danger Zone', isWarning: true),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'These actions will permanently delete all app data and cannot be undone.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('Clear All App Data'),
            subtitle: const Text(
              'Delete all tournaments, players, and history',
            ),
            onTap: () => _showClearAllDataDialog(context, ref),
          ),
          
          // Footer
          const SizedBox(height: 32),
          const _BbotFooter(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isWarning
                  ? Colors.red
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _showClearAllDataDialog(
      BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('Clear All App Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete:\n\n'
              '• All tournaments\n'
              '• All player data\n'
              '• All match history\n'
              '• All standings and statistics\n\n'
              'This action cannot be undone.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Type CLEAR ALL to confirm:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'CLEAR ALL',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              final input = controller.text.trim().toUpperCase();
              if (input == 'CLEAR ALL' || input == 'CLEARALL') {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type CLEAR ALL to confirm'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(tournamentRepositoryProvider);
        await repository.clearAllLocalData();
        if (context.mounted) {
          context.go('/'); // Navigate to home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All app data has been cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// B-Bot logo widget with Firebase Storage fetch and fallback
class _BbotLogoWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrlAsync = ref.watch(bbotLogoUrlProvider);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: logoUrlAsync.when(
          loading: () => const SizedBox(
            height: 64,
            width: 64,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Icon(
            Icons.auto_awesome,
            size: 48,
            color: Colors.deepPurple,
          ),
          data: (url) {
            if (url == null) {
              return const Icon(
                Icons.auto_awesome,
                size: 48,
                color: Colors.deepPurple,
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Colors.deepPurple,
                ),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 64,
                    width: 64,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Footer widget for B-Bot branding
class _BbotFooter extends StatelessWidget {
  const _BbotFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => UrlUtils.launchExternalUrl(
        context,
        BrandingService.bbotWebsiteUrl,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Powered by B-Bot Cloud • b-bot.cloud',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
