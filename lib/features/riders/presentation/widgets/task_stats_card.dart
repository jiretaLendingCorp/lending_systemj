// lib/features/riders/presentation/widgets/task_stats_card.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TaskStatsCard extends StatelessWidget {
  final int total;
  final int completed;
  final int pending;
  final int inTransit;

  const TaskStatsCard({
    super.key,
    required this.total,
    required this.completed,
    required this.pending,
    required this.inTransit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Overview",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Total',
                    value: '$total',
                    color: theme.colorScheme.onSurface,
                    icon: LucideIcons.clipboardList,
                  ),
                ),
                _divider(),
                Expanded(
                  child: _StatItem(
                    label: 'Completed',
                    value: '$completed',
                    color: ColorTokens.lightSuccess,
                    icon: LucideIcons.checkCircle,
                  ),
                ),
                _divider(),
                Expanded(
                  child: _StatItem(
                    label: 'Pending',
                    value: '$pending',
                    color: ColorTokens.lightWarning,
                    icon: LucideIcons.clock,
                  ),
                ),
                _divider(),
                Expanded(
                  child: _StatItem(
                    label: 'In Transit',
                    value: '$inTransit',
                    color: ColorTokens.accent,
                    icon: LucideIcons.truck,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: ColorTokens.lightBorder,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
