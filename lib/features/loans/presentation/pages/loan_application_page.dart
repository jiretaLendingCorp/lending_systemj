// lib/features/loans/presentation/pages/loan_application_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/constants.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/core/utils/validators.dart';
import 'package:jireta_loan/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:jireta_loan/features/loans/presentation/providers/loan_notifier.dart';

class LoanApplicationPage extends ConsumerStatefulWidget {
  const LoanApplicationPage({super.key});

  @override
  ConsumerState<LoanApplicationPage> createState() =>
      _LoanApplicationPageState();
}

class _LoanApplicationPageState extends ConsumerState<LoanApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _termController = TextEditingController();
  final _coMakerNameController = TextEditingController();
  final _coMakerPhoneController = TextEditingController();
  final _coMakerAddressController = TextEditingController();

  ScheduleType _scheduleType = ScheduleType.monthly;
  String _coMakerRelationship = 'Friend';
  bool _isSubmitting = false;

  static const _relationshipOptions = [
    'Friend',
    'Relative',
    'Coworker',
    'Neighbor',
    'Spouse',
    'Parent',
    'Sibling',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _termController.dispose();
    _coMakerNameController.dispose();
    _coMakerPhoneController.dispose();
    _coMakerAddressController.dispose();
    super.dispose();
  }

  double get _principal {
    return double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
  }

  int get _termDays {
    return int.tryParse(_termController.text) ?? 0;
  }

  double get _interestAmount => _principal * AppConstants.interestRate;

  double get _totalPayable => _principal + _interestAmount;

  int get _installmentCount => _scheduleType.installmentCount(_termDays);

  double get _installmentAmount =>
      _installmentCount > 0 ? _totalPayable / _installmentCount : 0;

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    ref.read(loanFeatureProvider.notifier).createLoan(
          principal: _principal,
          termDays: _termDays,
          scheduleType: _scheduleType,
          coMakerFullName: _coMakerNameController.text.trim(),
          coMakerPhone: _coMakerPhoneController.text.trim(),
          coMakerAddress: _coMakerAddressController.text.trim(),
          coMakerRelationship: _coMakerRelationship,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<LoanFeatureState>(loanFeatureProvider, (prev, next) {
      if (next is LoanError) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: ColorTokens.lightError,
          ),
        );
      } else if (next is LoanOperationSuccess) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: ColorTokens.lightSuccess,
          ),
        );
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Application'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: 'Loan Amount',
                icon: Icons.payments_outlined,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              AuthTextField(
                label: 'Amount',
                hint: '${AppConstants.currencySymbol}3,000 - ${AppConstants.currencySymbol}500,000',
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: Validators.loanAmount,
                prefixIcon: Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: isDark
                      ? ColorTokens.darkTextSecondary
                      : ColorTokens.lightTextSecondary,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              Text(
                'Range: ${AppConstants.currencySymbol}${AppConstants.minLoanAmount.toInt()} - ${AppConstants.currencySymbol}${AppConstants.maxLoanAmount.toInt()}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? ColorTokens.darkTextSecondary
                      : ColorTokens.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),

              _SectionHeader(
                title: 'Term & Schedule',
                icon: Icons.calendar_today_outlined,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              AuthTextField(
                label: 'Term (Days)',
                hint: 'e.g., 30, 60, 90',
                controller: _termController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Loan term is required';
                  }
                  final term = int.tryParse(value);
                  if (term == null) {
                    return 'Please enter a valid number of days';
                  }
                  if (term < 7) {
                    return 'Minimum term is 7 days';
                  }
                  if (term > 365) {
                    return 'Maximum term is 365 days';
                  }
                  return null;
                },
                prefixIcon: Icon(
                  Icons.schedule_outlined,
                  size: 20,
                  color: isDark
                      ? ColorTokens.darkTextSecondary
                      : ColorTokens.lightTextSecondary,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Schedule',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isDark
                              ? ColorTokens.darkTextSecondary
                              : ColorTokens.lightTextSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ScheduleType.values.map((type) {
                      final isSelected = type == _scheduleType;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () =>
                                setState(() => _scheduleType = type),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorTokens.accent
                                        .withOpacity(isDark ? 0.15 : 0.08)
                                    : isDark
                                        ? ColorTokens.darkSurface
                                        : ColorTokens.lightSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? ColorTokens.accent
                                      : isDark
                                          ? ColorTokens.darkBorder
                                          : ColorTokens.lightBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _scheduleIcon(type),
                                    size: 20,
                                    color: isSelected
                                        ? ColorTokens.accent
                                        : isDark
                                            ? ColorTokens.darkDisabled
                                            : ColorTokens.lightDisabled,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    type.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? ColorTokens.accent
                                          : isDark
                                              ? ColorTokens.darkTextSecondary
                                              : ColorTokens.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_principal > 0 && _termDays > 0) ...[
                _LoanPreviewCard(
                  principal: _principal,
                  interestRate: AppConstants.interestRate,
                  interestAmount: _interestAmount,
                  totalPayable: _totalPayable,
                  installmentCount: _installmentCount,
                  installmentAmount: _installmentAmount,
                  scheduleType: _scheduleType,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
              ],

              _SectionHeader(
                title: 'Co-Maker Information',
                icon: Icons.person_add_outlined,
                isDark: isDark,
              ),
              const SizedBox(height: 4),
              Text(
                'A co-maker guarantees the loan repayment if the lender defaults.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? ColorTokens.darkTextSecondary
                      : ColorTokens.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                label: 'Full Name',
                hint: 'Co-maker\'s full name',
                controller: _coMakerNameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                validator: (value) => Validators.required(value, fieldName: 'Co-maker name'),
                prefixIcon: Icon(
                  Icons.person_outlined,
                  size: 20,
                  color: isDark
                      ? ColorTokens.darkTextSecondary
                      : ColorTokens.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Phone Number',
                hint: '09XXXXXXXXX',
                controller: _coMakerPhoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: Validators.phone,
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: isDark
                      ? ColorTokens.darkTextSecondary
                      : ColorTokens.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Address',
                hint: 'Co-maker\'s address',
                controller: _coMakerAddressController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                validator: (value) => Validators.required(value, fieldName: 'Co-maker address'),
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: isDark
                      ? ColorTokens.darkTextSecondary
                      : ColorTokens.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Relationship',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isDark
                              ? ColorTokens.darkTextSecondary
                              : ColorTokens.lightTextSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _coMakerRelationship,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.people_outlined,
                        size: 20,
                        color: isDark
                            ? ColorTokens.darkTextSecondary
                            : ColorTokens.lightTextSecondary,
                      ),
                    ),
                    items: _relationshipOptions
                        .map((option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _coMakerRelationship = value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a relationship';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Application'),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'By submitting, you agree to the terms and conditions of the loan. Interest rate is fixed at 20% per term. Late payments incur a 20% penalty on the overdue amount.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? ColorTokens.darkDisabled
                      : ColorTokens.lightDisabled,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _scheduleIcon(ScheduleType type) => switch (type) {
        ScheduleType.daily => Icons.today_rounded,
        ScheduleType.weekly => Icons.date_range_rounded,
        ScheduleType.monthly => Icons.calendar_month_rounded,
      };
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: ColorTokens.accent,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _LoanPreviewCard extends StatelessWidget {
  final double principal;
  final double interestRate;
  final double interestAmount;
  final double totalPayable;
  final int installmentCount;
  final double installmentAmount;
  final ScheduleType scheduleType;
  final bool isDark;

  const _LoanPreviewCard({
    required this.principal,
    required this.interestRate,
    required this.interestAmount,
    required this.totalPayable,
    required this.installmentCount,
    required this.installmentAmount,
    required this.scheduleType,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ColorTokens.accent.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 18,
                  color: ColorTokens.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Loan Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorTokens.accent,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PreviewRow(
              label: 'Principal',
              value: CurrencyFormatter.formatPhp(principal),
              isDark: isDark,
            ),
            _PreviewRow(
              label: 'Interest (${CurrencyFormatter.formatPercentage(interestRate)})',
              value: CurrencyFormatter.formatPhp(interestAmount),
              isDark: isDark,
            ),
            Divider(
              color: isDark ? ColorTokens.darkBorder : ColorTokens.lightBorder,
            ),
            _PreviewRow(
              label: 'Total Payable',
              value: CurrencyFormatter.formatPhp(totalPayable),
              isDark: isDark,
              isBold: true,
              valueColor: ColorTokens.accent,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorTokens.accent.withOpacity(isDark ? 0.08 : 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$installmentCount ${scheduleType.label} Installments',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? ColorTokens.darkTextSecondary
                              : ColorTokens.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.formatPhp(installmentAmount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ColorTokens.accent,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Per installment',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? ColorTokens.darkTextSecondary
                              : ColorTokens.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Due ${scheduleType.label.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? ColorTokens.darkDisabled
                              : ColorTokens.lightDisabled,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isBold;
  final Color? valueColor;

  const _PreviewRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? ColorTokens.darkTextSecondary
                  : ColorTokens.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ??
                  (isDark ? ColorTokens.darkText : ColorTokens.lightText),
            ),
          ),
        ],
      ),
    );
  }
}
