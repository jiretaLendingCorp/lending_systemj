// lib/features/documents/presentation/widgets/document_type_card.dart
import 'package:flutter/material.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/documents/domain/entities/kyc_document.dart';

class DocumentTypeCard extends StatelessWidget {
  final DocumentType documentType;
  final KycDocument? existingDocument;
  final VoidCallback? onUpload;
  final VoidCallback? onReplace;
  final VoidCallback? onView;

  const DocumentTypeCard({
    super.key,
    required this.documentType,
    this.existingDocument,
    this.onUpload,
    this.onReplace,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = existingDocument?.status;
    final hasDocument = existingDocument != null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iconBackgroundColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    documentType.icon,
                    color: _iconBackgroundColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documentType.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        documentType.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasDocument) _StatusIndicator(status: status!),
              ],
            ),

            const SizedBox(height: 12),

            if (hasDocument) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _statusBackgroundColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon, size: 16, color: _statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      DateFormatter.formatRelative(
                          existingDocument!.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (!hasDocument && onUpload != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: const Text('Upload Document'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorTokens.accent,
                    side: const BorderSide(color: ColorTokens.accent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              )
            else if (hasDocument) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (onView != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onView,
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (onView != null && onReplace != null)
                    const SizedBox(width: 8),
                  if (onReplace != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onReplace,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Replace'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ColorTokens.secondaryAccent,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _iconBackgroundColor => switch (documentType) {
        DocumentType.governmentId => ColorTokens.accent,
        DocumentType.proofOfBilling => ColorTokens.lightInfo,
        DocumentType.selfie => ColorTokens.secondaryAccent,
        DocumentType.proofOfIncome => ColorTokens.lightSuccess,
      };

  Color get _borderColor {
    if (existingDocument == null) return ColorTokens.lightBorder;
    return switch (existingDocument!.status) {
      DocumentStatus.pending => ColorTokens.lightWarning,
      DocumentStatus.verified => ColorTokens.lightSuccess,
      DocumentStatus.rejected => ColorTokens.lightError,
    };
  }

  Color get _statusColor => switch (existingDocument?.status) {
        DocumentStatus.pending => ColorTokens.lightWarning,
        DocumentStatus.verified => ColorTokens.lightSuccess,
        DocumentStatus.rejected => ColorTokens.lightError,
        null => ColorTokens.lightBorder,
      };

  Color get _statusBackgroundColor => _statusColor;

  IconData get _statusIcon => switch (existingDocument?.status) {
        DocumentStatus.pending => Icons.schedule,
        DocumentStatus.verified => Icons.check_circle_outline,
        DocumentStatus.rejected => Icons.error_outline,
        null => Icons.upload_file,
      };

  String get _statusText => switch (existingDocument?.status) {
        DocumentStatus.pending => 'Under review',
        DocumentStatus.verified => 'Verified',
        DocumentStatus.rejected => 'Rejected – please re-upload',
        null => 'Not uploaded',
      };
}

class _StatusIndicator extends StatelessWidget {
  final DocumentStatus status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DocumentStatus.pending => ColorTokens.lightWarning,
      DocumentStatus.verified => ColorTokens.lightSuccess,
      DocumentStatus.rejected => ColorTokens.lightError,
    };

    final icon = switch (status) {
      DocumentStatus.pending => Icons.schedule,
      DocumentStatus.verified => Icons.check_circle,
      DocumentStatus.rejected => Icons.cancel,
    };

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
