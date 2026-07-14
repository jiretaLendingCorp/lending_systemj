import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/features/auth/domain/entities/user.dart';

/// Color-coded role badge widget.
///
/// Displays the user's role with a distinctive color and icon,
/// suitable for use in headers, list tiles, and profile screens.
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
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
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
        UserRole.admin => ColorTokens.roleAdmin,
        UserRole.manager => ColorTokens.roleManager,
        UserRole.rider => ColorTokens.roleRider,
        UserRole.borrower => ColorTokens.roleBorrower,
      };

  IconData get _roleIcon => switch (role) {
        UserRole.admin => Icons.admin_panel_settings_rounded,
        UserRole.manager => Icons.manage_accounts_rounded,
        UserRole.rider => Icons.two_wheeler_rounded,
        UserRole.borrower => Icons.person_rounded,
      };
}
