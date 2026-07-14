import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/utils/currency_formatter.dart';
import 'package:lendflow/features/riders/domain/entities/rider_task.dart';

/// Task summary card displaying key information about a rider task.
///
/// Shows the task type icon, borrower name, address, amount,
/// and current status. Used in the today's tasks list.
class TaskCard extends StatelessWidget {
  final RiderTask task;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: type icon, borrower name, status
              Row(
                children: [
                  _TypeIcon(type: task.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.borrowerName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.type.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: task.isDisbursement
                                ? ColorTokens.accent
                                : ColorTokens.secondaryAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: task.status),
                ],
              ),

              const SizedBox(height: 12),

              // Address row
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.borrowerAddress,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Amount row
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      task.isDisbursement ? 'Deliver' : 'Collect',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatPhp(task.amount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: task.isDisbursement
                            ? ColorTokens.accent
                            : ColorTokens.secondaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Type icon widget showing a colored circle with the task type icon.
class _TypeIcon extends StatelessWidget {
  final RiderTaskType type;

  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = type == RiderTaskType.disbursement
        ? ColorTokens.accent
        : ColorTokens.secondaryAccent;
    final icon = type == RiderTaskType.disbursement
        ? Icons.outbox_outlined
        : Icons.inbox_outlined;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

/// Status badge showing the current task status.
class _StatusBadge extends StatelessWidget {
  final RiderTaskStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Color get _statusColor => switch (status) {
        RiderTaskStatus.pending => ColorTokens.lightWarning,
        RiderTaskStatus.assigned => ColorTokens.lightInfo,
        RiderTaskStatus.inTransit => ColorTokens.accent,
        RiderTaskStatus.completed => ColorTokens.lightSuccess,
        RiderTaskStatus.failed => ColorTokens.lightError,
      };
}
