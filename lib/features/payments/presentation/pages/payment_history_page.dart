// lib/features/payments/presentation/pages/payment_history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';
import 'package:jireta_loan/features/payments/presentation/providers/payment_notifier.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentHistoryPage extends ConsumerStatefulWidget {
  final String? loanId;

  const PaymentHistoryPage({super.key, this.loanId});

  @override
  ConsumerState<PaymentHistoryPage> createState() =>
      _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends ConsumerState<PaymentHistoryPage> {
  String? _activeStatusFilter;
  String? _activeMethodFilter;

  static const _statusFilters = [
    (label: 'All', value: null),
    (label: 'Pending', value: 'pending'),
    (label: 'Completed', value: 'completed'),
    (label: 'Failed', value: 'failed'),
    (label: 'Refunded', value: 'refunded'),
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
      _loadPayments();
    });
  }

  void _loadPayments({int page = 1}) {
    ref.read(paymentFeatureProvider.notifier).loadPayments(
          loanId: widget.loanId,
          status: _activeStatusFilter,
          method: _activeMethodFilter,
          page: page,
        );
  }

  void _applyStatusFilter(String? status) {
    setState(() => _activeStatusFilter = status);
    _loadPayments();
  }

  void _applyMethodFilter(String? method) {
    setState(() => _activeMethodFilter = method);
    _loadPayments();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<PaymentFeatureState>(paymentFeatureProvider, (prev, next) {
      if (next is PaymentError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: ColorTokens.lightError,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

          Expanded(
            child: _buildBody(paymentState, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PaymentFeatureState state, bool isDark) {
    if (state is PaymentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is PaymentError) {
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? ColorTokens.darkTextSecondary
                        : ColorTokens.lightTextSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPayments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is PaymentsLoaded) {
      if (state.payments.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.receipt,
                size: 64,
                color: isDark
                    ? ColorTokens.darkDisabled
                    : ColorTokens.lightDisabled,
              ),
              const SizedBox(height: 16),
              Text(
                'No payments found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? ColorTokens.darkTextSecondary
                          : ColorTokens.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try adjusting the filters or make your first payment.',
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
        onRefresh: () async => _loadPayments(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.extentAfter < 200 &&
                state.hasMore) {
              ref.read(paymentFeatureProvider.notifier).loadMore(
                    loanId: widget.loanId,
                  );
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount:
                state.payments.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.payments.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final payment = state.payments[index];
              return _PaymentHistoryCard(
                payment: payment,
                onTap: () =>
                    context.push('/payments/${payment.id}/receipt'),
              );
            },
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onTap;

  const _PaymentHistoryCard({
    required this.payment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        payment.method.iconData,
                        size: 18,
                        color: _methodColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        payment.method.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  _StatusBadge(status: payment.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.formatPhp(payment.amount),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ColorTokens.accent,
                        ),
                  ),
                  Text(
                    DateFormatter.formatDisplayDateTime(payment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? ColorTokens.darkTextSecondary
                              : ColorTokens.lightTextSecondary,
                        ),
                  ),
                ],
              ),
              if (payment.referenceNumber != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Ref: ${payment.referenceNumber}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? ColorTokens.darkTextSecondary
                            : ColorTokens.lightTextSecondary,
                        fontFamily: 'monospace',
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color get _methodColor => switch (payment.method) {
        PaymentMethod.gcash => const Color(0xFF007BFF),
        PaymentMethod.office => ColorTokens.secondaryAccent,
        PaymentMethod.cash => ColorTokens.lightSuccess,
      };
}

class _StatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color get _statusColor => switch (status) {
        PaymentStatus.pending => ColorTokens.lightWarning,
        PaymentStatus.completed => ColorTokens.lightSuccess,
        PaymentStatus.failed => ColorTokens.lightError,
        PaymentStatus.refunded => ColorTokens.lightInfo,
      };
}
