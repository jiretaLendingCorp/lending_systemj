// lib/features/loans/presentation/widgets/loan_status_timeline.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoanStatusTimeline extends StatelessWidget {
  final Loan loan;
  final Axis direction;
  final bool showDates;

  const LoanStatusTimeline({
    super.key,
    required this.loan,
    this.direction = Axis.horizontal,
    this.showDates = true,
  });

  static const _lifecycle = [
    LoanStatus.draft,
    LoanStatus.submitted,
    LoanStatus.underReview,
    LoanStatus.approved,
    LoanStatus.disbursed,
    LoanStatus.active,
    LoanStatus.paid,
    LoanStatus.closed,
  ];

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return _buildHorizontal(context);
    }
    return _buildVertical(context);
  }

  Widget _buildHorizontal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = _getCurrentIndex();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(_lifecycle.length, (index) {
          final status = _lifecycle[index];
          final isCompleted = index < currentIndex;
          final isCurrent = index == currentIndex;
          final isFuture = index > currentIndex;
          final isSkipped = _isSkipped(status);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimelineNode(
                status: status,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isFuture: isFuture,
                isSkipped: isSkipped,
                isDark: isDark,
                showDates: showDates,
                loan: loan,
              ),
              if (index < _lifecycle.length - 1)
                _TimelineConnector(
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  isDark: isDark,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildVertical(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statuses = _getVerticalStatuses();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(statuses.length, (index) {
          final item = statuses[index];
          final status = item.status;
          final isCompleted = item.isCompleted;
          final isCurrent = item.isCurrent;
          final isFuture = item.isFuture;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _TimelineDot(
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                      isFuture: isFuture,
                      isDark: isDark,
                    ),
                    if (index < statuses.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: isCompleted
                              ? ColorTokens.lightSuccess
                              : isDark
                                  ? ColorTokens.darkBorder
                                  : ColorTokens.lightBorder,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : isCompleted
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                            color: isCurrent
                                ? ColorTokens.accent
                                : isCompleted
                                    ? ColorTokens.lightSuccess
                                    : isFuture
                                        ? isDark
                                            ? ColorTokens.darkDisabled
                                            : ColorTokens.lightDisabled
                                        : isDark
                                            ? ColorTokens.darkText
                                            : ColorTokens.lightText,
                          ),
                        ),
                        if (showDates && _getDateForStatus(status) != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            DateFormatter.formatDisplayDateTime(
                              _getDateForStatus(status)!,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? ColorTokens.darkTextSecondary
                                  : ColorTokens.lightTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  int _getCurrentIndex() {
    final statusIndex = _lifecycle.indexOf(loan.status);
    if (statusIndex >= 0) return statusIndex;

    if (loan.status == LoanStatus.rejected) {
      return 2;
    }
    if (loan.status == LoanStatus.defaulted) {
      return 5;
    }
    return 0;
  }

  bool _isSkipped(LoanStatus status) {
    if (loan.status == LoanStatus.rejected) {
      return status == LoanStatus.approved ||
          status == LoanStatus.disbursed ||
          status == LoanStatus.active ||
          status == LoanStatus.paid ||
          status == LoanStatus.closed;
    }
    if (loan.status == LoanStatus.defaulted) {
      return status == LoanStatus.paid || status == LoanStatus.closed;
    }
    return false;
  }

  DateTime? _getDateForStatus(LoanStatus status) {
    return switch (status) {
      LoanStatus.draft || LoanStatus.submitted => loan.createdAt,
      LoanStatus.approved => loan.approvedAt,
      LoanStatus.disbursed => loan.disbursedAt,
      LoanStatus.active => loan.disbursedAt,
      LoanStatus.paid => loan.dueAt,
      _ => null,
    };
  }

  List<_StatusItem> _getVerticalStatuses() {
    final currentIndex = _getCurrentIndex();
    final items = <_StatusItem>[];

    for (var i = 0; i < _lifecycle.length; i++) {
      final status = _lifecycle[i];
      if (_isSkipped(status) && loan.status != LoanStatus.closed) continue;

      items.add(_StatusItem(
        status: status,
        isCompleted: i < currentIndex,
        isCurrent: i == currentIndex || status == loan.status,
        isFuture: i > currentIndex && status != loan.status,
      ));
    }

    if (loan.status == LoanStatus.rejected) {
      items.add(_StatusItem(
        status: LoanStatus.rejected,
        isCompleted: false,
        isCurrent: true,
        isFuture: false,
      ));
    }

    if (loan.status == LoanStatus.defaulted) {
      items.add(_StatusItem(
        status: LoanStatus.defaulted,
        isCompleted: false,
        isCurrent: true,
        isFuture: false,
      ));
    }

    return items;
  }
}

class _TimelineNode extends StatelessWidget {
  final LoanStatus status;
  final bool isCompleted;
  final bool isCurrent;
  final bool isFuture;
  final bool isSkipped;
  final bool isDark;
  final bool showDates;
  final Loan loan;

  const _TimelineNode({
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.isFuture,
    required this.isSkipped,
    required this.isDark,
    required this.showDates,
    required this.loan,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? ColorTokens.lightSuccess
        : isCurrent
            ? ColorTokens.accent
            : isFuture
                ? isDark
                    ? ColorTokens.darkDisabled
                    : ColorTokens.lightDisabled
                : ColorTokens.lightSuccess;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSkipped
                ? Colors.transparent
                : isCompleted
                    ? color
                    : isCurrent
                        ? color.withValues(alpha: 0.2)
                        : Colors.transparent,
            border: Border.all(
              color: isSkipped
                  ? (isDark ? ColorTokens.darkBorder : ColorTokens.lightBorder)
                  : color,
              width: 2,
            ),
          ),
          child: isCompleted && !isSkipped
              ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
              : isCurrent
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    )
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          status.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isSkipped
                ? (isDark ? ColorTokens.darkDisabled : ColorTokens.lightDisabled)
                : color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;
  final bool isDark;

  const _TimelineConnector({
    required this.isCompleted,
    required this.isCurrent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isCompleted
          ? ColorTokens.lightSuccess
          : isCurrent
              ? ColorTokens.accent.withValues(alpha: 0.5)
              : isDark
                  ? ColorTokens.darkBorder
                  : ColorTokens.lightBorder,
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;
  final bool isFuture;
  final bool isDark;

  const _TimelineDot({
    required this.isCompleted,
    required this.isCurrent,
    required this.isFuture,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? ColorTokens.lightSuccess
        : isCurrent
            ? ColorTokens.accent
            : isFuture
                ? isDark
                    ? ColorTokens.darkDisabled
                    : ColorTokens.lightDisabled
                : ColorTokens.lightSuccess;

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? color
            : isCurrent
                ? color.withValues(alpha: 0.2)
                : Colors.transparent,
        border: Border.all(color: color, width: 2),
      ),
      child: isCompleted
          ? const Icon(LucideIcons.check, size: 10, color: Colors.white)
          : isCurrent
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                )
              : null,
    );
  }
}

class _StatusItem {
  final LoanStatus status;
  final bool isCompleted;
  final bool isCurrent;
  final bool isFuture;

  const _StatusItem({
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.isFuture,
  });
}
