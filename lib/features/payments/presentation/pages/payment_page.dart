// lib/features/payments/presentation/pages/payment_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';
import 'package:jireta_loan/features/payments/presentation/providers/payment_notifier.dart';
import 'package:jireta_loan/features/payments/presentation/widgets/payment_method_card.dart';
import 'package:jireta_loan/features/payments/presentation/widgets/payment_summary_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final String? loanId;

  const PaymentPage({super.key, this.loanId});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PaymentMethod _selectedMethod = PaymentMethod.gcash;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitPayment() {
    if (!_formKey.currentState!.validate()) return;

    final amount = CurrencyFormatter.parsePhp(_amountController.text);
    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum payment amount is ₱100.'),
          backgroundColor: ColorTokens.lightError,
        ),
      );
      return;
    }

    final loanId = widget.loanId ?? '';
    if (loanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No loan selected for payment.'),
          backgroundColor: ColorTokens.lightError,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    ref.read(paymentFeatureProvider.notifier).createPayment(
          loanId: loanId,
          amount: amount,
          method: _selectedMethod,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentState = ref.watch(paymentFeatureProvider);

    ref.listen<PaymentFeatureState>(paymentFeatureProvider, (prev, next) {
      if (next is PaymentOperationSuccess) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: ColorTokens.lightSuccess,
          ),
        );
        context.push('/payments/${next.payment.id}/receipt');
      } else if (next is PaymentError) {
        setState(() => _isSubmitting = false);
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
        title: const Text('Make a Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.loanId != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorTokens.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ColorTokens.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.wallet,
                        color: ColorTokens.accent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loan #${widget.loanId!.length > 8 ? widget.loanId!.substring(0, 8).toUpperCase() : widget.loanId!.toUpperCase()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Payment for this loan',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? ColorTokens.darkTextSecondary
                                        : ColorTokens.lightTextSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                'Payment Amount',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Enter amount',
                  prefixText: '₱ ',
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark
                        ? ColorTokens.darkText
                        : ColorTokens.lightText,
                  ),
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark
                          ? ColorTokens.darkBorder
                          : ColorTokens.lightBorder,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a payment amount.';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount.';
                  }
                  if (amount < 100) {
                    return 'Minimum payment is ₱100.';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [500.0, 1000.0, 2000.0, 5000.0].map((amount) {
                  return ActionChip(
                    label: Text(CurrencyFormatter.formatPhpCompact(amount)),
                    onPressed: () {
                      _amountController.text = amount.toStringAsFixed(2);
                      setState(() {});
                    },
                    backgroundColor: isDark
                        ? ColorTokens.darkSurface
                        : ColorTokens.lightSurface,
                    side: BorderSide(
                      color: isDark
                          ? ColorTokens.darkBorder
                          : ColorTokens.lightBorder,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Column(
                children: PaymentMethod.values.map((method) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PaymentMethodCard(
                      method: method,
                      isSelected: _selectedMethod == method,
                      onTap: () => setState(() => _selectedMethod = method),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              if (_amountController.text.isNotEmpty) ...[
                PaymentSummaryCard(
                  amount: CurrencyFormatter.parsePhp(_amountController.text),
                  method: _selectedMethod,
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ||
                          paymentState is PaymentCreating
                      ? null
                      : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorTokens.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor:
                        ColorTokens.accent.withValues(alpha: 0.5),
                  ),
                  child: paymentState is PaymentCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _getSubmitButtonText(_selectedMethod),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubmitButtonText(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.gcash => 'Pay with GCash',
      PaymentMethod.office => 'Record Office Payment',
      PaymentMethod.cash => 'Request Cash Collection',
    };
  }
}
