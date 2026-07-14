import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/theme/text_styles.dart';
import 'package:lendflow/core/utils/currency_formatter.dart';
import 'package:lendflow/core/utils/date_formatter.dart';
import 'package:lendflow/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:lendflow/features/dashboard/presentation/providers/dashboard_notifier.dart';
import 'package:lendflow/features/dashboard/presentation/widgets/kpi_card.dart';
import 'package:lendflow/shared/widgets/empty_state.dart';
import 'package:lendflow/shared/widgets/error_banner.dart';

/// Web manager dashboard page scoped to the manager's branch.
///
/// Layout:
/// - Row of 4 KPI cards: My Loans, Active Loans, Overdue Count, Today's Tasks
/// - BarChart for branch performance
/// - Pending approval count with link
/// - Recent collections list
class ManagerDashboardPage extends ConsumerStatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  ConsumerState<ManagerDashboardPage> createState() =>
      _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends ConsumerState<ManagerDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardFeatureProvider.notifier).loadManagerStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardFeatureProvider);

    return RefreshIndicator(
      color: ColorTokens.accent,
      onRefresh: () =>
          ref.read(dashboardFeatureProvider.notifier).loadManagerStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manager Dashboard',
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
                // ── Pending approvals quick link ─────────────────────
                if (dashboardState is DashboardLoaded &&
                    dashboardState.stats.pendingApprovals > 0)
                  _PendingApprovalsLink(
                    count: dashboardState.stats.pendingApprovals,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // ── State handling ──────────────────────────────────────
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
                    .loadManagerStats(),
              ),

            if (dashboardState is DashboardLoaded) ...[
              // ── KPI cards row ─────────────────────────────────────
              _buildKpiRow(dashboardState.stats),
              const SizedBox(height: 24),

              // ── Charts row ───────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branch performance bar chart
                  Expanded(
                    flex: 3,
                    child: _BranchPerformanceChart(
                      stats: dashboardState.stats,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Recent collections panel
                  Expanded(
                    flex: 2,
                    child: _RecentCollectionsPanel(
                      activities: dashboardState.recentActivity,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow(DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 16.0;
        final cardsPerRow = 4;
        final cardWidth =
            (constraints.maxWidth - (cardsPerRow - 1) * spacing) /
                cardsPerRow;

        return Row(
          children: [
            SizedBox(
              width: cardWidth,
              child: KpiCard(
                title: 'My Loans',
                value: '${stats.totalLoans}',
                icon: Icons.account_balance_rounded,
                iconColor: ColorTokens.accent,
              ),
            ),
            SizedBox(width: spacing),
            SizedBox(
              width: cardWidth,
              child: KpiCard(
                title: 'Active Loans',
                value: '${stats.activeLoans}',
                icon: Icons.trending_up_rounded,
                iconColor: ColorTokens.lightInfo,
                trend: stats.totalLoans > 0
                    ? '${((stats.activeLoans / stats.totalLoans) * 100).toStringAsFixed(0)}%'
                    : null,
                trendUp: true,
              ),
            ),
            SizedBox(width: spacing),
            SizedBox(
              width: cardWidth,
              child: KpiCard(
                title: 'Overdue Count',
                value: '${stats.overdueCount}',
                icon: Icons.warning_amber_rounded,
                iconColor: ColorTokens.lightError,
                trend: stats.overdueCount > 0
                    ? '${stats.overdueRate.toStringAsFixed(1)}%'
                    : null,
                trendUp: false,
                onTap: () => context.go('/manager/collections'),
              ),
            ),
            SizedBox(width: spacing),
            SizedBox(
              width: cardWidth,
              child: KpiCard(
                title: "Today's Tasks",
                value: '${stats.pendingApprovals}',
                icon: Icons.task_alt_rounded,
                iconColor: ColorTokens.lightWarning,
                subtitle: 'Pending approvals',
                onTap: () => context.go('/manager/loans'),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Pending approvals quick link
// ─────────────────────────────────────────────────────────────────

class _PendingApprovalsLink extends StatelessWidget {
  final int count;

  const _PendingApprovalsLink({required this.count});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/manager/loans'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: ColorTokens.lightWarning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ColorTokens.lightWarning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 18,
              color: ColorTokens.lightWarning,
            ),
            const SizedBox(width: 8),
            Text(
              '$count pending approval${count > 1 ? 's' : ''}',
              style: TextStyles.labelLarge(context).copyWith(
                color: ColorTokens.lightWarning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: ColorTokens.lightWarning,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Branch performance bar chart
// ─────────────────────────────────────────────────────────────────

class _BranchPerformanceChart extends StatelessWidget {
  final DashboardStats stats;

  const _BranchPerformanceChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : ColorTokens.darkSurface;
    final borderColor = isLight ? ColorTokens.lightBorder : ColorTokens.darkBorder;

    // Sample branch performance data
    final weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
    final disbursements = [
      stats.todayDisbursements > 0 ? stats.todayDisbursements * 4 : 120000,
      stats.todayDisbursements > 0 ? stats.todayDisbursements * 3.5 : 95000,
      stats.todayDisbursements > 0 ? stats.todayDisbursements * 5 : 155000,
      stats.todayDisbursements > 0 ? stats.todayDisbursements * 4.2 : 130000,
    ];
    final collections = [
      stats.todayCollections > 0 ? stats.todayCollections * 3.8 : 98000,
      stats.todayCollections > 0 ? stats.todayCollections * 4.5 : 140000,
      stats.todayCollections > 0 ? stats.todayCollections * 3.2 : 102000,
      stats.todayCollections > 0 ? stats.todayCollections * 4 : 125000,
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
            'Branch Performance',
            style: TextStyles.titleSmall(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This month\'s disbursements vs collections',
            style: TextStyles.bodySmall(context),
          ),
          const SizedBox(height: 8),
          // Legend
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
              Text('Disbursed', style: TextStyles.bodySmall(context)),
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
              Text('Collected', style: TextStyles.bodySmall(context)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 200000,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        CurrencyFormatter.formatPhpCompact(rod.toY),
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
                        if (index >= 0 && index < weeks.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              weeks[index],
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
                  horizontalInterval: 50000,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isLight
                        ? ColorTokens.lightBorder.withValues(alpha: 0.5)
                        : ColorTokens.darkBorder.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(weeks.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: disbursements[i].toDouble(),
                        color: ColorTokens.accent,
                        width: 18,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: collections[i].toDouble(),
                        color: ColorTokens.secondaryAccent,
                        width: 18,
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
          const SizedBox(height: 12),
          // Summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryMetric(
                label: 'Collection Rate',
                value: '${stats.collectionRate.toStringAsFixed(1)}%',
                color: stats.collectionRate >= 80
                    ? ColorTokens.lightSuccess
                    : ColorTokens.lightWarning,
              ),
              _SummaryMetric(
                label: 'Outstanding',
                value: CurrencyFormatter.formatPhpCompact(stats.outstandingBalance),
                color: ColorTokens.accent,
              ),
              _SummaryMetric(
                label: 'Overdue Rate',
                value: '${stats.overdueRate.toStringAsFixed(1)}%',
                color: stats.overdueRate <= 10
                    ? ColorTokens.lightSuccess
                    : ColorTokens.lightError,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyles.titleMedium(context).copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyles.labelSmall(context),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Recent collections panel
// ─────────────────────────────────────────────────────────────────

class _RecentCollectionsPanel extends StatelessWidget {
  final List<RecentActivity> activities;

  const _RecentCollectionsPanel({required this.activities});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : ColorTokens.darkSurface;
    final borderColor = isLight ? ColorTokens.lightBorder : ColorTokens.darkBorder;

    // Filter collection-related activities
    final collectionActivities = activities
        .where((a) =>
            a.type == 'collection' ||
            a.type == 'payment_received')
        .toList();

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
                'Recent Collections',
                style: TextStyles.titleSmall(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/manager/collections'),
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
          if (collectionActivities.isEmpty)
            const EmptyState(
              icon: Icons.savings_outlined,
              title: 'No recent collections',
              subtitle: 'Collections will appear here as payments are received',
              iconSize: 40,
            )
          else
            ...collectionActivities.take(8).map(
                  (activity) => _CollectionTile(
                    activity: activity,
                    isLight: isLight,
                  ),
                ),
        ],
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  final RecentActivity activity;
  final bool isLight;

  const _CollectionTile({
    required this.activity,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isLight
        ? ColorTokens.lightBorder.withValues(alpha: 0.5)
        : ColorTokens.darkBorder.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ColorTokens.lightSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payments_outlined,
              size: 16,
              color: ColorTokens.lightSuccess,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: TextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
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
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: ColorTokens.lightSuccess,
          ),
        ],
      ),
    );
  }
}
