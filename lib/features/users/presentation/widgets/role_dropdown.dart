import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/utils/constants.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';

/// Role selection dropdown widget.
///
/// Displays a compact dropdown for selecting user roles.
/// Used in user creation and user management table rows.
class RoleDropdown extends StatelessWidget {
  final UserRole currentRole;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const RoleDropdown({
    super.key,
    required this.currentRole,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = _roleColor(currentRole);

    if (!enabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: roleColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          currentRole.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: roleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? ColorTokens.lightBorder
              : ColorTokens.darkBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentRole.toApiString(),
          isDense: true,
          isExpanded: false,
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          style: theme.textTheme.bodySmall?.copyWith(
            color: roleColor,
            fontWeight: FontWeight.w600,
          ),
          items: AppConstants.validRoles.map((role) {
            final userRole = UserRole.fromString(role);
            return DropdownMenuItem<String>(
              value: role,
              child: Text(
                userRole.label,
                style: TextStyle(color: _roleColor(userRole)),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null && value != currentRole.toApiString()) {
              onChanged?.call(value);
            }
          },
        ),
      ),
    );
  }

  /// Returns the role-specific color.
  Color _roleColor(UserRole role) {
    return switch (role) {
      UserRole.admin => ColorTokens.roleAdmin,
      UserRole.manager => ColorTokens.roleManager,
      UserRole.rider => ColorTokens.roleRider,
      UserRole.borrower => ColorTokens.roleBorrower,
    };
  }
}
