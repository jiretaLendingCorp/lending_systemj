// lib/features/lenders/presentation/widgets/kyc_status_card.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/features/lenders/domain/entities/lender_profile.dart';

class KycStatusCard extends StatelessWidget {
  final KycStatus kycStatus;

  const KycStatusCard({super.key, required this.kycStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _statusIcon,
                color: _statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KYC Verification',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            if (kycStatus.isPending || kycStatus.isRejected)
              FilledButton(
                onPressed: () => _navigateToKycUpload(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _statusColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(
                  kycStatus.isPending ? 'Upload' : 'Retry',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor => switch (kycStatus) {
        KycStatus.pending => ColorTokens.lightWarning,
        KycStatus.verified => ColorTokens.lightSuccess,
        KycStatus.rejected => ColorTokens.lightError,
      };

  IconData get _statusIcon => switch (kycStatus) {
        KycStatus.pending => Icons.schedule,
        KycStatus.verified => Icons.verified_user_outlined,
        KycStatus.rejected => Icons.error_outline,
      };

  String get _statusTitle => switch (kycStatus) {
        KycStatus.pending => 'Verification Pending',
        KycStatus.verified => 'Verified',
        KycStatus.rejected => 'Verification Failed',
      };

  String get _statusDescription => switch (kycStatus) {
        KycStatus.pending =>
          'Please upload your documents to complete verification.',
        KycStatus.verified =>
          'Your identity has been verified. You can apply for loans.',
        KycStatus.rejected =>
          'Some documents were not accepted. Please re-upload.',
      };

  void _navigateToKycUpload(BuildContext context) {
    Navigator.pushNamed(context, '/kyc-upload');
  }
}
