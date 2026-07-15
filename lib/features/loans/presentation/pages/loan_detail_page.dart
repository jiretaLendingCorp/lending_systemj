// lib/features/loans/presentation/pages/loan_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:jireta_loan/features/loans/presentation/providers/loan_notifier.dart';
import 'package:jireta_loan/features/loans/presentation/widgets/loan_schedule_table.dart';
import 'package:jireta_loan/features/loans/presentation/widgets/loan_status_badge.dart';
import 'package:jireta_loan/features/loans/presentation/widgets/loan_status_timeline.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoanDetailPage extends ConsumerStatefulWidget {
  final String loanId;

  const LoanDetailPage({
    super.key,
    required this.loanId,
  });

  @override
  ConsumerState<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends ConsumerState<LoanDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loanFeatureProvider.notifier).loadLoanDetail(widget.loanId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rejectReasonController.dispose();
    super.dispose();
  }

  void _handleApprove() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Loan'),
        content: const Text(
          'Are you sure you want to approve this loan? The lender will be notified and the loan will proceed to disbursement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(loanFeatureProvider.notifier).approveLoan(widget.loanId);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _handleReject() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Loan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejecting this loan. The lender will be notified.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectReasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectReasonController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorTokens.lightError,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(loanFeatureProvider.notifier).rejectLoan(
                    widget.loanId,
                    reason: _rejectReasonController.text.trim().isNotEmpty
                        ? _rejectReasonController.text.trim()
                        : null,
                  );
              _rejectReasonController.clear();
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loanState = ref.watch(loanFeatureProvider);
    final canApprove = ref.watch(canApproveLoansProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<LoanFeatureState>(loanFeatureProvider, (prev, next) {
      if (next is LoanError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: ColorTokens.lightError,
          ),
        );
      } else if (next is LoanOperationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: ColorTokens.lightSuccess,
          ),
        );
        ref.read(loanFeatureProvider.notifier).loadLoanDetail(widget.loanId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Details'),
        bottom: loanState is LoanDetailLoaded
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Schedule'),
                  Tab(text: 'Timeline'),
                ],
              )
            : null,
      ),
      body: _buildBody(loanState, isDark, canApprove),
    );
  }

  Widget _buildBody(
    LoanFeatureState state,
    bool isDark,
    bool canApprove,
  ) {
    if (state is LoansLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is LoanError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: ColorTokens.lightError,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(loanFeatureProvider.notifier)
                  .loadLoanDetail(widget.loanId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is LoanDetailLoaded) {
      final loan = state.loan;
      final schedule = state.schedule;

      return Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  loan: loan,
                  isDark: isDark,
                ),

                SingleChildScrollView(
                  child: LoanScheduleTable(schedule: schedule),
                ),

                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: LoanStatusTimeline(
                    loan: loan,
                    direction: Axis.vertical,
                  ),
                ),
              ],
            ),
          ),

          if (canApprove && loan.status.isApprovable)
            _buildActionButtons(isDark),
        ],
      );
    }

    return const Center(child: Text('No loan data'));
  }

  Widget _buildActionButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkSurface : ColorTokens.lightCanvas,
        border: Border(
          top: BorderSide(
            color: isDark ? ColorTokens.darkBorder : ColorTokens.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorTokens.lightError,
                side: const BorderSide(color: ColorTokens.lightError),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleApprove,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Approve'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Loan loan;
  final bool isDark;

  const _OverviewTab({required this.loan, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Loan #${loan.id.substring(0, 8).toUpperCase()}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              LoanStatusBadge(status: loan.status, showIcon: true),
            ],
          ),
          const SizedBox(height: 24),

          _SectionCard(
            title: 'Loan Details',
            isDark: isDark,
            children: [
              _DetailRow(
                label: 'Principal',
                value: CurrencyFormatter.formatPhp(loan.principal),
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Interest Rate',
                value: CurrencyFormatter.formatPercentage(loan.interestRate),
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Interest Amount',
                value: CurrencyFormatter.formatPhp(loan.interestAmount),
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Total Payable',
                value: CurrencyFormatter.formatPhp(loan.totalPayable),
                isDark: isDark,
                valueColor: ColorTokens.accent,
                isBold: true,
              ),
              _DetailRow(
                label: 'Term',
                value: '${loan.termDays} days',
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Schedule',
                value: loan.scheduleType.label,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (loan.status.isActive) ...[
            _SectionCard(
              title: 'Payment Progress',
              isDark: isDark,
              children: [
                _DetailRow(
                  label: 'Outstanding Balance',
                  value: CurrencyFormatter.formatPhp(loan.outstandingBalance),
                  isDark: isDark,
                  valueColor: loan.status == LoanStatus.defaulted
                      ? ColorTokens.lightError
                      : null,
                ),
                if (loan.penaltyAmount > 0)
                  _DetailRow(
                    label: 'Penalty Amount',
                    value: CurrencyFormatter.formatPhp(loan.penaltyAmount),
                    isDark: isDark,
                    valueColor: ColorTokens.lightError,
                  ),
                _DetailRow(
                  label: 'Amount Paid',
                  value: CurrencyFormatter.formatPhp(loan.amountPaid),
                  isDark: isDark,
                  valueColor: ColorTokens.lightSuccess,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: loan.repaymentProgress,
                    backgroundColor: isDark
                        ? ColorTokens.darkBorder
                        : ColorTokens.lightBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      loan.status == LoanStatus.defaulted
                          ? ColorTokens.lightError
                          : ColorTokens.accent,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(loan.repaymentProgress * 100).toStringAsFixed(1)}% complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? ColorTokens.darkTextSecondary
                            : ColorTokens.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          _SectionCard(
            title: 'Key Dates',
            isDark: isDark,
            children: [
              _DetailRow(
                label: 'Application Date',
                value: DateFormatter.formatDisplayDateTime(loan.createdAt),
                isDark: isDark,
              ),
              if (loan.approvedAt != null)
                _DetailRow(
                  label: 'Approved Date',
                  value: DateFormatter.formatDisplayDateTime(loan.approvedAt!),
                  isDark: isDark,
                ),
              if (loan.disbursedAt != null)
                _DetailRow(
                  label: 'Disbursed Date',
                  value: DateFormatter.formatDisplayDateTime(loan.disbursedAt!),
                  isDark: isDark,
                ),
              if (loan.dueAt != null)
                _DetailRow(
                  label: 'Due Date',
                  value: DateFormatter.formatDueDate(loan.dueAt!),
                  isDark: isDark,
                  valueColor: loan.status == LoanStatus.defaulted
                      ? ColorTokens.lightError
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ??
                    (isDark ? ColorTokens.darkText : ColorTokens.lightText),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
