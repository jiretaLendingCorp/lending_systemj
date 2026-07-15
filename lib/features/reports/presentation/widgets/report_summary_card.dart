// lib/features/reports/presentation/widgets/report_summary_card.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReportSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? trend;
  final bool trendUp;

  const ReportSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.trend,
    this.trendUp = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ??
        (theme.brightness == Brightness.light
            ? Colors.white
            : ColorTokens.darkSurface);
    final effectiveIconColor = iconColor ?? ColorTokens.accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? ColorTokens.lightBorder
              : ColorTokens.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: effectiveIconColor),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        size: 12,
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
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyles.headlineSmall(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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
    );
  }
}
