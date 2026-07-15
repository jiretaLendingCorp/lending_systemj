// lib/features/reports/presentation/pages/overdue_report_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:jireta_loan/features/reports/presentation/providers/report_notifier.dart';
import 'package:jireta_loan/features/reports/presentation/widgets/aging_table.dart';
import 'package:jireta_loan/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:jireta_loan/shared/widgets/error_banner.dart';
import 'package:jireta_loan/shared/widgets/loading_overlay.dart';

class OverdueReportPage extends ConsumerStatefulWidget {
  const OverdueReportPage({super.key});

  @override
  ConsumerState<OverdueReportPage> createState() => _OverdueReportPageState();
}

class _OverdueReportPageState extends ConsumerState<OverdueReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportFeatureProvider.notifier).loadOverdue();
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
                          Text('Overdue Report',
                              style: TextStyles.headlineSmall(context)),
                          const SizedBox(height: 4),
                          Text(
                            'Aging analysis of overdue loan payments.',
                            style: TextStyles.bodySmall(context),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _exportReport(),
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
                if (state is OverdueLoaded) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ReportSummaryCard(
                          label: 'Total Overdue',
                          value: CurrencyFormatter.formatPhp(state.report.totalAmount),
                          icon: LucideIcons.alertTriangle,
                          iconColor: ColorTokens.lightError,
                          subtitle: '${state.report.totalOverdue} loans',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ReportSummaryCard(
                          label: '1-7 Days',
                          value: CurrencyFormatter.formatPhp(state.report.amount1to7),
                          icon: LucideIcons.clock,
                          iconColor: ColorTokens.lightWarning,
                          subtitle: '${state.report.days1to7} loans',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ReportSummaryCard(
                          label: '8-30 Days',
                          value: CurrencyFormatter.formatPhp(state.report.amount8to30),
                          icon: LucideIcons.calendarX,
                          iconColor: ColorTokens.secondaryAccent,
                          subtitle: '${state.report.days8to30} loans',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ReportSummaryCard(
                          label: '30+ Days',
                          value: CurrencyFormatter.formatPhp(state.report.amount30Plus),
                          icon: LucideIcons.alertCircle,
                          iconColor: ColorTokens.lightError,
                          subtitle: '${state.report.days30Plus} loans',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AgingTable(report: state.report),
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

  void _exportReport() {
    ref.read(reportFeatureProvider.notifier).exportReport(
          reportType: 'overdue',
          format: 'csv',
        );
  }
}
