// lib/features/users/presentation/widgets/role_dropdown.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/constants.dart';
import 'package:jireta_loan/features/auth/domain/entities/user.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
          color: roleColor.withValues(alpha: 0.1),
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
          icon: const Icon(LucideIcons.chevronDown, size: 16),
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

  Color _roleColor(UserRole role) {
    return switch (role) {
      UserRole.headManager => ColorTokens.roleHeadManager,
      UserRole.employee => ColorTokens.roleEmployee,
      UserRole.rider => ColorTokens.roleRider,
      UserRole.lender => ColorTokens.roleLender,
    };
  }
}
