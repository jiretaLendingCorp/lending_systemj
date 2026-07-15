// lib/features/reports/presentation/widgets/aging_table.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:jireta_loan/core/utils/currency_formatter.dart';
import 'package:jireta_loan/features/reports/domain/entities/report_data.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AgingTable extends StatelessWidget {
  final OverdueReport report;

  const AgingTable({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : ColorTokens.darkSurface;
    final borderColor = isLight ? ColorTokens.lightBorder : ColorTokens.darkBorder;
    final headerBg = isLight ? ColorTokens.lightSurface : ColorTokens.darkCanvas;
    final totalOverdue = report.totalOverdue;
    final totalAmount = report.totalAmount;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 20,
                    color: ColorTokens.secondaryAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overdue Aging Summary',
                    style: TextStyles.titleSmall(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: headerBg,
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('Aging Bucket', style: TextStyles.labelMedium(context).copyWith(fontWeight: FontWeight.w700))),
                  Expanded(flex: 2, child: Text('Count', style: TextStyles.labelMedium(context).copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                  Expanded(flex: 3, child: Text('Total Amount', style: TextStyles.labelMedium(context).copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                  Expanded(flex: 2, child: Text('% of Portfolio', style: TextStyles.labelMedium(context).copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                ],
              ),
            ),

            _AgingRow(
              bucket: '1-7 Days',
              count: report.days1to7,
              amount: report.amount1to7,
              totalAmount: totalAmount,
              color: ColorTokens.lightWarning,
              isLight: isLight,
            ),
            _AgingRow(
              bucket: '8-30 Days',
              count: report.days8to30,
              amount: report.amount8to30,
              totalAmount: totalAmount,
              color: ColorTokens.secondaryAccent,
              isLight: isLight,
            ),
            _AgingRow(
              bucket: '30+ Days',
              count: report.days30Plus,
              amount: report.amount30Plus,
              totalAmount: totalAmount,
              color: ColorTokens.lightError,
              isLight: isLight,
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: headerBg,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Total',
                      style: TextStyles.labelLarge(context).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$totalOverdue',
                      style: TextStyles.labelLarge(context).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      CurrencyFormatter.formatPhp(totalAmount),
                      style: TextStyles.labelLarge(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: ColorTokens.lightError,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '100%',
                      style: TextStyles.labelLarge(context).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.right,
                    ),
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

class _AgingRow extends StatelessWidget {
  final String bucket;
  final int count;
  final double amount;
  final double totalAmount;
  final Color color;
  final bool isLight;

  const _AgingRow({
    required this.bucket,
    required this.count,
    required this.amount,
    required this.totalAmount,
    required this.color,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isLight
        ? ColorTokens.lightBorder.withValues(alpha: 0.5)
        : ColorTokens.darkBorder.withValues(alpha: 0.5);
    final pct = totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  bucket,
                  style: TextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$count',
              style: TextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              CurrencyFormatter.formatPhp(amount),
              style: TextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 32,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
