import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/theme/text_styles.dart';
import 'package:lendflow/core/utils/date_formatter.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';
import 'package:lendflow/features/users/domain/entities/user_management.dart';
import 'package:lendflow/features/users/presentation/providers/user_notifier.dart';
import 'package:lendflow/shared/widgets/avatar_widget.dart';
import 'package:lendflow/shared/widgets/confirm_dialog.dart';
import 'package:lendflow/shared/widgets/currency_text.dart';
import 'package:lendflow/shared/widgets/status_chip.dart';

/// Web: User detail page with admin actions.
///
/// Displays full user profile information and provides admin
/// actions: reset password, force logout, deactivate/reactivate.
class UserDetailPage extends ConsumerWidget {
  final String userId;

  const UserDetailPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userFeatureProvider);
    final theme = Theme.of(context);

    // Find user from loaded state, or show loading
    UserManagement? user;
    if (state is UsersLoaded) {
      try {
        user = state.users.firstWhere((u) => u.id == userId);
      } catch (_) {
        // User not in current list, need to load
      }
    } else if (state is UserOperationSuccess && state.user != null) {
      user = state.user;
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text('User Details', style: TextStyles.titleLarge(context)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final roleColor = _roleColor(user.role);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('User Details', style: TextStyles.titleLarge(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                _ProfileHeader(user: user, roleColor: roleColor),
                const SizedBox(height: 24),
                // Info cards
                _InfoSection(user: user),
                const SizedBox(height: 24),
                // Action buttons
                _ActionSection(user: user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _roleColor(UserRole role) {
    return switch (role) {
      UserRole.admin => ColorTokens.roleAdmin,
      UserRole.manager => ColorTokens.roleManager,
      UserRole.rider => ColorTokens.roleRider,
      UserRole.borrower => ColorTokens.roleBorrower,
    };
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserManagement user;
  final Color roleColor;

  const _ProfileHeader({
    required this.user,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.white
            : ColorTokens.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? ColorTokens.lightBorder
              : ColorTokens.darkBorder,
        ),
      ),
      child: Row(
        children: [
          AvatarWidget(fullName: user.fullName, radius: 36),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: TextStyles.headlineSmall(context),
                ),
                const SizedBox(height: 4),
                Text(user.email, style: TextStyles.bodyMedium(context)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.roleLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: roleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      label: user.statusLabel,
                      color: user.isActive
                          ? ColorTokens.lightSuccess
                          : ColorTokens.lightError,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final UserManagement user;

  const _InfoSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.light
        ? ColorTokens.lightBorder
        : ColorTokens.darkBorder;
    final bgColor = theme.brightness == Brightness.light
        ? Colors.white
        : ColorTokens.darkSurface;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Information', style: TextStyles.titleMedium(context)),
          const SizedBox(height: 16),
          _InfoRow(label: 'User ID', value: user.id),
          _InfoRow(label: 'Email', value: user.email),
          _InfoRow(label: 'Phone', value: user.phone ?? 'Not provided'),
          _InfoRow(label: 'Role', value: user.roleLabel),
          _InfoRow(label: 'Branch', value: user.branchId ?? 'Not assigned'),
          _InfoRow(
            label: 'Created',
            value: DateFormatter.formatDisplayDateTime(user.createdAt),
          ),
          _InfoRow(
            label: 'Last Login',
            value: user.lastLoginAt != null
                ? DateFormatter.formatDisplayDateTime(user.lastLoginAt!)
                : 'Never',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyles.bodySmall(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends ConsumerWidget {
  final UserManagement user;

  const _ActionSection({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.light
        ? ColorTokens.lightBorder
        : ColorTokens.darkBorder;
    final bgColor = theme.brightness == Brightness.light
        ? Colors.white
        : ColorTokens.darkSurface;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Actions', style: TextStyles.titleMedium(context)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => _handleResetPassword(context, ref),
                icon: const Icon(Icons.lock_reset_outlined, size: 18),
                label: const Text('Reset Password'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorTokens.accent,
                  side: const BorderSide(color: ColorTokens.accent),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _handleForceLogout(context, ref),
                icon: const Icon(Icons.logout_outlined, size: 18),
                label: const Text('Force Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorTokens.lightWarning,
                  side: BorderSide(color: ColorTokens.lightWarning),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
              if (user.isActive)
                OutlinedButton.icon(
                  onPressed: () => _handleDeactivate(context, ref),
                  icon: const Icon(Icons.person_off_outlined, size: 18),
                  label: const Text('Deactivate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorTokens.lightError,
                    side: const BorderSide(color: ColorTokens.lightError),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              if (!user.isActive)
                OutlinedButton.icon(
                  onPressed: () => _handleReactivate(context, ref),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Reactivate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorTokens.lightSuccess,
                    side: const BorderSide(color: ColorTokens.lightSuccess),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleResetPassword(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Reset Password',
        message:
            'A password reset link will be sent to ${user.email}. The user will need to set a new password.',
        confirmLabel: 'Send Reset Link',
      ),
    );
    if (confirmed == true) {
      ref.read(userFeatureProvider.notifier).resetPassword(user.id);
    }
  }

  Future<void> _handleForceLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Force Logout',
        message:
            'This will end all active sessions for ${user.displayName}. They will need to sign in again.',
        confirmLabel: 'Force Logout',
        isDestructive: true,
      ),
    );
    if (confirmed == true) {
      ref.read(userFeatureProvider.notifier).forceLogout(user.id);
    }
  }

  Future<void> _handleDeactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Deactivate User',
        message:
            'Are you sure you want to deactivate ${user.displayName}? They will lose access to the system. This requires re-authentication.',
        confirmLabel: 'Deactivate',
        isDestructive: true,
      ),
    );
    if (confirmed == true) {
      ref.read(userFeatureProvider.notifier).deactivateUser(user.id);
    }
  }

  Future<void> _handleReactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Reactivate User',
        message:
            'Are you sure you want to reactivate ${user.displayName}? They will regain access to the system.',
        confirmLabel: 'Reactivate',
      ),
    );
    if (confirmed == true) {
      ref.read(userFeatureProvider.notifier).reactivateUser(user.id);
    }
  }
}
