import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/utils/date_formatter.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';
import 'package:lendflow/features/users/domain/entities/user_management.dart';
import 'package:lendflow/features/users/presentation/widgets/role_dropdown.dart';
import 'package:lendflow/shared/widgets/avatar_widget.dart';
import 'package:lendflow/shared/widgets/status_chip.dart';

/// Data table row for a single [UserManagement] entry.
///
/// Displays user avatar, name, email, role, status, last login,
/// and action buttons for admin operations.
class UserTableRow extends StatelessWidget {
  final UserManagement user;
  final VoidCallback? onTap;
  final ValueChanged<String>? onRoleChanged;
  final VoidCallback? onDeactivate;
  final VoidCallback? onReactivate;
  final VoidCallback? onResetPassword;
  final VoidCallback? onForceLogout;

  const UserTableRow({
    super.key,
    required this.user,
    this.onTap,
    this.onRoleChanged,
    this.onDeactivate,
    this.onReactivate,
    this.onResetPassword,
    this.onForceLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.brightness == Brightness.light
                  ? ColorTokens.lightBorder
                  : ColorTokens.darkBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar + Name + Email
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  AvatarWidget(
                    fullName: user.fullName,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Role
            Expanded(
              flex: 2,
              child: RoleDropdown(
                currentRole: user.role,
                enabled: onRoleChanged != null,
                onChanged: onRoleChanged,
              ),
            ),
            // Phone
            Expanded(
              flex: 2,
              child: Text(
                user.phone ?? '—',
                style: theme.textTheme.bodySmall,
              ),
            ),
            // Status
            Expanded(
              flex: 1,
              child: StatusChip(
                label: user.statusLabel,
                color: user.isActive ? ColorTokens.lightSuccess : ColorTokens.lightError,
              ),
            ),
            // Last Login
            Expanded(
              flex: 2,
              child: Text(
                user.lastLoginAt != null
                    ? DateFormatter.formatDisplayDateTime(user.lastLoginAt!)
                    : 'Never',
                style: theme.textTheme.bodySmall,
              ),
            ),
            // Actions
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (user.isActive && onResetPassword != null)
                    _ActionButton(
                      icon: Icons.lock_reset_outlined,
                      tooltip: 'Reset Password',
                      onTap: onResetPassword!,
                    ),
                  if (user.isActive && onForceLogout != null)
                    _ActionButton(
                      icon: Icons.logout_outlined,
                      tooltip: 'Force Logout',
                      onTap: onForceLogout!,
                    ),
                  if (user.isActive && onDeactivate != null)
                    _ActionButton(
                      icon: Icons.person_off_outlined,
                      tooltip: 'Deactivate',
                      onTap: onDeactivate!,
                      color: ColorTokens.lightError,
                    ),
                  if (!user.isActive && onReactivate != null)
                    _ActionButton(
                      icon: Icons.person_add_outlined,
                      tooltip: 'Reactivate',
                      onTap: onReactivate!,
                      color: ColorTokens.lightSuccess,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: color ?? ColorTokens.accent,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
