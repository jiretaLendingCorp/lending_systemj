import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/utils/date_formatter.dart';
import 'package:lendflow/features/documents/domain/entities/kyc_document.dart';
import 'package:lendflow/features/documents/presentation/providers/document_notifier.dart';
import 'package:lendflow/features/documents/presentation/widgets/document_type_card.dart';
import 'package:lendflow/features/documents/presentation/widgets/document_upload_button.dart';

/// Mobile page for uploading KYC documents.
///
/// Features:
/// - Four document type cards (Government ID, Proof of Billing, Selfie, Proof of Income)
/// - Each card shows upload status and allows camera/picker selection
/// - Upload progress indicator
/// - Pull-to-refresh to reload document status
class KycUploadPage extends ConsumerStatefulWidget {
  const KycUploadPage({super.key});

  @override
  ConsumerState<KycUploadPage> createState() => _KycUploadPageState();
}

class _KycUploadPageState extends ConsumerState<KycUploadPage> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentFeatureProvider.notifier).loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docState = ref.watch(documentFeatureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Verification'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(documentFeatureProvider.notifier).loadDocuments(),
        child: CustomScrollView(
          slivers: [
            // Introduction text
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Required Documents',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please upload clear photos or scans of the following '
                      'documents to complete your identity verification.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Upload progress
            if (docState is DocumentUploading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _UploadProgressCard(
                    documentType: docState.documentType,
                    progress: docState.progress,
                  ),
                ),
              ),

            // Document type cards
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildDocumentCard(
                    DocumentType.governmentId,
                    docState,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentCard(
                    DocumentType.proofOfBilling,
                    docState,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentCard(
                    DocumentType.selfie,
                    docState,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentCard(
                    DocumentType.proofOfIncome,
                    docState,
                  ),
                ]),
              ),
            ),

            // Error message
            if (docState is DocumentError)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorTokens.lightError.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ColorTokens.lightError.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 18, color: ColorTokens.lightError),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            docState.message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ColorTokens.lightError,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Upload success
            if (docState is DocumentUploaded)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorTokens.lightSuccess.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ColorTokens.lightSuccess.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 18, color: ColorTokens.lightSuccess),
                        const SizedBox(width: 8),
                        Text(
                          'Document uploaded successfully',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ColorTokens.lightSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Tips section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: _TipsCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(
    DocumentType type,
    DocumentFeatureState docState,
  ) {
    // Find the existing document for this type (if any)
    KycDocument? existingDoc;
    if (docState is DocumentsLoaded) {
      existingDoc = docState.findByType(type);
    }

    return DocumentTypeCard(
      documentType: type,
      existingDocument: existingDoc,
      onUpload: () => _handleUpload(type),
      onReplace: existingDoc != null && existingDoc.needsReupload
          ? () => _handleUpload(type)
          : null,
      onView: existingDoc != null
          ? () => _viewDocument(existingDoc!)
          : null,
    );
  }

  Future<void> _handleUpload(DocumentType type) async {
    // Show source selection dialog
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Source',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      ref.read(documentFeatureProvider.notifier).uploadDocument(
            documentType: type,
            filePath: pickedFile.path,
            fileName: pickedFile.name,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _viewDocument(KycDocument document) {
    ref.read(documentFeatureProvider.notifier).getSignedUrl(
          filePath: document.fileUrl,
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DocumentPreviewWrapper(document: document),
      ),
    );
  }
}

/// Upload progress card widget.
class _UploadProgressCard extends StatelessWidget {
  final DocumentType documentType;
  final double progress;

  const _UploadProgressCard({
    required this.documentType,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: ColorTokens.accent.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ColorTokens.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Uploading ${documentType.label}...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ColorTokens.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: ColorTokens.lightBorder,
                color: ColorTokens.accent,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tips card for document upload guidance.
class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 18, color: ColorTokens.lightWarning),
                const SizedBox(width: 8),
                Text(
                  'Tips for a quick verification',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _tipItem('Ensure documents are clear and not blurry'),
            _tipItem('All four corners of the document should be visible'),
            _tipItem('Use good lighting when taking photos'),
            _tipItem('Selfie should clearly show your face'),
            _tipItem('Accepted formats: JPG, PNG, PDF'),
          ],
        ),
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(
              color: ColorTokens.lightWarning,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: ColorTokens.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper for document preview navigation.
class _DocumentPreviewWrapper extends ConsumerWidget {
  final KycDocument document;

  const _DocumentPreviewWrapper({required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(documentFeatureProvider);
    final signedUrl = docState is SignedUrlLoaded ? docState.url : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(document.documentType.label),
        centerTitle: true,
      ),
      body: Center(
        child: signedUrl != null
            ? Text('Document preview: $signedUrl')
            : const CircularProgressIndicator(),
      ),
    );
  }
}
