// lib/features/collections/presentation/pages/collection_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/features/collections/domain/entities/collection.dart';
import 'package:jireta_loan/features/collections/domain/repositories/collection_repository.dart';
import 'package:jireta_loan/features/collections/presentation/providers/collection_notifier.dart';
import 'package:jireta_loan/features/collections/presentation/widgets/collection_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CollectionListPage extends ConsumerStatefulWidget {
  const CollectionListPage({super.key});

  @override
  ConsumerState<CollectionListPage> createState() =>
      _CollectionListPageState();
}

class _CollectionListPageState
    extends ConsumerState<CollectionListPage> {
  String? _activeStatusFilter;
  String? _activeMethodFilter;

  static const _statusFilters = [
    (label: 'All', value: null),
    (label: 'Pending', value: 'pending'),
    (label: 'Assigned', value: 'assigned'),
    (label: 'In Transit', value: 'in_transit'),
    (label: 'Collected', value: 'collected'),
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
      _loadCollections();
    });
  }

  void _loadCollections({int page = 1}) {
    ref.read(collectionFeatureProvider.notifier).loadCollections(
          status: _activeStatusFilter,
          method: _activeMethodFilter,
          page: page,
        );
  }

  void _applyStatusFilter(String? status) {
    setState(() => _activeStatusFilter = status);
    _loadCollections();
  }

  void _applyMethodFilter(String? method) {
    setState(() => _activeMethodFilter = method);
    _loadCollections();
  }

  @override
  Widget build(BuildContext context) {
    final collectionState = ref.watch(collectionFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<CollectionFeatureState>(
      collectionFeatureProvider,
      (prev, next) {
        if (next is CollectionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: ColorTokens.lightError,
            ),
          );
        }
        if (next is CollectionOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: ColorTokens.lightSuccess,
            ),
          );
          _loadCollections();
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
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

          if (collectionState is CollectionsLoaded)
            _buildSummaryBar(collectionState, isDark),

          Expanded(
            child: _buildBody(collectionState, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(CollectionsLoaded state, bool isDark) {
    final pending = state.collections
        .where((c) => c.status == CollectionStatus.pending)
        .length;
    final inTransit = state.collections
        .where((c) => c.status == CollectionStatus.inTransit)
        .length;
    final collected = state.collections
        .where((c) => c.status == CollectionStatus.collected)
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
            label: 'Collected',
            count: collected,
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

  Widget _buildBody(CollectionFeatureState state, bool isDark) {
    if (state is CollectionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CollectionError) {
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
              onPressed: _loadCollections,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is CollectionsLoaded) {
      if (state.collections.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.banknote,
                size: 64,
                color: isDark
                    ? ColorTokens.darkDisabled
                    : ColorTokens.lightDisabled,
              ),
              const SizedBox(height: 16),
              Text(
                'No collections found',
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
        onRefresh: () async => _loadCollections(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.extentAfter < 200 &&
                state.hasMore) {
              ref
                  .read(collectionFeatureProvider.notifier)
                  .loadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: state.collections.length +
                (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.collections.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final collection = state.collections[index];
              return CollectionCard(
                collection: collection,
                onTap: () => context
                    .push('/collections/${collection.id}'),
                onAssignRider: collection.status.isActionable
                    ? () => _showAssignRiderDialog(collection.id)
                    : null,
              );
            },
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showAssignRiderDialog(String collectionId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => _AssignRiderCollectionDialog(
        collectionId: collectionId,
        isDark: isDark,
      ),
    );
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

class _AssignRiderCollectionDialog extends ConsumerStatefulWidget {
  final String collectionId;
  final bool isDark;

  const _AssignRiderCollectionDialog({
    required this.collectionId,
    required this.isDark,
  });

  @override
  ConsumerState<_AssignRiderCollectionDialog> createState() =>
      _AssignRiderCollectionDialogState();
}

class _AssignRiderCollectionDialogState
    extends ConsumerState<_AssignRiderCollectionDialog> {
  String? _selectedRiderId;
  bool _isLoading = true;
  bool _isAssigning = false;
  List<CollectionRiderInfo> _riders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRiders();
  }

  Future<void> _loadRiders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repository = ref.read(collectionRepositoryProvider);
    final result = await repository.getAvailableRiders();

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (riders) {
        setState(() {
          _isLoading = false;
          _riders = riders;
        });
      },
    );
  }

  Future<void> _assignRider() async {
    if (_selectedRiderId == null) return;

    setState(() => _isAssigning = true);

    await ref.read(collectionFeatureProvider.notifier).assignRider(
          collectionId: widget.collectionId,
          riderId: _selectedRiderId!,
        );

    if (mounted) {
      setState(() => _isAssigning = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            LucideIcons.userPlus,
            color: ColorTokens.accent,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('Assign Rider'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SizedBox(
          width: double.maxFinite,
          child: _buildContent(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isAssigning
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedRiderId != null && !_isAssigning
              ? _assignRider
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorTokens.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                ColorTokens.accent.withValues(alpha: 0.5),
          ),
          child: _isAssigning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 40,
              color: ColorTokens.lightError,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadRiders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_riders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.userX,
              size: 40,
              color: widget.isDark
                  ? ColorTokens.darkDisabled
                  : ColorTokens.lightDisabled,
            ),
            const SizedBox(height: 12),
            const Text('No available riders'),
            const SizedBox(height: 4),
            Text(
              'All riders are currently busy. Try again later.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select a rider for this collection:',
          style: TextStyle(
            fontSize: 13,
            color: widget.isDark
                ? ColorTokens.darkTextSecondary
                : ColorTokens.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _riders.length,
            itemBuilder: (context, index) {
              final rider = _riders[index];
              final isSelected = _selectedRiderId == rider.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () =>
                      setState(() => _selectedRiderId = rider.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorTokens.accent
                              .withValues(alpha: 0.08)
                          : widget.isDark
                              ? ColorTokens.darkSurface
                              : ColorTokens.lightSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? ColorTokens.accent
                            : widget.isDark
                                ? ColorTokens.darkBorder
                                : ColorTokens.lightBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: ColorTokens.roleRider
                              .withValues(alpha: 0.12),
                          child: Text(
                            rider.name.isNotEmpty
                                ? rider.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ColorTokens.roleRider,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                rider.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isSelected
                                      ? ColorTokens.accent
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.truck,
                                    size: 12,
                                    color: widget.isDark
                                        ? ColorTokens
                                            .darkTextSecondary
                                        : ColorTokens
                                            .lightTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${rider.activeCollections} active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.isDark
                                          ? ColorTokens
                                              .darkTextSecondary
                                          : ColorTokens
                                              .lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            LucideIcons.circleCheck,
                            color: ColorTokens.accent,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
