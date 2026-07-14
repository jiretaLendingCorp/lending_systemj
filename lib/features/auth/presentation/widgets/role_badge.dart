// lib/features/auth/presentation/widgets/role_badge.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/features/auth/domain/entities/user.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;
  final double fontSize;
  final double iconSize;
  final EdgeInsets padding;
  final bool showIcon;

  const RoleBadge({
    super.key,
    required this.role,
    this.fontSize = 11,
    this.iconSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _roleColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _roleIcon,
              size: iconSize,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            role.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color get _roleColor => switch (role) {
        UserRole.headManager => ColorTokens.roleHeadManager,
        UserRole.employee => ColorTokens.roleEmployee,
        UserRole.rider => ColorTokens.roleRider,
        UserRole.lender => ColorTokens.roleLender,
      };

  IconData get _roleIcon => switch (role) {
        UserRole.headManager => Icons.admin_panel_settings_rounded,
        UserRole.employee => Icons.manage_accounts_rounded,
        UserRole.rider => Icons.two_wheeler_rounded,
        UserRole.lender => Icons.person_rounded,
      };
}
