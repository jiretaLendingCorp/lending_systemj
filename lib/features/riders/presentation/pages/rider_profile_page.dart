import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/utils/constants.dart';
import 'package:lendflow/features/riders/presentation/providers/rider_notifier.dart';

/// Mobile page displaying the rider's profile, stats, and settings.
///
/// Features:
/// - Rider avatar and name
/// - Performance statistics (total completed, success rate)
/// - App settings (notifications, location)
/// - Logout button
class RiderProfilePage extends ConsumerWidget {
  const RiderProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final userName = authState is AuthAuthenticated ? authState.user.name : 'Rider';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: ColorTokens.roleRider.withOpacity(0.1),
                    child: Text(
                      userName.isNotEmpty
                          ? userName.substring(0, 1).toUpperCase()
                          : 'R',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: ColorTokens.roleRider,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorTokens.roleRider.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppConstants.roleRider.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: ColorTokens.roleRider,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Performance stats
            Text(
              'Performance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Completed',
                  value: '0',
                  color: ColorTokens.lightSuccess,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.trending_up_outlined,
                  label: 'Success Rate',
                  value: '0%',
                  color: ColorTokens.accent,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.route_outlined,
                  label: 'This Month',
                  value: '0',
                  color: ColorTokens.secondaryAccent,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Settings
            Text(
              'Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _SettingsSection(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive task notifications'),
                  secondary: const Icon(Icons.notifications_outlined),
                  value: true,
                  onChanged: (value) {
                    // Handle notification toggle
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Location Services'),
                  subtitle: const Text('Enable GPS for check-ins'),
                  secondary: const Icon(Icons.location_on_outlined),
                  value: true,
                  onChanged: (value) {
                    // Handle location toggle
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SettingsSection(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to help
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About LendFlow'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to about
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text(
                          'Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ref.read(authProvider.notifier).logout();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: ColorTokens.lightError,
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.logout,
                    color: theme.colorScheme.error),
                label: Text(
                  'Sign Out',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.error.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Small stat card for displaying performance metrics.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable settings section card.
class _SettingsSection extends StatelessWidget {
  final List<Widget> children;

  const _SettingsSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
