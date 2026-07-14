// lib/features/payments/presentation/widgets/payment_method_card.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback? onTap;

  const PaymentMethodCard({
    super.key,
    required this.method,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _methodAccentColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.08)
              : isDark
                  ? ColorTokens.darkSurface
                  : ColorTokens.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accentColor
                : isDark
                    ? ColorTokens.darkBorder
                    : ColorTokens.lightBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _methodIcon,
                color: accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? accentColor
                              : isDark
                                  ? ColorTokens.darkText
                                  : ColorTokens.lightText,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? ColorTokens.darkTextSecondary
                              : ColorTokens.lightTextSecondary,
                        ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? ColorTokens.darkBorder
                        : ColorTokens.lightBorder,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData get _methodIcon => switch (method) {
        PaymentMethod.gcash => Icons.phone_android_rounded,
        PaymentMethod.office => Icons.store_rounded,
        PaymentMethod.cash => Icons.payments_rounded,
      };

  Color get _methodAccentColor => switch (method) {
        PaymentMethod.gcash => const Color(0xFF007BFF),
        PaymentMethod.office => ColorTokens.secondaryAccent,
        PaymentMethod.cash => ColorTokens.lightSuccess,
      };
}
