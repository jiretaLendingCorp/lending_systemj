// lib/features/borrowers/presentation/pages/borrower_payments_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/borrowers/presentation/providers/borrower_notifier.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LenderPaymentsPage extends ConsumerStatefulWidget {
  const LenderPaymentsPage({super.key});

  @override
  ConsumerState<LenderPaymentsPage> createState() =>
      _BorrowerPaymentsPageState();
}

class _BorrowerPaymentsPageState extends ConsumerState<LenderPaymentsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(borrowerFeatureProvider.notifier).loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borrowerState = ref.watch(borrowerFeatureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(borrowerFeatureProvider.notifier).loadPayments(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _navigateToMakePayment,
                  icon: const Icon(LucideIcons.creditCard),
                  label: const Text('Make a Payment'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorTokens.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            if (borrowerState is BorrowerLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (borrowerState is BorrowerError)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.circleAlert,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(borrowerState.message,
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref
                            .read(borrowerFeatureProvider.notifier)
                            .loadPayments(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (borrowerState is BorrowerPaymentsLoaded)
              borrowerState.payments.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.receipt,
                                size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No payments yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your payment history will appear here',
                              style: theme.textTheme.bodySmall?.copyWith(
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
                            final payment = borrowerState.payments[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PaymentCard(payment: payment),
                            );
                          },
                          childCount: borrowerState.payments.length,
                        ),
                      ),
                    )
            else
              const SliverFillRemaining(
                child: Center(child: Text('Loading payments...')),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToMakePayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to payment flow')),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Payments'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('All Loans'), leading: Icon(LucideIcons.list)),
            ListTile(
                title: Text('Current Loan'), leading: Icon(LucideIcons.filter)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _paymentStatusColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _paymentStatusIcon,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.formatPhp(payment.amount),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatDisplayDate(payment.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                payment.status.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _paymentStatusColor => switch (payment.status) {
        PaymentStatus.completed => ColorTokens.lightSuccess,
        PaymentStatus.pending => ColorTokens.lightWarning,
        PaymentStatus.failed => ColorTokens.lightError,
        PaymentStatus.refunded => ColorTokens.lightInfo,
      };

  IconData get _paymentStatusIcon => switch (payment.status) {
        PaymentStatus.completed => LucideIcons.circleCheck,
        PaymentStatus.pending => LucideIcons.clock,
        PaymentStatus.failed => LucideIcons.circleAlert,
        PaymentStatus.refunded => LucideIcons.rotateCcw,
      };
}
