// lib/features/collections/presentation/pages/collection_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/collections/domain/entities/collection.dart';
import 'package:jireta_loan/features/collections/presentation/providers/collection_notifier.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CollectionDetailPage extends ConsumerStatefulWidget {
  final String collectionId;

  const CollectionDetailPage({
    super.key,
    required this.collectionId,
  });

  @override
  ConsumerState<CollectionDetailPage> createState() =>
      _CollectionDetailPageState();
}

class _CollectionDetailPageState
    extends ConsumerState<CollectionDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(collectionFeatureProvider.notifier)
          .loadCollectionDetail(widget.collectionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(collectionFeatureProvider);
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
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Detail'),
        actions: [
          if (state is CollectionDetailLoaded)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                if (state.collection.status.isActionable)
                  const PopupMenuItem(
                    value: 'assign',
                    child: Text('Assign Rider'),
                  ),
                if (state.collection.status ==
                    CollectionStatus.inTransit)
                  const PopupMenuItem(
                    value: 'collected',
                    child: Text('Mark Collected'),
                  ),
                if (!state.collection.status.isTerminal)
                  const PopupMenuItem(
                    value: 'failed',
                    child: Text('Mark as Failed'),
                  ),
              ],
            ),
        ],
      ),
      body: _buildBody(state, isDark),
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
              LucideIcons.alertCircle,
              size: 48,
              color: ColorTokens.lightError,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(collectionFeatureProvider.notifier)
                  .loadCollectionDetail(widget.collectionId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is CollectionDetailLoaded) {
      final collection = state.collection;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _statusColor(collection.status)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      collection.status.iconData,
                      size: 36,
                      color: _statusColor(collection.status),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.formatPhp(collection.amount),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ColorTokens.accent,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _CollectionStatusBadge(
                    status: collection.status,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusDescription(collection.status),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? ColorTokens.darkTextSecondary
                              : ColorTokens.lightTextSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _DetailSection(
              title: 'Collection Info',
              children: [
                _DetailRow(
                  label: 'Collection ID',
                  value:
                      '#${collection.id.length > 8 ? collection.id.substring(0, 8).toUpperCase() : collection.id.toUpperCase()}',
                  isDark: isDark,
                ),
                _DetailRow(
                  label: 'Loan ID',
                  value:
                      '#${collection.loanId.length > 8 ? collection.loanId.substring(0, 8).toUpperCase() : collection.loanId.toUpperCase()}',
                  isDark: isDark,
                ),
                _DetailRow(
                  label: 'Lender ID',
                  value:
                      '#${collection.lenderId.length > 8 ? collection.lenderId.substring(0, 8).toUpperCase() : collection.lenderId.toUpperCase()}',
                  isDark: isDark,
                ),
                _DetailRow(
                  label: 'Method',
                  value: collection.method.label,
                  isDark: isDark,
                  trailing: Icon(
                    collection.method.iconData,
                    size: 16,
                    color: _methodColor(collection.method),
                  ),
                ),
                _DetailRow(
                  label: 'Amount',
                  value: CurrencyFormatter.formatPhp(collection.amount),
                  isDark: isDark,
                  valueColor: ColorTokens.accent,
                ),
                _DetailRow(
                  label: 'Created',
                  value: DateFormatter.formatDisplayDateTime(
                      collection.createdAt),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _DetailSection(
              title: 'Rider Assignment',
              children: [
                if (collection.hasRiderAssigned) ...[
                  _DetailRow(
                    label: 'Rider',
                    value: collection.riderName ?? 'Unknown',
                    isDark: isDark,
                    trailing: Icon(
                      LucideIcons.user,
                      size: 16,
                      color: ColorTokens.roleRider,
                    ),
                  ),
                  _DetailRow(
                    label: 'Rider ID',
                    value: collection.assignedRiderId ?? '',
                    isDark: isDark,
                    mono: true,
                  ),
                ] else
                  _DetailRow(
                    label: 'Rider',
                    value: 'Not assigned',
                    isDark: isDark,
                    valueColor: ColorTokens.lightWarning,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (collection.isCollected) ...[
              _DetailSection(
                title: 'Collection Proof',
                children: [
                  if (collection.collectedAt != null)
                    _DetailRow(
                      label: 'Collected At',
                      value: DateFormatter.formatDisplayDateTime(
                          collection.collectedAt!),
                      isDark: isDark,
                    ),
                  if (collection.hasGpsCoordinates) ...[
                    _DetailRow(
                      label: 'GPS Latitude',
                      value: collection.gpsLatitude!
                          .toStringAsFixed(6),
                      isDark: isDark,
                      mono: true,
                    ),
                    _DetailRow(
                      label: 'GPS Longitude',
                      value: collection.gpsLongitude!
                          .toStringAsFixed(6),
                      isDark: isDark,
                      mono: true,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ColorTokens.lightSuccess
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ColorTokens.lightSuccess
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 20,
                            color: ColorTokens.lightSuccess,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GPS Location Verified',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ColorTokens.lightSuccess,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (collection.photoReceiptUrl != null) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Photo Receipt',
                      value: 'View Photo',
                      isDark: isDark,
                      valueColor: ColorTokens.accent,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (collection.status.isActionable ||
                collection.status == CollectionStatus.inTransit) ...[
              if (collection.status ==
                  CollectionStatus.pending) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAssignRiderSheet(
                        collection.id),
                    icon: const Icon(LucideIcons.userPlus),
                    label: const Text('Assign Rider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorTokens.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              if (collection.status ==
                  CollectionStatus.inTransit) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _markCollected,
                    icon:
                        const Icon(LucideIcons.checkCircle),
                    label: const Text('Mark Collected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorTokens.lightSuccess,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _markFailed(),
                    icon: const Icon(LucideIcons.alertCircle),
                    label: const Text('Mark as Failed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.lightError,
                      side: const BorderSide(
                          color: ColorTokens.lightError),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'assign':
        final state = ref.read(collectionFeatureProvider);
        if (state is CollectionDetailLoaded) {
          _showAssignRiderSheet(state.collection.id);
        }
        break;
      case 'collected':
        _markCollected();
        break;
      case 'failed':
        _markFailed();
        break;
    }
  }

  void _showAssignRiderSheet(String collectionId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening rider assignment...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _markCollected() {
    ref.read(collectionFeatureProvider.notifier).markCollected(
          collectionId: widget.collectionId,
          latitude: 14.6760,
          longitude: 121.0437,
        );
  }

  void _markFailed() {
    ref.read(collectionFeatureProvider.notifier).markFailed(
          widget.collectionId,
          reason: 'Unable to collect from lender.',
        );
  }

  Color _statusColor(CollectionStatus status) => switch (status) {
        CollectionStatus.pending => ColorTokens.lightWarning,
        CollectionStatus.assigned => ColorTokens.lightInfo,
        CollectionStatus.inTransit => const Color(0xFF7C4DFF),
        CollectionStatus.collected => ColorTokens.lightSuccess,
        CollectionStatus.failed => ColorTokens.lightError,
      };

  String _statusDescription(CollectionStatus status) =>
      switch (status) {
        CollectionStatus.pending =>
          'Waiting for a rider to be assigned.',
        CollectionStatus.assigned =>
          'Rider assigned. Waiting to start collection.',
        CollectionStatus.inTransit =>
          'Rider is en route to collect payment.',
        CollectionStatus.collected =>
          'Payment has been successfully collected.',
        CollectionStatus.failed =>
          'Collection was unsuccessful.',
      };

  Color _methodColor(CollectionMethod method) => switch (method) {
        CollectionMethod.gcash => const Color(0xFF007BFF),
        CollectionMethod.office => ColorTokens.secondaryAccent,
        CollectionMethod.cash => ColorTokens.lightSuccess,
      };
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? ColorTokens.darkSurface : ColorTokens.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? ColorTokens.darkBorder : ColorTokens.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.accent,
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
  final Widget? trailing;
  final bool mono;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
    this.trailing,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ??
                      (isDark
                          ? ColorTokens.darkText
                          : ColorTokens.lightText),
                  fontFamily: mono ? 'monospace' : null,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionStatusBadge extends StatelessWidget {
  final CollectionStatus status;

  const _CollectionStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColor;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.iconData, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor => switch (status) {
        CollectionStatus.pending => ColorTokens.lightWarning,
        CollectionStatus.assigned => ColorTokens.lightInfo,
        CollectionStatus.inTransit => const Color(0xFF7C4DFF),
        CollectionStatus.collected => ColorTokens.lightSuccess,
        CollectionStatus.failed => ColorTokens.lightError,
      };
}
