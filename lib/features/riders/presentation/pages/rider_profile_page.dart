// lib/features/riders/presentation/pages/rider_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/constants.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RiderProfilePage extends ConsumerWidget {
  const RiderProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final userName = authState is AppAuthAuthenticated ? (authState.fullName ?? 'Rider') : 'Rider';

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
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: ColorTokens.roleRider.withValues(alpha: 0.1),
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
                      color: ColorTokens.roleRider.withValues(alpha: 0.1),
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
                  icon: LucideIcons.circleCheck,
                  label: 'Completed',
                  value: '0',
                  color: ColorTokens.lightSuccess,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: LucideIcons.trendingUp,
                  label: 'Success Rate',
                  value: '0%',
                  color: ColorTokens.accent,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: LucideIcons.navigation,
                  label: 'This Month',
                  value: '0',
                  color: ColorTokens.secondaryAccent,
                ),
              ],
            ),

            const SizedBox(height: 32),

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
                  secondary: const Icon(LucideIcons.bell),
                  value: true,
                  onChanged: (value) {
                  },
                ),
                SwitchListTile.adaptive(
                  title: const Text('Location Services'),
                  subtitle: const Text('Enable GPS for check-ins'),
                  secondary: const Icon(LucideIcons.mapPin),
                  value: true,
                  onChanged: (value) {
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SettingsSection(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.circleQuestionMark),
                  title: const Text('Help & Support'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () {
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.info),
                  title: const Text('About Jireta Loan'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () {
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

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
                            ref.read(authProvider.notifier).signOut();
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
                icon: Icon(LucideIcons.logOut,
                    color: theme.colorScheme.error),
                label: Text(
                  'Sign Out',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
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
