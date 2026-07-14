// lib/features/riders/presentation/pages/rider_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/riders/domain/entities/rider_task.dart';
import 'package:jireta_loan/features/riders/presentation/providers/rider_notifier.dart';

class RiderHistoryPage extends ConsumerStatefulWidget {
  const RiderHistoryPage({super.key});

  @override
  ConsumerState<RiderHistoryPage> createState() => _RiderHistoryPageState();
}

class _RiderHistoryPageState extends ConsumerState<RiderHistoryPage> {
  DateTimeRange? _selectedDateRange;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory({int page = 1}) {
    _currentPage = page;
    ref.read(riderFeatureProvider.notifier).loadHistory(
          startDate: _selectedDateRange?.start,
          endDate: _selectedDateRange?.end,
          page: page,
        );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: ColorTokens.accent,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riderState = ref.watch(riderFeatureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDateRange,
            tooltip: 'Filter by date',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadHistory(),
        child: CustomScrollView(
          slivers: [
            if (_selectedDateRange != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Chip(
                        avatar: const Icon(Icons.filter_list, size: 16),
                        label: Text(
                          '${DateFormatter.formatDisplayDate(_selectedDateRange!.start)} '
                          '– ${DateFormatter.formatDisplayDate(_selectedDateRange!.end)}',
                          style: theme.textTheme.labelSmall,
                        ),
                        onDeleted: () {
                          setState(() => _selectedDateRange = null);
                          _loadHistory();
                        },
                      ),
                    ],
                  ),
                ),
              ),

            if (riderState is RiderLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (riderState is RiderError)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(riderState.message,
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => _loadHistory(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (riderState is RiderHistoryLoaded)
              riderState.tasks.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history,
                                size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No completed tasks yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your completed and failed tasks will appear here',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == riderState.tasks.length) {
                              if (riderState.hasMore) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: OutlinedButton(
                                      onPressed: () => _loadHistory(
                                          page: _currentPage + 1),
                                      child: const Text('Load More'),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            final task = riderState.tasks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HistoryTaskCard(task: task),
                            );
                          },
                          childCount: riderState.tasks.length + 1,
                        ),
                      ),
                    )
            else
              const SliverFillRemaining(
                child: Center(child: Text('Loading history...')),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTaskCard extends StatelessWidget {
  final RiderTask task;

  const _HistoryTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  task.isDisbursement
                      ? Icons.outbox_outlined
                      : Icons.inbox_outlined,
                  size: 20,
                  color: task.isDisbursement
                      ? ColorTokens.accent
                      : ColorTokens.secondaryAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  task.type.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: task.isDisbursement
                        ? ColorTokens.accent
                        : ColorTokens.secondaryAccent,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (task.status == RiderTaskStatus.completed
                            ? ColorTokens.lightSuccess
                            : ColorTokens.lightError)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.status.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: task.status == RiderTaskStatus.completed
                          ? ColorTokens.lightSuccess
                          : ColorTokens.lightError,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.lenderName,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.lenderAddress,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.formatPhp(task.amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (task.completedAt != null)
                  Text(
                    DateFormatter.formatDisplayDate(task.completedAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
