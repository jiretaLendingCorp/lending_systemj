import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/theme/text_styles.dart';
import 'package:lendflow/core/utils/currency_formatter.dart';
import 'package:lendflow/features/reports/domain/entities/report_data.dart';
import 'package:lendflow/features/reports/presentation/providers/report_notifier.dart';
import 'package:lendflow/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:lendflow/shared/widgets/error_banner.dart';
import 'package:lendflow/shared/widgets/loading_overlay.dart';

/// Web: Collection efficiency report page.
///
/// Displays collection efficiency metrics including success rate,
/// collection amounts, and average collection time.
class CollectionEfficiencyPage extends ConsumerStatefulWidget {
  const CollectionEfficiencyPage({super.key});

  @override
  ConsumerState<CollectionEfficiencyPage> createState() =>
      _CollectionEfficiencyPageState();
}

class _CollectionEfficiencyPageState
    extends ConsumerState<CollectionEfficiencyPage> {
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportFeatureProvider.notifier).loadCollectionEfficiency();
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
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Collection Efficiency Report',
                              style: TextStyles.headlineSmall(context)),
                          const SizedBox(height: 4),
                          Text(
                            'Metrics tracking payment collection effectiveness.',
                            style: TextStyles.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.date_range_outlined, size: 18),
                      label: Text(
                        _dateRange != null
                            ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                            : 'Select Date Range',
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _exportReport(),
                      icon: const Icon(Icons.download_outlined, size: 18),
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
                if (state is CollectionEfficiencyLoaded) ...[
                  _buildKpiCards(state.report),
                  const SizedBox(height: 24),
                  _buildEfficiencyDetails(state.report, theme),
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

  Widget _buildKpiCards(CollectionEfficiencyReport report) {
    return Row(
      children: [
        Expanded(
          child: ReportSummaryCard(
            label: 'Efficiency Rate',
            value: '${report.efficiencyRate.toStringAsFixed(1)}%',
            icon: Icons.speed_outlined,
            iconColor: ColorTokens.accent,
            trend: report.efficiencyRate >= 90 ? 'Good' : 'Low',
            trendUp: report.efficiencyRate >= 90,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ReportSummaryCard(
            label: 'Total Collected',
            value: CurrencyFormatter.formatPhp(report.totalCollected),
            icon: Icons.payments_outlined,
            iconColor: ColorTokens.lightSuccess,
            subtitle: 'of ${CurrencyFormatter.formatPhp(report.totalExpected)} expected',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ReportSummaryCard(
            label: 'Success Rate',
            value: '${report.successRate.toStringAsFixed(1)}%',
            icon: Icons.check_circle_outline,
            iconColor: ColorTokens.lightSuccess,
            subtitle: '${report.successfulAttempts} of ${report.totalAttempts} attempts',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ReportSummaryCard(
            label: 'Avg. Collection Time',
            value: '${report.averageCollectionTimeHours.toStringAsFixed(1)}h',
            icon: Icons.schedule_outlined,
            iconColor: ColorTokens.lightInfo,
          ),
        ),
      ],
    );
  }

  Widget _buildEfficiencyDetails(
      CollectionEfficiencyReport report, ThemeData theme) {
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
          Text('Collection Breakdown', style: TextStyles.titleMedium(context)),
          const SizedBox(height: 20),
          // Collected vs Expected progress
          _MetricRow(
            label: 'Total Expected',
            value: CurrencyFormatter.formatPhp(report.totalExpected),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Total Collected',
            value: CurrencyFormatter.formatPhp(report.totalCollected),
            valueColor: ColorTokens.lightSuccess,
          ),
          _MetricRow(
            label: 'Partial Payments',
            value: CurrencyFormatter.formatPhp(report.totalPartial),
            valueColor: ColorTokens.lightWarning,
          ),
          _MetricRow(
            label: 'Failed Collections',
            value: CurrencyFormatter.formatPhp(report.totalFailed),
            valueColor: ColorTokens.lightError,
          ),
          const Divider(height: 32),
          _MetricRow(
            label: 'Total Attempts',
            value: '${report.totalAttempts}',
          ),
          _MetricRow(
            label: 'Successful',
            value: '${report.successfulAttempts}',
            valueColor: ColorTokens.lightSuccess,
          ),
          _MetricRow(
            label: 'Failed',
            value: '${report.failedAttempts}',
            valueColor: ColorTokens.lightError,
          ),
          const SizedBox(height: 16),
          // Efficiency progress bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Collection Progress',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: report.efficiencyRate / 100,
                        minHeight: 12,
                        backgroundColor: ColorTokens.accent.withOpacity(0.15),
                        valueColor:
                            const AlwaysStoppedAnimation(ColorTokens.accent),
                      ),
                    ),
                  ],
                ),
              ),
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
      ref.read(reportFeatureProvider.notifier).loadCollectionEfficiency(
            startDate: range.start,
            endDate: range.end,
          );
    }
  }

  void _exportReport() {
    ref.read(reportFeatureProvider.notifier).exportReport(
          reportType: 'collection_efficiency',
          format: 'csv',
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
        );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
