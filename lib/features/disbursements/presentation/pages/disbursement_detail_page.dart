// lib/features/disbursements/presentation/pages/disbursement_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/disbursements/domain/entities/disbursement.dart';
import 'package:jireta_loan/features/disbursements/presentation/providers/disbursement_notifier.dart';
import 'package:jireta_loan/features/disbursements/presentation/widgets/assign_rider_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DisbursementDetailPage extends ConsumerStatefulWidget {
  final String disbursementId;

  const DisbursementDetailPage({
    super.key,
    required this.disbursementId,
  });

  @override
  ConsumerState<DisbursementDetailPage> createState() =>
      _DisbursementDetailPageState();
}

class _DisbursementDetailPageState
    extends ConsumerState<DisbursementDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(disbursementFeatureProvider.notifier)
          .loadDisbursementDetail(widget.disbursementId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(disbursementFeatureProvider);
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
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disbursement Detail'),
        actions: [
          if (state is DisbursementDetailLoaded)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                if (state.disbursement.status.isActionable)
                  const PopupMenuItem(
                    value: 'assign',
                    child: Text('Assign Rider'),
                  ),
                if (state.disbursement.status ==
                    DisbursementStatus.assigned)
                  const PopupMenuItem(
                    value: 'in_transit',
                    child: Text('Mark In Transit'),
                  ),
                if (state.disbursement.status ==
                    DisbursementStatus.inTransit)
                  const PopupMenuItem(
                    value: 'delivered',
                    child: Text('Mark Delivered'),
                  ),
                if (!state.disbursement.status.isTerminal)
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
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(disbursementFeatureProvider.notifier)
                  .loadDisbursementDetail(widget.disbursementId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is DisbursementDetailLoaded) {
      final disbursement = state.disbursement;
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
                      color: _statusColor(disbursement.status)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      disbursement.status.iconData,
                      size: 36,
                      color: _statusColor(disbursement.status),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailStatusBadge(
                    status: disbursement.status,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusDescription(disbursement.status),
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
              title: 'Disbursement Info',
              children: [
                _DetailRow(
                  label: 'ID',
                  value:
                      '#${disbursement.id.length > 8 ? disbursement.id.substring(0, 8).toUpperCase() : disbursement.id.toUpperCase()}',
                  isDark: isDark,
                ),
                _DetailRow(
                  label: 'Loan ID',
                  value:
                      '#${disbursement.loanId.length > 8 ? disbursement.loanId.substring(0, 8).toUpperCase() : disbursement.loanId.toUpperCase()}',
                  isDark: isDark,
                ),
                _DetailRow(
                  label: 'Method',
                  value: disbursement.method.label,
                  isDark: isDark,
                  trailing: Icon(
                    disbursement.method.iconData,
                    size: 16,
                    color: _methodColor(disbursement.method),
                  ),
                ),
                _DetailRow(
                  label: 'Created',
                  value: DateFormatter.formatDisplayDateTime(
                      disbursement.createdAt),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _DetailSection(
              title: 'Rider Assignment',
              children: [
                if (disbursement.hasRiderAssigned) ...[
                  _DetailRow(
                    label: 'Rider',
                    value: disbursement.riderName ?? 'Unknown',
                    isDark: isDark,
                    trailing: Icon(
                      LucideIcons.user,
                      size: 16,
                      color: ColorTokens.roleRider,
                    ),
                  ),
                  _DetailRow(
                    label: 'Rider ID',
                    value: disbursement.assignedRiderId ?? '',
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

            if (disbursement.isDelivered) ...[
              _DetailSection(
                title: 'Delivery Proof',
                children: [
                  if (disbursement.deliveredAt != null)
                    _DetailRow(
                      label: 'Delivered At',
                      value: DateFormatter.formatDisplayDateTime(
                          disbursement.deliveredAt!),
                      isDark: isDark,
                    ),
                  if (disbursement.hasGpsCoordinates) ...[
                    _DetailRow(
                      label: 'GPS Latitude',
                      value: disbursement.gpsLatitude!
                          .toStringAsFixed(6),
                      isDark: isDark,
                      mono: true,
                    ),
                    _DetailRow(
                      label: 'GPS Longitude',
                      value: disbursement.gpsLongitude!
                          .toStringAsFixed(6),
                      isDark: isDark,
                      mono: true,
                    ),
                  ],
                  if (disbursement.receiptUrl != null)
                    _DetailRow(
                      label: 'Receipt',
                      value: 'View Receipt',
                      isDark: isDark,
                      valueColor: ColorTokens.accent,
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (disbursement.xenditDisbursementId != null) ...[
              _DetailSection(
                title: 'Xendit Reference',
                children: [
                  _DetailRow(
                    label: 'Disbursement ID',
                    value: disbursement.xenditDisbursementId!,
                    isDark: isDark,
                    mono: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (disbursement.status.isActionable) ...[
              if (disbursement.status ==
                  DisbursementStatus.pending) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showAssignRiderDialog(disbursement.id),
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
              if (disbursement.status ==
                  DisbursementStatus.assigned) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(disbursementFeatureProvider.notifier)
                        .markInTransit(disbursement.id),
                    icon: const Icon(LucideIcons.truck),
                    label: const Text('Mark In Transit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorTokens.lightInfo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              if (disbursement.status ==
                  DisbursementStatus.inTransit) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _markDelivered,
                    icon: const Icon(LucideIcons.circleCheck),
                    label: const Text('Mark Delivered'),
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
                    icon: const Icon(LucideIcons.circleAlert),
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
    final state = ref.read(disbursementFeatureProvider);
    if (state is! DisbursementDetailLoaded) return;

    final id = state.disbursement.id;

    switch (action) {
      case 'assign':
        _showAssignRiderDialog(id);
        break;
      case 'in_transit':
        ref
            .read(disbursementFeatureProvider.notifier)
            .markInTransit(id);
        break;
      case 'delivered':
        _markDelivered();
        break;
      case 'failed':
        _markFailed();
        break;
    }
  }

  void _showAssignRiderDialog(String disbursementId) {
    showDialog(
      context: context,
      builder: (context) => AssignRiderDialog(
        disbursementId: disbursementId,
      ),
    );
  }

  void _markDelivered() {
    ref.read(disbursementFeatureProvider.notifier).markDelivered(
          disbursementId: widget.disbursementId,
          latitude: 14.5547,
          longitude: 121.0244,
        );
  }

  void _markFailed() {
    ref.read(disbursementFeatureProvider.notifier).markFailed(
          widget.disbursementId,
          reason: 'Unable to deliver to lender.',
        );
  }

  Color _statusColor(DisbursementStatus status) => switch (status) {
        DisbursementStatus.pending => ColorTokens.lightWarning,
        DisbursementStatus.assigned => ColorTokens.lightInfo,
        DisbursementStatus.inTransit => Color(0xFF7C4DFF),
        DisbursementStatus.delivered => ColorTokens.lightSuccess,
        DisbursementStatus.failed => ColorTokens.lightError,
      };

  String _statusDescription(DisbursementStatus status) => switch (status) {
        DisbursementStatus.pending =>
          'Waiting for a rider to be assigned.',
        DisbursementStatus.assigned =>
          'Rider assigned. Waiting to start delivery.',
        DisbursementStatus.inTransit =>
          'Rider is en route to deliver funds.',
        DisbursementStatus.delivered =>
          'Funds have been successfully delivered.',
        DisbursementStatus.failed =>
          'Delivery was unsuccessful.',
      };

  Color _methodColor(DisbursementMethod method) => switch (method) {
        DisbursementMethod.gcash => const Color(0xFF007BFF),
        DisbursementMethod.office => ColorTokens.secondaryAccent,
        DisbursementMethod.cash => ColorTokens.lightSuccess,
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

class _DetailStatusBadge extends StatelessWidget {
  final DisbursementStatus status;

  const _DetailStatusBadge({required this.status});

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
        DisbursementStatus.pending => ColorTokens.lightWarning,
        DisbursementStatus.assigned => ColorTokens.lightInfo,
        DisbursementStatus.inTransit => Color(0xFF7C4DFF),
        DisbursementStatus.delivered => ColorTokens.lightSuccess,
        DisbursementStatus.failed => ColorTokens.lightError,
      };
}
