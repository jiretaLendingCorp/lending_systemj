// lib/features/payments/presentation/pages/payment_receipt_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';
import 'package:jireta_loan/features/payments/presentation/providers/payment_notifier.dart';

class PaymentReceiptPage extends ConsumerStatefulWidget {
  final String paymentId;

  const PaymentReceiptPage({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentReceiptPage> createState() =>
      _PaymentReceiptPageState();
}

class _PaymentReceiptPageState extends ConsumerState<PaymentReceiptPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(paymentFeatureProvider.notifier)
          .loadPaymentDetail(widget.paymentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentFeatureProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        actions: [
          if (paymentState is PaymentDetailLoaded &&
              paymentState.payment.receiptUrl != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download Receipt',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Downloading receipt...')),
                );
              },
            ),
        ],
      ),
      body: _buildBody(paymentState, isDark),
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
              Icons.error_outline_rounded,
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
              onPressed: () => ref
                  .read(paymentFeatureProvider.notifier)
                  .loadPaymentDetail(widget.paymentId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is PaymentDetailLoaded) {
      final payment = state.payment;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _statusColor(payment.status)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(payment.status),
                      size: 32,
                      color: _statusColor(payment.status),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.formatPhp(payment.amount),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ColorTokens.accent,
                        ),
                  ),
                  const SizedBox(height: 4),
                  _ReceiptStatusBadge(status: payment.status),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _ReceiptSection(
              title: 'Payment Details',
              children: [
                _ReceiptRow(
                  label: 'Payment ID',
                  value:
                      '#${payment.id.length > 8 ? payment.id.substring(0, 8).toUpperCase() : payment.id.toUpperCase()}',
                  isDark: isDark,
                ),
                _ReceiptRow(
                  label: 'Loan ID',
                  value:
                      '#${payment.loanId.length > 8 ? payment.loanId.substring(0, 8).toUpperCase() : payment.loanId.toUpperCase()}',
                  isDark: isDark,
                ),
                _ReceiptRow(
                  label: 'Method',
                  value: payment.method.label,
                  isDark: isDark,
                  trailing: Icon(
                    payment.method.iconData,
                    size: 16,
                    color: _methodColor(payment.method),
                  ),
                ),
                _ReceiptRow(
                  label: 'Amount',
                  value: CurrencyFormatter.formatPhp(payment.amount),
                  isDark: isDark,
                  valueColor: ColorTokens.accent,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _ReceiptSection(
              title: 'Reference Information',
              children: [
                if (payment.referenceNumber != null)
                  _ReceiptRow(
                    label: 'Reference No.',
                    value: payment.referenceNumber!,
                    isDark: isDark,
                    mono: true,
                  ),
                if (payment.xenditPaymentId != null)
                  _ReceiptRow(
                    label: 'Xendit ID',
                    value: payment.xenditPaymentId!,
                    isDark: isDark,
                    mono: true,
                  ),
                if (payment.collectedBy != null)
                  _ReceiptRow(
                    label: 'Collected By',
                    value: payment.collectedBy!,
                    isDark: isDark,
                  ),
                if (payment.referenceNumber == null &&
                    payment.xenditPaymentId == null &&
                    payment.collectedBy == null)
                  _ReceiptRow(
                    label: 'Reference',
                    value: 'Not available yet',
                    isDark: isDark,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _ReceiptSection(
              title: 'Timestamps',
              children: [
                _ReceiptRow(
                  label: 'Created',
                  value: DateFormatter.formatDisplayDateTime(
                      payment.createdAt),
                  isDark: isDark,
                ),
                if (payment.collectedAt != null)
                  _ReceiptRow(
                    label: 'Completed',
                    value: DateFormatter.formatDisplayDateTime(
                        payment.collectedAt!),
                    isDark: isDark,
                  ),
              ],
            ),
            const SizedBox(height: 32),

            if (payment.receiptUrl != null) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Downloading receipt PDF...')),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Download Receipt PDF'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ColorTokens.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Sharing receipt...')),
                  );
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Receipt'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark
                        ? ColorTokens.darkBorder
                        : ColorTokens.lightBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _statusColor(PaymentStatus status) => switch (status) {
        PaymentStatus.pending => ColorTokens.lightWarning,
        PaymentStatus.completed => ColorTokens.lightSuccess,
        PaymentStatus.failed => ColorTokens.lightError,
        PaymentStatus.refunded => ColorTokens.lightInfo,
      };

  IconData _statusIcon(PaymentStatus status) => switch (status) {
        PaymentStatus.pending => Icons.schedule_rounded,
        PaymentStatus.completed => Icons.check_circle_rounded,
        PaymentStatus.failed => Icons.cancel_rounded,
        PaymentStatus.refunded => Icons.replay_rounded,
      };

  Color _methodColor(PaymentMethod method) => switch (method) {
        PaymentMethod.gcash => const Color(0xFF007BFF),
        PaymentMethod.office => ColorTokens.secondaryAccent,
        PaymentMethod.cash => ColorTokens.lightSuccess,
      };
}

class _ReceiptSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ReceiptSection({
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

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;
  final Widget? trailing;
  final bool mono;

  const _ReceiptRow({
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

class _ReceiptStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const _ReceiptStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
          Icon(_statusIcon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor => switch (status) {
        PaymentStatus.pending => ColorTokens.lightWarning,
        PaymentStatus.completed => ColorTokens.lightSuccess,
        PaymentStatus.failed => ColorTokens.lightError,
        PaymentStatus.refunded => ColorTokens.lightInfo,
      };

  IconData get _statusIcon => switch (status) {
        PaymentStatus.pending => Icons.schedule_rounded,
        PaymentStatus.completed => Icons.check_circle_rounded,
        PaymentStatus.failed => Icons.cancel_rounded,
        PaymentStatus.refunded => Icons.replay_rounded,
      };
}
