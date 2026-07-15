// lib/features/users/presentation/widgets/user_table_row.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:jireta_loan/features/users/domain/entities/user_management.dart';
import 'package:jireta_loan/features/users/presentation/widgets/role_dropdown.dart';
import 'package:jireta_loan/shared/widgets/avatar_widget.dart';
import 'package:jireta_loan/shared/widgets/status_chip.dart';

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
            Expanded(
              flex: 2,
              child: RoleDropdown(
                currentRole: user.role,
                enabled: onRoleChanged != null,
                onChanged: onRoleChanged,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                user.phone ?? '—',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Expanded(
              flex: 1,
              child: StatusChip(
                label: user.statusLabel,
                statusColor: user.isActive ? StatusColor.success : StatusColor.error,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                user.lastLoginAt != null
                    ? DateFormatter.formatDisplayDateTime(user.lastLoginAt!)
                    : 'Never',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (user.isActive && onResetPassword != null)
                    _ActionButton(
                      icon: LucideIcons.lock,
                      tooltip: 'Reset Password',
                      onTap: onResetPassword!,
                    ),
                  if (user.isActive && onForceLogout != null)
                    _ActionButton(
                      icon: LucideIcons.logOut,
                      tooltip: 'Force Logout',
                      onTap: onForceLogout!,
                    ),
                  if (user.isActive && onDeactivate != null)
                    _ActionButton(
                      icon: LucideIcons.userX,
                      tooltip: 'Deactivate',
                      onTap: onDeactivate!,
                      color: ColorTokens.lightError,
                    ),
                  if (!user.isActive && onReactivate != null)
                    _ActionButton(
                      icon: LucideIcons.userPlus,
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
