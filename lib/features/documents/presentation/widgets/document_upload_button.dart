import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lendflow/core/theme/color_tokens.dart';

/// Camera/gallery pick + upload button with progress indicator.
///
/// Provides a reusable button that:
/// 1. Opens a camera or gallery picker
/// 2. Shows upload progress while the file is being uploaded
/// 3. Displays success/failure state after upload
class DocumentUploadButton extends StatefulWidget {
  /// Label text for the button.
  final String label;

  /// Icon to display alongside the label.
  final IconData icon;

  /// Whether an upload is currently in progress.
  final bool isUploading;

  /// Upload progress (0.0 to 1.0). Only shown when [isUploading] is true.
  final double progress;

  /// Whether the last upload was successful.
  final bool isSuccess;

  /// Whether the last upload failed.
  final bool isError;

  /// Callback when a file is selected and should be uploaded.
  /// The [filePath] and [fileName] are provided from the picker.
  final void Function(String filePath, String fileName) onFileSelected;

  /// Whether the button is enabled.
  final bool enabled;

  const DocumentUploadButton({
    super.key,
    required this.label,
    this.icon = Icons.add_photo_alternate_outlined,
    this.isUploading = false,
    this.progress = 0.0,
    this.isSuccess = false,
    this.isError = false,
    required this.onFileSelected,
    this.enabled = true,
  });

  @override
  State<DocumentUploadButton> createState() => _DocumentUploadButtonState();
}

class _DocumentUploadButtonState extends State<DocumentUploadButton> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.isUploading) {
      return _buildUploadingState(theme);
    }

    if (widget.isSuccess) {
      return _buildSuccessState(theme);
    }

    if (widget.isError) {
      return _buildErrorState(theme);
    }

    return _buildIdleState(theme);
  }

  Widget _buildIdleState(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: widget.enabled ? _pickImage : null,
        icon: Icon(widget.icon, size: 18),
        label: Text(widget.label),
        style: FilledButton.styleFrom(
          backgroundColor: ColorTokens.accent,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUploadingState(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: null,
        icon: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        label: Text('Uploading... ${(widget.progress * 100).toStringAsFixed(0)}%'),
        style: FilledButton.styleFrom(
          backgroundColor: ColorTokens.accent.withOpacity(0.7),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Uploaded'),
        style: FilledButton.styleFrom(
          backgroundColor: ColorTokens.lightSuccess,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: widget.enabled ? _pickImage : null,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Retry Upload'),
        style: FilledButton.styleFrom(
          backgroundColor: ColorTokens.lightError,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    // Show source selection
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Source',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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

      widget.onFileSelected(pickedFile.path, pickedFile.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }
}

/// Source selection button for camera/gallery picker.
class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: ColorTokens.lightBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: ColorTokens.accent),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
