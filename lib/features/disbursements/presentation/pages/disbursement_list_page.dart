// lib/features/disbursements/presentation/pages/disbursement_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/features/disbursements/domain/entities/disbursement.dart';
import 'package:jireta_loan/features/disbursements/presentation/providers/disbursement_notifier.dart';
import 'package:jireta_loan/features/disbursements/presentation/widgets/disbursement_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DisbursementListPage extends ConsumerStatefulWidget {
  const DisbursementListPage({super.key});

  @override
  ConsumerState<DisbursementListPage> createState() =>
      _DisbursementListPageState();
}

class _DisbursementListPageState
    extends ConsumerState<DisbursementListPage> {
  String? _activeStatusFilter;
  String? _activeMethodFilter;

  static const _statusFilters = [
    (label: 'All', value: null),
    (label: 'Pending', value: 'pending'),
    (label: 'Assigned', value: 'assigned'),
    (label: 'In Transit', value: 'in_transit'),
    (label: 'Delivered', value: 'delivered'),
    (label: 'Failed', value: 'failed'),
  ];

  static const _methodFilters = [
    (label: 'All Methods', value: null),
    (label: 'GCash', value: 'gcash'),
    (label: 'Office', value: 'office'),
    (label: 'Cash', value: 'cash'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDisbursements();
    });
  }

  void _loadDisbursements({int page = 1}) {
    ref.read(disbursementFeatureProvider.notifier).loadDisbursements(
          status: _activeStatusFilter,
          method: _activeMethodFilter,
          page: page,
        );
  }

  void _applyStatusFilter(String? status) {
    setState(() => _activeStatusFilter = status);
    _loadDisbursements();
  }

  void _applyMethodFilter(String? method) {
    setState(() => _activeMethodFilter = method);
    _loadDisbursements();
  }

  @override
  Widget build(BuildContext context) {
    final disbursementState = ref.watch(disbursementFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<DisbursementFeatureState>(
      disbursementFeatureProvider,
      (prev, next) {
        if (next is DisbursementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: ColorTokens.lightError,
            ),
          );
        }
        if (next is DisbursementOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: ColorTokens.lightSuccess,
            ),
          );
          _loadDisbursements();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disbursements'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = _statusFilters[index];
                final isSelected = _activeStatusFilter == option.value;
                return FilterChip(
                  label: Text(option.label),
                  selected: isSelected,
                  onSelected: (_) => _applyStatusFilter(option.value),
                  backgroundColor: isDark
                      ? ColorTokens.darkSurface
                      : ColorTokens.lightSurface,
                  selectedColor:
                      ColorTokens.accent.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? ColorTokens.accent
                        : isDark
                            ? ColorTokens.darkTextSecondary
                            : ColorTokens.lightTextSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? ColorTokens.accent
                        : isDark
                            ? ColorTokens.darkBorder
                            : ColorTokens.lightBorder,
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),

          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _methodFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = _methodFilters[index];
                final isSelected = _activeMethodFilter == option.value;
                return FilterChip(
                  label: Text(option.label),
                  selected: isSelected,
                  onSelected: (_) => _applyMethodFilter(option.value),
                  backgroundColor: isDark
                      ? ColorTokens.darkSurface
                      : ColorTokens.lightSurface,
                  selectedColor: ColorTokens.secondaryAccent
                      .withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? ColorTokens.secondaryAccent
                        : isDark
                            ? ColorTokens.darkTextSecondary
                            : ColorTokens.lightTextSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? ColorTokens.secondaryAccent
                        : isDark
                            ? ColorTokens.darkBorder
                            : ColorTokens.lightBorder,
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),

          if (disbursementState is DisbursementsLoaded)
            _buildSummaryBar(disbursementState, isDark),

          Expanded(
            child: _buildBody(disbursementState, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(DisbursementsLoaded state, bool isDark) {
    final pending = state.disbursements
        .where((d) => d.status == DisbursementStatus.pending)
        .length;
    final inTransit = state.disbursements
        .where((d) => d.status == DisbursementStatus.inTransit)
        .length;
    final delivered = state.disbursements
        .where((d) => d.status == DisbursementStatus.delivered)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
      child: Row(
        children: [
          _SummaryChip(
            label: 'Pending',
            count: pending,
            color: ColorTokens.lightWarning,
          ),
          const SizedBox(width: 16),
          _SummaryChip(
            label: 'In Transit',
            count: inTransit,
            color: ColorTokens.lightInfo,
          ),
          const SizedBox(width: 16),
          _SummaryChip(
            label: 'Delivered',
            count: delivered,
            color: ColorTokens.lightSuccess,
          ),
          const Spacer(),
          Text(
            'Total: ${state.total}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DisbursementFeatureState state, bool isDark) {
    if (state is DisbursementsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is DisbursementError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 48,
              color: ColorTokens.lightError,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? ColorTokens.darkTextSecondary
                        : ColorTokens.lightTextSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDisbursements,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is DisbursementsLoaded) {
      if (state.disbursements.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.truck,
                size: 64,
                color: isDark
                    ? ColorTokens.darkDisabled
                    : ColorTokens.lightDisabled,
              ),
              const SizedBox(height: 16),
              Text(
                'No disbursements found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? ColorTokens.darkTextSecondary
                          : ColorTokens.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try adjusting the filters.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? ColorTokens.darkDisabled
                          : ColorTokens.lightDisabled,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async => _loadDisbursements(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.extentAfter < 200 &&
                state.hasMore) {
              ref
                  .read(disbursementFeatureProvider.notifier)
                  .loadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: state.disbursements.length +
                (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.disbursements.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final disbursement = state.disbursements[index];
              return DisbursementCard(
                disbursement: disbursement,
                onTap: () => context
                    .push('/disbursements/${disbursement.id}'),
                onAssignRider: disbursement.status.isActionable
                    ? () => _showAssignRiderDialog(disbursement.id)
                    : null,
              );
            },
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showAssignRiderDialog(String disbursementId) {
    context.push('/disbursements/$disbursementId/assign-rider');
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
