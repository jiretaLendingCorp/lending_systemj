// lib/features/dashboard/presentation/widgets/kpi_card.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? trend;
  final bool trendUp;
  final String? subtitle;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.trend,
    this.trendUp = true,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? ColorTokens.accent;
    final bgColor = theme.brightness == Brightness.light
        ? Colors.white
        : ColorTokens.darkSurface;
    final borderColor = theme.brightness == Brightness.light
        ? ColorTokens.lightBorder
        : ColorTokens.darkBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: effectiveIconColor),
                ),
                if (trend != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: trendUp
                          ? ColorTokens.lightSuccess.withValues(alpha: 0.1)
                          : ColorTokens.lightError.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                          size: 14,
                          color: trendUp
                              ? ColorTokens.lightSuccess
                              : ColorTokens.lightError,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          trend!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: trendUp
                                ? ColorTokens.lightSuccess
                                : ColorTokens.lightError,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyles.headlineSmall(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyles.bodySmall(context),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ColorTokens.lightTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
