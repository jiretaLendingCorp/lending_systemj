import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';

/// Circle avatar with initials fallback and role color.
///
/// Displays a user avatar image when [avatarUrl] is provided, or
/// falls back to showing coloured initials derived from [fullName].
/// The background colour is determined by the user's role, making it
/// easy to identify roles at a glance.
///
/// ```dart
/// AvatarWidget(
///   fullName: 'Juan Dela Cruz',
///   role: 'admin',
///   avatarUrl: 'https://...',
///   radius: 24,
/// )
/// ```
class AvatarWidget extends StatelessWidget {
  /// Full name used to generate initials when no avatar URL is available.
  final String fullName;

  /// Remote avatar image URL. When `null`, initials are shown.
  final String? avatarUrl;

  /// User role string that determines the fallback colour.
  /// Accepted values: 'admin', 'manager', 'rider', 'borrower'.
  final String? role;

  /// Radius of the circular avatar. Defaults to 20.
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
        backgroundColor: roleColor.withValues(alpha: 0.15),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: roleColor.withValues(alpha: 0.15),
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

  /// Extract up to two initials from a full name.
  ///
  /// - "Juan Dela Cruz" → "JD"
  /// - "Maria" → "MA"
  /// - "" → "?"
  String _initials(String name) {
    if (name.trim().isEmpty) return '?';

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    // Single-word name: take first two characters
    final single = parts[0];
    return single.length >= 2
        ? single.substring(0, 2).toUpperCase()
        : single.toUpperCase();
  }

  /// Map a role string to its design colour.
  Color _roleColor(String? role) {
    return switch (role?.toLowerCase()) {
      'admin' => ColorTokens.roleAdmin,
      'manager' => ColorTokens.roleManager,
      'rider' => ColorTokens.roleRider,
      'borrower' => ColorTokens.roleBorrower,
      _ => ColorTokens.accent,
    };
  }
}
