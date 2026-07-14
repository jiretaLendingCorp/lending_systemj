// lib/shared/widgets/avatar_widget.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';

class AvatarWidget extends StatelessWidget {
  final String fullName;

  final String? avatarUrl;

  final String? role;

  final double radius;

  const AvatarWidget({
    super.key,
    required this.fullName,
    this.avatarUrl,
    this.role,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(role);

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (error, stackTrace) {},
        backgroundColor: roleColor.withOpacity(0.15),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: roleColor.withOpacity(0.15),
      child: Text(
        _initials(fullName),
        style: TextStyle(
          color: roleColor,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final single = parts[0];
    return single.length >= 2
        ? single.substring(0, 2).toUpperCase()
        : single.toUpperCase();
  }

  Color _roleColor(String? role) {
    return switch (role?.toLowerCase()) {
      'head_manager' => ColorTokens.roleHeadManager,
      'employee' => ColorTokens.roleEmployee,
      'rider' => ColorTokens.roleRider,
      'lender' => ColorTokens.roleLender,
      _ => ColorTokens.accent,
    };
  }
}
