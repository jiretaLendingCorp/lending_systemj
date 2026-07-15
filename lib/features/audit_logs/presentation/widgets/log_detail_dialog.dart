// lib/features/audit_logs/presentation/widgets/log_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/audit_logs/domain/entities/audit_log.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LogDetailDialog extends StatelessWidget {
  final AuditLog log;

  const LogDetailDialog({
    super.key,
    required this.log,
  });

  static Future<void> show(BuildContext context, AuditLog log) {
    return showDialog(
      context: context,
      builder: (context) => LogDetailDialog(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.history, color: ColorTokens.accent, size: 22),
          const SizedBox(width: 8),
          Text('Audit Log Detail', style: TextStyles.titleMedium(context)),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'Log ID', value: log.id),
              _DetailRow(label: 'Timestamp', value: DateFormatter.formatDisplayDateTime(log.createdAt)),
              _DetailRow(
                label: 'User ID',
                value: log.userId,
                valueStyle: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              _DetailRow(label: 'User Role', value: log.userRole),
              _DetailRow(label: 'Action', value: log.action),
              if (log.entityType != null)
                _DetailRow(label: 'Entity Type', value: log.entityType!),
              if (log.entityId != null)
                _DetailRow(
                  label: 'Entity ID',
                  value: log.entityId!,
                  valueStyle: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              _DetailRow(label: 'IP Address', value: log.ipAddress.isNotEmpty ? log.ipAddress : 'N/A'),
              if (log.hasDiff) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text('Value Changes', style: TextStyles.labelLarge(context)),
                const SizedBox(height: 12),
                _DiffView(
                  label: 'Old Value',
                  value: log.oldValue,
                  isOld: true,
                ),
                const SizedBox(height: 8),
                _DiffView(
                  label: 'New Value',
                  value: log.newValue,
                  isOld: false,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyles.bodySmall(context)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: valueStyle ?? theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiffView extends StatelessWidget {
  final String label;
  final String? value;
  final bool isOld;

  const _DiffView({
    required this.label,
    required this.value,
    required this.isOld,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isOld
        ? ColorTokens.lightError.withValues(alpha: 0.06)
        : ColorTokens.lightSuccess.withValues(alpha: 0.06);
    final borderColor = isOld
        ? ColorTokens.lightError.withValues(alpha: 0.2)
        : ColorTokens.lightSuccess.withValues(alpha: 0.2);
    final textColor = isOld ? ColorTokens.lightError : ColorTokens.lightSuccess;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOld ? LucideIcons.minusCircle : LucideIcons.plusCircle,
                size: 14,
                color: textColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            value ?? '(empty)',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
