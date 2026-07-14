// lib/features/users/presentation/pages/user_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:jireta_loan/core/utils/constants.dart';
import 'package:jireta_loan/features/users/domain/entities/user_management.dart';
import 'package:jireta_loan/features/users/presentation/providers/user_notifier.dart';
import 'package:jireta_loan/features/users/presentation/widgets/user_table_row.dart';
import 'package:jireta_loan/shared/widgets/confirm_dialog.dart';
import 'package:jireta_loan/shared/widgets/empty_state.dart';
import 'package:jireta_loan/shared/widgets/error_banner.dart';
import 'package:jireta_loan/shared/widgets/loading_overlay.dart';
import 'package:jireta_loan/shared/widgets/search_bar_widget.dart';
import 'package:jireta_loan/shared/widgets/status_chip.dart';

class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({super.key});

  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  String? _roleFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  void _loadUsers() {
    ref.read(userFeatureProvider.notifier).loadUsers(
          role: _roleFilter,
          search: _searchQuery.isEmpty ? null : _searchQuery,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userFeatureProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Management',
                            style: TextStyles.headlineSmall(context),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage system users, roles, and access.',
                            style: TextStyles.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/head-employee/users/create'),
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Create User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorTokens.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchBarWidget(
                        hintText: 'Search users by name or email...',
                        onChanged: (value) {
                          _searchQuery = value;
                          _loadUsers();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RoleFilterDropdown(
                      currentFilter: _roleFilter,
                      onChanged: (value) {
                        setState(() => _roleFilter = value);
                        _loadUsers();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light
                        ? ColorTokens.lightSurface
                        : ColorTokens.darkSurface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text('User',
                              style: TextStyles.labelMedium(context))),
                      Expanded(
                          flex: 2,
                          child: Text('Role',
                              style: TextStyles.labelMedium(context))),
                      Expanded(
                          flex: 2,
                          child: Text('Phone',
                              style: TextStyles.labelMedium(context))),
                      Expanded(
                          flex: 1,
                          child: Text('Status',
                              style: TextStyles.labelMedium(context))),
                      Expanded(
                          flex: 2,
                          child: Text('Last Login',
                              style: TextStyles.labelMedium(context))),
                      Expanded(
                          flex: 2,
                          child: Text('Actions',
                              style: TextStyles.labelMedium(context))),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: switch (state) {
                  UsersLoading() => const Center(
                      child: CircularProgressIndicator()),
                  UserError(:final message) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: ErrorBanner(message: message),
                    ),
                  UsersLoaded(:final users) => users.isEmpty
                      ? const Center(
                          child: EmptyState(
                            icon: Icons.people_outline,
                            title: 'No users found',
                            subtitle: 'Try adjusting your search or filters.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return UserTableRow(
                              user: user,
                              onTap: () => context
                                  .push('/head-employee/users/${user.id}'),
                              onRoleChanged: (newRole) =>
                                  _handleRoleChange(user, newRole),
                              onDeactivate: () =>
                                  _handleDeactivate(user),
                              onReactivate: () =>
                                  _handleReactivate(user),
                              onResetPassword: () =>
                                  _handleResetPassword(user),
                              onForceLogout: () =>
                                  _handleForceLogout(user),
                            );
                          },
                        ),
                  UserOperationSuccess(:final message) => _buildSuccessView(message),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          ),
          if (state is UsersLoading)
            const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSuccessView(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ColorTokens.lightSuccess,
        ),
      );
      _loadUsers();
    });
    return const SizedBox.shrink();
  }

  Future<void> _handleRoleChange(UserManagement user, String newRole) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Change User Role',
        message:
            'Are you sure you want to change ${user.displayName}\'s role to ${newRole.toUpperCase()}? This action requires re-authentication.',
        confirmLabel: 'Change Role',
        isDestructive: true,
      ),
    );
    if (confirmed == true) {
      ref.read(userFeatureProvider.notifier).updateUserRole(
            userId: user.id,
            newRole: newRole,
          );
    }
  }

  Future<void> _handleDeactivate(UserManagement user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Deactivate User',
        message:
            'Are you sure you want to deactivate ${user.displayName}? They will lose access to the system.',
        confirmLabel: 'Deactivate',
        isDestructive: true,
      ),
    );
    if (confirmed == true) {
      ref.read(userFeatureProvider.notifier).deactivateUser(user.id);
    }
  }

  Future<void> _handleReactivate(UserManagement user) async {
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

  Future<void> _handleResetPassword(UserManagement user) async {
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

  Future<void> _handleForceLogout(UserManagement user) async {
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
}

class _RoleFilterDropdown extends StatelessWidget {
  final String? currentFilter;
  final ValueChanged<String?> onChanged;

  const _RoleFilterDropdown({
    required this.currentFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? ColorTokens.lightBorder
              : ColorTokens.darkBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: currentFilter,
          hint: Text('All Roles', style: theme.textTheme.bodySmall),
          isDense: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Roles'),
            ),
            ...AppConstants.validRoles.map((role) => DropdownMenuItem<String?>(
                  value: role,
                  child: Text(role[0].toUpperCase() + role.substring(1)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
