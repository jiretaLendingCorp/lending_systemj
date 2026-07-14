// lib/features/documents/presentation/pages/document_preview_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/utils/date_formatter.dart';
import 'package:jireta_loan/features/documents/domain/entities/kyc_document.dart';
import 'package:jireta_loan/features/documents/presentation/providers/document_notifier.dart';

class DocumentPreviewPage extends ConsumerStatefulWidget {
  final KycDocument document;

  const DocumentPreviewPage({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<DocumentPreviewPage> createState() =>
      _DocumentPreviewPageState();
}

class _DocumentPreviewPageState extends ConsumerState<DocumentPreviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentFeatureProvider.notifier).getSignedUrl(
            filePath: widget.document.fileUrl,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docState = ref.watch(documentFeatureProvider);
    final doc = widget.document;

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.documentType.label),
        centerTitle: true,
        actions: [
          if (doc.needsReupload)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                Navigator.pop(context);
              },
              tooltip: 'Re-upload',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Document Details',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        _StatusBadge(status: doc.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Type', doc.documentType.label),
                    _infoRow('Uploaded', DateFormatter.formatDisplayDate(doc.createdAt)),
                    if (doc.reviewedAt != null)
                      _infoRow('Reviewed', DateFormatter.formatDisplayDate(doc.reviewedAt!)),
                    if (doc.reviewedBy != null)
                      _infoRow('Reviewed By', doc.reviewedBy!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (docState is SignedUrlLoaded)
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 400,
                      color: ColorTokens.lightSurface,
                      child: _buildDocumentPreview(docState.url),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 6),
                          Text(
                            'This link expires in 1 hour for security',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (docState is DocumentLoading)
              const Card(
                child: SizedBox(
                  width: double.infinity,
                  height: 400,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (docState is DocumentError)
              Card(
                child: SizedBox(
                  width: double.infinity,
                  height: 400,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load document',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () {
                            ref
                                .read(documentFeatureProvider.notifier)
                                .getSignedUrl(
                                  filePath: widget.document.fileUrl,
                                );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            if (doc.status.isRejected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ColorTokens.lightError.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: ColorTokens.lightError.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 20, color: ColorTokens.lightError),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Document Rejected',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: ColorTokens.lightError,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This document was not accepted. Please re-upload '
                            'a clearer image or a different document.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ColorTokens.lightError,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (doc.needsReupload)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Re-upload Document'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorTokens.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(String url) {
    final isImage = _isImageUrl(url);

    if (isImage) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.broken_image_outlined, size: 48),
                const SizedBox(height: 8),
                Text('Failed to load image',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        },
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_outlined,
              size: 64, color: ColorTokens.lightError),
          const SizedBox(height: 12),
          Text(
            'PDF Document',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {
            },
            child: const Text('Open Document'),
          ),
        ],
      ),
    );
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.gif') ||
        lower.contains('.webp');
  }
}

class _StatusBadge extends StatelessWidget {
  final DocumentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Color get _statusColor => switch (status) {
        DocumentStatus.pending => ColorTokens.lightWarning,
        DocumentStatus.verified => ColorTokens.lightSuccess,
        DocumentStatus.rejected => ColorTokens.lightError,
      };
}
