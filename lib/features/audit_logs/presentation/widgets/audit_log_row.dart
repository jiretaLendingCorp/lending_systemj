// lib/features/audit_logs/presentation/widgets/audit_log_row.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/audit_logs/domain/entities/audit_log.dart';
import 'package:jireta_loan/shared/widgets/avatar_widget.dart';

class AuditLogRow extends StatelessWidget {
  final AuditLog log;
  final VoidCallback? onTap;

  const AuditLogRow({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.light
        ? ColorTokens.lightBorder
        : ColorTokens.darkBorder;
    final categoryColor = _categoryColor(log.actionCategory);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 160,
              child: Text(
                DateFormatter.formatDisplayDateTime(log.createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  AvatarWidget(
                    fullName: log.userRole,
                    radius: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.userId.substring(0, 8),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          log.userRole,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _roleColor(log.userRole),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.action,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                log.entityType != null
                    ? '${log.entityType}${log.entityId != null ? ' #${log.entityId!.substring(0, 8)}' : ''}'
                    : '—',
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: log.hasDiff
                  ? Icon(LucideIcons.arrowLeftRight, size: 16, color: ColorTokens.lightInfo)
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              width: 120,
              child: Text(
                log.ipAddress.isNotEmpty ? log.ipAddress : '—',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    return switch (category) {
      'create' => ColorTokens.lightSuccess,
      'update' => ColorTokens.lightInfo,
      'delete' => ColorTokens.lightError,
      'auth' => ColorTokens.accent,
      'approval' => ColorTokens.lightWarning,
      _ => ColorTokens.lightTextSecondary,
    };
  }

  Color _roleColor(String role) {
    return switch (role.toLowerCase()) {
      'head_manager' => ColorTokens.roleHeadManager,
      'employee' => ColorTokens.roleEmployee,
      'rider' => ColorTokens.roleRider,
      'lender' => ColorTokens.roleLender,
      _ => ColorTokens.lightTextSecondary,
    };
  }
}
