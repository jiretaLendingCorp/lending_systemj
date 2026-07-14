// lib/features/dashboard/presentation/pages/admin_dashboard_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:jireta_loan/features/dashboard/presentation/providers/dashboard_notifier.dart';
import 'package:jireta_loan/features/dashboard/presentation/widgets/kpi_card.dart';
import 'package:jireta_loan/shared/widgets/empty_state.dart';
import 'package:jireta_loan/shared/widgets/error_banner.dart';
import 'package:jireta_loan/shared/widgets/loading_overlay.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardFeatureProvider.notifier).loadAdminStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardFeatureProvider);

    return Stack(
      children: [
        RefreshIndicator(
          color: ColorTokens.accent,
          onRefresh: () =>
              ref.read(dashboardFeatureProvider.notifier).loadAdminStats(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Head Employee Dashboard',
                          style: TextStyles.headlineSmall(context).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormatter.formatDisplayDate(DateTime.now()),
                          style: TextStyles.bodySmall(context),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _QuickActionButton(
                          label: 'Create Loan',
                          icon: Icons.add_rounded,
                          onPressed: () => context.go('/head-employee/loans'),
                        ),
                        const SizedBox(width: 8),
                        _QuickActionButton(
                          label: 'Approve Loans',
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: () => context.go('/head-employee/loans'),
                          color: ColorTokens.lightSuccess,
                        ),
                        const SizedBox(width: 8),
                        _QuickActionButton(
                          label: 'View Reports',
                          icon: Icons.assessment_outlined,
                          onPressed: () => context.go('/head-employee/reports'),
                          color: ColorTokens.secondaryAccent,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (dashboardState is DashboardLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                if (dashboardState is DashboardError)
                  ErrorBanner(
                    message: dashboardState.message,
                    onRetry: () => ref
                        .read(dashboardFeatureProvider.notifier)
                        .loadAdminStats(),
                  ),

                if (dashboardState is DashboardLoaded) ...[
                  _buildKpiRow(dashboardState.stats),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _MonthlyBarChart(
                          stats: dashboardState.stats,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _LoanStatusPieChart(
                          stats: dashboardState.stats,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _RecentActivityList(
                    activities: dashboardState.recentActivity,
                  ),
                ],
              ],
            ),
          ),
        ),

        if (dashboardState is DashboardLoading)
          const LoadingOverlay(isLoading: false),
      ],
    );
  }

  Widget _buildKpiRow(DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = 200.0;
        final spacing = 16.0;
        final cardsPerRow =
            ((constraints.maxWidth + spacing) / (cardWidth + spacing)).floor();
        final effectivePerRow = cardsPerRow.clamp(2, 6);

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: (constraints.maxWidth - (effectivePerRow - 1) * 16) /
                  effectivePerRow,
              child: KpiCard(
                title: 'Total Loans',
                value: '${stats.totalLoans}',
                icon: Icons.account_balance_rounded,
                iconColor: ColorTokens.accent,
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - (effectivePerRow - 1) * 16) /
                  effectivePerRow,
              child: KpiCard(
                title: 'Active Loans',
                value: '${stats.activeLoans}',
                icon: Icons.trending_up_rounded,
                iconColor: ColorTokens.lightInfo,
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - (effectivePerRow - 1) * 16) /
                  effectivePerRow,
              child: KpiCard(
                title: 'Total Disbursed',
                value: CurrencyFormatter.formatPhpCompact(stats.totalDisbursed),
                icon: Icons.payments_rounded,
                iconColor: ColorTokens.lightSuccess,
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - (effectivePerRow - 1) * 16) /
                  effectivePerRow,
              child: KpiCard(
                title: 'Overdue Count',
                value: '${stats.overdueCount}',
                icon: Icons.warning_amber_rounded,
                iconColor: ColorTokens.lightError,
                trend: stats.overdueCount > 0 ? '${stats.overdueRate.toStringAsFixed(1)}%' : null,
                trendUp: false,
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - (effectivePerRow - 1) * 16) /
                  effectivePerRow,
              child: KpiCard(
                title: 'Pending Approvals',
                value: '${stats.pendingApprovals}',
                icon: Icons.hourglass_top_rounded,
                iconColor: ColorTokens.lightWarning,
                onTap: () => context.go('/head-employee/loans'),
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - (effectivePerRow - 1) * 16) /
                  effectivePerRow,
              child: KpiCard(
                title: "Today's Collections",
                value: CurrencyFormatter.formatPhpCompact(stats.todayCollections),
                icon: Icons.today_rounded,
                iconColor: ColorTokens.secondaryAccent,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = ColorTokens.accent,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final DashboardStats stats;

  const _MonthlyBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : ColorTokens.darkSurface;
    final borderColor = isLight ? ColorTokens.lightBorder : ColorTokens.darkBorder;

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final disbursements = [450000, 380000, 520000, 470000, 610000, 550000];
    final collections = [320000, 350000, 410000, 430000, 490000, 520000];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Disbursements vs Collections',
            style: TextStyles.titleSmall(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: ColorTokens.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text('Disbursements', style: TextStyles.bodySmall(context)),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: ColorTokens.secondaryAccent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text('Collections', style: TextStyles.bodySmall(context)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 700000,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final value = rod.toY;
                      return BarTooltipItem(
                        CurrencyFormatter.formatPhpCompact(value),
                        TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              months[index],
                              style: TextStyle(
                                color: isLight
                                    ? ColorTokens.lightTextSecondary
                                    : ColorTokens.darkTextSecondary,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          CurrencyFormatter.formatPhpCompact(value),
                          style: TextStyle(
                            color: isLight
                                ? ColorTokens.lightTextSecondary
                                : ColorTokens.darkTextSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100000,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isLight
                        ? ColorTokens.lightBorder.withValues(alpha: 0.5)
                        : ColorTokens.darkBorder.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(months.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: disbursements[i].toDouble(),
                        color: ColorTokens.accent,
                        width: 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: collections[i].toDouble(),
                        color: ColorTokens.secondaryAccent,
                        width: 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanStatusPieChart extends StatelessWidget {
  final DashboardStats stats;

  const _LoanStatusPieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : ColorTokens.darkSurface;
    final borderColor = isLight ? ColorTokens.lightBorder : ColorTokens.darkBorder;

    final activeCount = stats.activeLoans;
    final overdueCount = stats.overdueCount;
    final paidCount = stats.totalLoans - stats.activeLoans - stats.overdueCount;
    final totalCount = stats.totalLoans > 0 ? stats.totalLoans : 1;

    final sections = [
      PieChartSectionData(
        value: activeCount.toDouble(),
        color: ColorTokens.loanActive,
        title: '${((activeCount / totalCount) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      PieChartSectionData(
        value: overdueCount.toDouble(),
        color: ColorTokens.loanOverdue,
        title: '${((overdueCount / totalCount) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      PieChartSectionData(
        value: paidCount.toDouble().clamp(0, double.infinity),
        color: ColorTokens.loanPaid,
        title: '${((paidCount / totalCount) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loan Status Distribution',
            style: TextStyles.titleSmall(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _ChartLegend(
                color: ColorTokens.loanActive,
                label: 'Active ($activeCount)',
                isLight: isLight,
              ),
              _ChartLegend(
                color: ColorTokens.loanOverdue,
                label: 'Overdue ($overdueCount)',
                isLight: isLight,
              ),
              _ChartLegend(
                color: ColorTokens.loanPaid,
                label: 'Paid ($paidCount)',
                isLight: isLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLight;

  const _ChartLegend({
    required this.color,
    required this.label,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isLight
                ? ColorTokens.lightTextSecondary
                : ColorTokens.darkTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final List<RecentActivity> activities;

  const _RecentActivityList({required this.activities});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : ColorTokens.darkSurface;
    final borderColor = isLight ? ColorTokens.lightBorder : ColorTokens.darkBorder;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyles.titleSmall(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/head-employee/audit'),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: ColorTokens.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (activities.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'No recent activity',
              subtitle: 'Activity will appear here as actions are performed',
              iconSize: 40,
            )
          else
            ...activities.take(10).map((activity) => _ActivityTile(
                  activity: activity,
                  isLight: isLight,
                )),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final RecentActivity activity;
  final bool isLight;

  const _ActivityTile({
    required this.activity,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _activityColor(activity.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _activityIcon(activity.type),
              size: 18,
              color: _activityColor(activity.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: TextStyles.bodyMedium(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatRelative(activity.createdAt),
                  style: TextStyles.bodySmall(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _activityIcon(String type) {
    return switch (type) {
      'loan_created' => Icons.add_circle_outline_rounded,
      'loan_approved' => Icons.check_circle_outline_rounded,
      'loan_rejected' => Icons.cancel_outlined,
      'payment_received' => Icons.payments_outlined,
      'disbursement' => Icons.send_outlined,
      'collection' => Icons.savings_outlined,
      'user_created' => Icons.person_add_outlined,
      _ => Icons.info_outline_rounded,
    };
  }

  Color _activityColor(String type) {
    return switch (type) {
      'loan_created' => ColorTokens.accent,
      'loan_approved' => ColorTokens.lightSuccess,
      'loan_rejected' => ColorTokens.lightError,
      'payment_received' => ColorTokens.lightSuccess,
      'disbursement' => ColorTokens.lightInfo,
      'collection' => ColorTokens.secondaryAccent,
      'user_created' => ColorTokens.roleHeadManager,
      _ => ColorTokens.lightDisabled,
    };
  }
}
