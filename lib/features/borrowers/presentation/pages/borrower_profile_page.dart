// lib/features/lenders/presentation/pages/borrower_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/constants.dart';
import 'package:jireta_loan/features/lenders/domain/entities/lender_profile.dart';
import 'package:jireta_loan/features/lenders/presentation/providers/borrower_notifier.dart';
import 'package:jireta_loan/features/lenders/presentation/widgets/kyc_status_card.dart';

class LenderProfilePage extends ConsumerStatefulWidget {
  const LenderProfilePage({super.key});

  @override
  ConsumerState<LenderProfilePage> createState() =>
      _BorrowerProfilePageState();
}

class _BorrowerProfilePageState extends ConsumerState<LenderProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(borrowerFeatureProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borrowerState = ref.watch(borrowerFeatureProvider);
    final authState = ref.watch(authProvider);
    final userName =
        authState is AppAuthAuthenticated ? (authState.fullName ?? 'Lender') : 'Lender';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(borrowerFeatureProvider.notifier).loadProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          ColorTokens.roleLender.withValues(alpha: 0.1),
                      child: Text(
                        userName.isNotEmpty
                            ? userName.substring(0, 1).toUpperCase()
                            : 'B',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: ColorTokens.roleLender,
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
                        color: ColorTokens.roleLender.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppConstants.roleLender.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ColorTokens.roleLender,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (borrowerState is BorrowerProfileLoaded) ...[
                KycStatusCard(kycStatus: borrowerState.profile.kycStatus),
                const SizedBox(height: 24),

                Text(
                  'Personal Information',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  children: [
                    _infoRow(Icons.person_outline, 'Full Name',
                        borrowerState.profile.fullName),
                    _infoRow(Icons.phone_outlined, 'Phone',
                        borrowerState.profile.phone),
                    _infoRow(Icons.email_outlined, 'Email',
                        borrowerState.profile.email),
                    _infoRow(Icons.location_on_outlined, 'Address',
                        borrowerState.profile.address),
                    _infoRow(Icons.work_outline, 'Employment',
                        borrowerState.profile.employmentType.label),
                    _infoRow(
                      Icons.payments_outlined,
                      'Monthly Income',
                      borrowerState.profile.monthlyIncome > 0
                          ? '₱${borrowerState.profile.monthlyIncome.toStringAsFixed(0)}'
                          : 'Not set',
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              Text(
                'Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _InfoCard(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Payment reminders & updates'),
                    secondary: const Icon(Icons.notifications_outlined),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Biometric Login'),
                    subtitle: const Text('Use fingerprint or face ID'),
                    secondary: const Icon(Icons.fingerprint),
                    value: false,
                    onChanged: (value) {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSignOutDialog(),
                  icon: Icon(Icons.logout, color: theme.colorScheme.error),
                  label: Text(
                    'Sign Out',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Not set',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile coming soon')),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
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
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}
