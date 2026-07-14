import 'package:flutter/material.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/utils/currency_formatter.dart';
import 'package:lendflow/core/utils/date_formatter.dart';
import 'package:lendflow/features/loans/domain/entities/loan_schedule.dart';

/// Loan repayment schedule table widget.
///
/// Displays all installments with their number, amount due,
/// due date, and current status. Overdue installments are
/// highlighted in red.
class LoanScheduleTable extends StatelessWidget {
  final List<LoanSchedule> schedule;
  final bool compact;

  const LoanScheduleTable({
    super.key,
    required this.schedule,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (schedule.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_note_rounded,
                size: 48,
                color: isDark ? ColorTokens.darkDisabled : ColorTokens.lightDisabled,
              ),
              const SizedBox(height: 12),
              Text(
                'No schedule available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? ColorTokens.darkTextSecondary
                          : ColorTokens.lightTextSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _SummaryChip(
                label: 'Total',
                value: '${schedule.length} installments',
                color: ColorTokens.accent,
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                label: 'Paid',
                value: '${schedule.where((s) => s.isPaid).length}',
                color: ColorTokens.lightSuccess,
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                label: 'Overdue',
                value:
                    '${schedule.where((s) => s.status == InstallmentStatus.overdue).length}',
                color: ColorTokens.lightError,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
            border: Border(
              bottom: BorderSide(
                color: isDark ? ColorTokens.darkBorder : ColorTokens.lightBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: compact ? 32 : 48, child: Text('#', style: _headerStyle(isDark))),
              Expanded(
                flex: 2,
                child: Text('Amount Due', style: _headerStyle(isDark)),
              ),
              Expanded(
                flex: 2,
                child: Text('Due Date', style: _headerStyle(isDark)),
              ),
              SizedBox(
                width: compact ? 70 : 90,
                child: Text('Status', style: _headerStyle(isDark), textAlign: TextAlign.right),
              ),
            ],
          ),
        ),

        // Schedule rows
        ...schedule.map((item) => _ScheduleRow(
              item: item,
              isDark: isDark,
              compact: compact,
            )),
      ],
    );
  }

  TextStyle _headerStyle(bool isDark) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: isDark ? ColorTokens.darkTextSecondary : ColorTokens.lightTextSecondary,
      letterSpacing: 0.5,
    );
  }
}

/// Single row in the schedule table.
class _ScheduleRow extends StatelessWidget {
  final LoanSchedule item;
  final bool isDark;
  final bool compact;

  const _ScheduleRow({
    required this.item,
    required this.isDark,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = item.isOverdue;
    final isPaid = item.isPaid;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOverdue
            ? ColorTokens.lightError.withValues(alpha: isDark ? 0.08 : 0.04)
            : null,
        border: Border(
          bottom: BorderSide(
            color: isDark ? ColorTokens.darkBorder : ColorTokens.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Installment number
          SizedBox(
            width: compact ? 32 : 48,
            child: Text(
              '${item.installmentNumber}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? ColorTokens.darkText : ColorTokens.lightText,
              ),
            ),
          ),
          // Amount due
          Expanded(
            flex: 2,
            child: Text(
              CurrencyFormatter.formatPhp(item.amountDue),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPaid
                    ? ColorTokens.lightSuccess
                    : isOverdue
                        ? ColorTokens.lightError
                        : isDark
                            ? ColorTokens.darkText
                            : ColorTokens.lightText,
              ),
            ),
          ),
          // Due date
          Expanded(
            flex: 2,
            child: Text(
              DateFormatter.formatDisplayDate(item.dueDate),
              style: TextStyle(
                fontSize: 13,
                color: isOverdue
                    ? ColorTokens.lightError
                    : isDark
                        ? ColorTokens.darkTextSecondary
                        : ColorTokens.lightTextSecondary,
              ),
            ),
          ),
          // Status
          SizedBox(
            width: compact ? 70 : 90,
            child: _StatusChip(status: item.status, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

/// Small status chip for installment status.
class _StatusChip extends StatelessWidget {
  final InstallmentStatus status;
  final bool isDark;

  const _StatusChip({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      InstallmentStatus.paid => ColorTokens.lightSuccess,
      InstallmentStatus.overdue => ColorTokens.lightError,
      InstallmentStatus.pending => isDark
          ? ColorTokens.darkTextSecondary
          : ColorTokens.lightTextSecondary,
    };

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Summary chip for schedule stats.
class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
