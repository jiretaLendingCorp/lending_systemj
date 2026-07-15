// lib/features/settings/presentation/widgets/settings_section.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final Widget? trailing;

  const SettingsSection({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.children,
    this.trailing,
  });

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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: ColorTokens.accent),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyles.titleMedium(context)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TextStyles.bodySmall(context)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final String label;
  final String? description;
  final Widget control;
  final bool requiresReAuth;

  const SettingsRow({
    super.key,
    required this.label,
    this.description,
    required this.control,
    this.requiresReAuth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    if (requiresReAuth) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Requires re-authentication',
                        child: Icon(
                          LucideIcons.shield,
                          size: 14,
                          color: ColorTokens.lightWarning,
                        ),
                      ),
                    ],
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: TextStyles.bodySmall(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 200,
            child: control,
          ),
        ],
      ),
    );
  }
}
