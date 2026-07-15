// lib/features/reports/presentation/pages/portfolio_report_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/features/reports/domain/entities/report_data.dart';
import 'package:jireta_loan/features/reports/presentation/providers/report_notifier.dart';
import 'package:jireta_loan/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:jireta_loan/shared/widgets/error_banner.dart';
import 'package:jireta_loan/shared/widgets/loading_overlay.dart';

class PortfolioReportPage extends ConsumerStatefulWidget {
  const PortfolioReportPage({super.key});

  @override
  ConsumerState<PortfolioReportPage> createState() =>
      _PortfolioReportPageState();
}

class _PortfolioReportPageState extends ConsumerState<PortfolioReportPage> {
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportFeatureProvider.notifier).loadPortfolio();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportFeatureProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Loan Portfolio Report',
                              style: TextStyles.headlineSmall(context)),
                          const SizedBox(height: 4),
                          Text(
                            'Overview of the lending portfolio performance.',
                            style: TextStyles.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(LucideIcons.calendarRange, size: 18),
                      label: Text(
                        _dateRange != null
                            ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                            : 'Select Date Range',
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _exportReport('portfolio'),
                      icon: const Icon(LucideIcons.download, size: 18),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorTokens.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (state is ReportError)
                  ErrorBanner(message: state.message),
                if (state is PortfolioLoaded) ...[
                  _buildKpiCards(state.report),
                  const SizedBox(height: 24),
                  _buildLoanStatusTable(state.report, theme),
                ],
                if (state is ReportLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          if (state is ReportLoading) const LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildKpiCards(PortfolioReport report) {
    return Row(
      children: [
        Expanded(
          child: ReportSummaryCard(
            label: 'Total Disbursed',
            value: CurrencyFormatter.formatPhp(report.totalDisbursed),
            icon: LucideIcons.wallet,
            iconColor: ColorTokens.accent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ReportSummaryCard(
            label: 'Outstanding',
            value: CurrencyFormatter.formatPhp(report.totalOutstanding),
            icon: LucideIcons.clock,
            iconColor: ColorTokens.lightWarning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ReportSummaryCard(
            label: 'Total Collected',
            value: CurrencyFormatter.formatPhp(report.totalCollected),
            icon: LucideIcons.circleCheck,
            iconColor: ColorTokens.lightSuccess,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ReportSummaryCard(
            label: 'Interest Earned',
            value: CurrencyFormatter.formatPhp(report.totalInterestEarned),
            icon: LucideIcons.trendingUp,
            iconColor: ColorTokens.lightInfo,
            subtitle: 'Rate: ${report.collectionRate.toStringAsFixed(1)}% collected',
          ),
        ),
      ],
    );
  }

  Widget _buildLoanStatusTable(PortfolioReport report, ThemeData theme) {
    final borderColor = theme.brightness == Brightness.light
        ? ColorTokens.lightBorder
        : ColorTokens.darkBorder;
    final bgColor = theme.brightness == Brightness.light
        ? Colors.white
        : ColorTokens.darkSurface;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loan Status Breakdown', style: TextStyles.titleMedium(context)),
          const SizedBox(height: 16),
          _StatusRow(
            label: 'Active',
            count: report.activeLoans,
            color: ColorTokens.loanActive,
            total: report.totalLoans,
          ),
          _StatusRow(
            label: 'Paid',
            count: report.paidLoans,
            color: ColorTokens.loanPaid,
            total: report.totalLoans,
          ),
          _StatusRow(
            label: 'Overdue',
            count: report.overdueLoans,
            color: ColorTokens.loanOverdue,
            total: report.totalLoans,
          ),
          _StatusRow(
            label: 'Pending',
            count: report.pendingLoans,
            color: ColorTokens.loanPending,
            total: report.totalLoans,
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Loans', style: TextStyles.labelLarge(context)),
              Text('${report.totalLoans}',
                  style: TextStyles.titleMedium(context)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() => _dateRange = range);
      ref.read(reportFeatureProvider.notifier).loadPortfolio(
            startDate: range.start,
            endDate: range.end,
          );
    }
  }

  void _exportReport(String type) {
    ref.read(reportFeatureProvider.notifier).exportReport(
          reportType: type,
          format: 'csv',
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
        );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final int total;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text('$count', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
