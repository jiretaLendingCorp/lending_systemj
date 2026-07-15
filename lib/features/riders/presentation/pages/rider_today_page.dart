// lib/features/riders/presentation/pages/rider_today_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/features/riders/domain/entities/rider_task.dart';
import 'package:jireta_loan/features/riders/presentation/providers/rider_notifier.dart';
import 'package:jireta_loan/features/riders/presentation/widgets/task_card.dart';
import 'package:jireta_loan/features/riders/presentation/widgets/task_stats_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RiderTodayPage extends ConsumerStatefulWidget {
  const RiderTodayPage({super.key});

  @override
  ConsumerState<RiderTodayPage> createState() => _RiderTodayPageState();
}

class _RiderTodayPageState extends ConsumerState<RiderTodayPage> {
  String? _activeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderFeatureProvider.notifier).loadTodayTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riderState = ref.watch(riderFeatureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Tasks"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              ref.read(riderFeatureProvider.notifier).loadTodayTasks(
                    type: _activeFilter,
                  );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(riderFeatureProvider.notifier)
            .loadTodayTasks(type: _activeFilter),
        child: CustomScrollView(
          slivers: [
            if (riderState is RiderTasksLoaded)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TaskStatsCard(
                    total: riderState.tasks.length,
                    completed: riderState.completedCount,
                    pending: riderState.pendingCount,
                    inTransit: riderState.inTransitCount,
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _activeFilter == null,
                      onSelected: (_) {
                        setState(() => _activeFilter = null);
                        ref
                            .read(riderFeatureProvider.notifier)
                            .loadTodayTasks();
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Disbursement'),
                      selected: _activeFilter == 'disbursement',
                      onSelected: (_) {
                        setState(() => _activeFilter = 'disbursement');
                        ref
                            .read(riderFeatureProvider.notifier)
                            .loadTodayTasks(type: 'disbursement');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Collection'),
                      selected: _activeFilter == 'collection',
                      onSelected: (_) {
                        setState(() => _activeFilter = 'collection');
                        ref
                            .read(riderFeatureProvider.notifier)
                            .loadTodayTasks(type: 'collection');
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
                      Icon(LucideIcons.alertCircle,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        riderState.message,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref
                            .read(riderFeatureProvider.notifier)
                            .loadTodayTasks(type: _activeFilter),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (riderState is RiderTasksLoaded)
              riderState.tasks.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.checkCircle,
                                size: 64,
                                color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks for today',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = riderState.tasks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Dismissible(
                                key: ValueKey(task.id),
                                direction: task.status.isActive
                                    ? DismissDirection.endToStart
                                    : DismissDirection.none,
                                confirmDismiss: (direction) =>
                                    _confirmComplete(context, task),
                                onDismissed: (direction) =>
                                    _handleComplete(task),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding:
                                      const EdgeInsets.only(right: 24),
                                  decoration: BoxDecoration(
                                    color: ColorTokens.lightSuccess,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    LucideIcons.checkCircle,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                child: TaskCard(task: task),
                              ),
                            );
                          },
                          childCount: riderState.tasks.length,
                        ),
                      ),
                    )
            else if (riderState is TaskCompleted)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.checkCircle,
                          size: 64, color: ColorTokens.lightSuccess),
                      const SizedBox(height: 16),
                      Text(
                        riderState.message,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref
                            .read(riderFeatureProvider.notifier)
                            .loadTodayTasks(type: _activeFilter),
                        child: const Text('Back to Tasks'),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SliverFillRemaining(
                child: Center(child: Text('Ready to start your day')),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmComplete(
      BuildContext context, RiderTask task) async {
    final action = task.isDisbursement ? 'deliver' : 'collect';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text(
          'Are you sure you want to mark this ${task.type.label.toLowerCase()} '
          'of ${CurrencyFormatter.formatPhp(task.amount)} for '
          '${task.lenderName} as ${task.isDisbursement ? "delivered" : "collected"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _handleComplete(RiderTask task) {
    if (task.isDisbursement) {
      ref.read(riderFeatureProvider.notifier).markDelivered(
            taskId: task.id,
            latitude: task.gpsLatitude,
            longitude: task.gpsLongitude,
          );
    } else {
      ref.read(riderFeatureProvider.notifier).markCollected(
            taskId: task.id,
            amount: task.amount,
            latitude: task.gpsLatitude,
            longitude: task.gpsLongitude,
          );
    }
  }
}
