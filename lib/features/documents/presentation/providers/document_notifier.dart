import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/features/documents/data/datasources/document_remote_datasource.dart';
import 'package:lendflow/features/documents/data/repositories/document_repository_impl.dart';
import 'package:lendflow/features/documents/domain/entities/kyc_document.dart';
import 'package:lendflow/features/documents/domain/repositories/document_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────
// Document state model
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level document state managed by [DocumentNotifier].
sealed class DocumentFeatureState {
  const DocumentFeatureState();
}

/// Initial state.
class DocumentInitial extends DocumentFeatureState {
  const DocumentInitial();
}

/// Loading state.
class DocumentLoading extends DocumentFeatureState {
  const DocumentLoading();
}

/// Upload in progress state.
class DocumentUploading extends DocumentFeatureState {
  final double progress;
  final DocumentType documentType;

  const DocumentUploading({
    required this.progress,
    required this.documentType,
  });
}

/// Documents loaded successfully.
class DocumentsLoaded extends DocumentFeatureState {
  final List<KycDocument> documents;

  const DocumentsLoaded({required this.documents});

  /// Find a document by type.
  KycDocument? findByType(DocumentType type) {
    try {
      return documents.firstWhere((d) => d.documentType == type);
    } catch (_) {
      return null;
    }
  }

  /// Whether all required documents are uploaded.
  bool get hasAllDocuments =>
      findByType(DocumentType.governmentId) != null &&
      findByType(DocumentType.proofOfBilling) != null &&
      findByType(DocumentType.selfie) != null &&
      findByType(DocumentType.proofOfIncome) != null;

  /// Whether all documents are verified.
  bool get allVerified =>
      documents.isNotEmpty &&
      documents.every((d) => d.status.isVerified);
}

/// Upload completed state.
class DocumentUploaded extends DocumentFeatureState {
  final KycDocument document;

  const DocumentUploaded({required this.document});
}

/// Signed URL generated.
class SignedUrlLoaded extends DocumentFeatureState {
  final String url;

  const SignedUrlLoaded({required this.url});
}

/// Document deleted.
class DocumentDeleted extends DocumentFeatureState {
  const DocumentDeleted();
}

/// An error occurred.
class DocumentError extends DocumentFeatureState {
  final String message;
  final Failure? failure;

  const DocumentError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [SupabaseClient] instance.
final documentSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provides the [DocumentRemoteDataSource].
final documentRemoteDataSourceProvider =
    Provider<DocumentRemoteDataSource>((ref) {
  return DocumentRemoteDataSource(
    supabaseClient: ref.watch(documentSupabaseClientProvider),
    dio: ref.watch(dioProvider),
  );
});

/// Provides the [DocumentRepository] implementation.
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(
    remoteDataSource: ref.watch(documentRemoteDataSourceProvider),
  );
});

/// Provides the [DocumentNotifier] for document feature screens.
final documentFeatureProvider =
    StateNotifierProvider<DocumentNotifier, DocumentFeatureState>((ref) {
  return DocumentNotifier(
    repository: ref.watch(documentRepositoryProvider),
    authProvider: ref.watch(authProvider),
  );
});

// ─────────────────────────────────────────────────────────────────
// Document notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing document feature UI state.
class DocumentNotifier extends StateNotifier<DocumentFeatureState> {
  final DocumentRepository _repository;
  final AuthState _authState;

  DocumentNotifier({
    required DocumentRepository repository,
    required AuthState authProvider,
  })  : _repository = repository,
        _authState = authProvider,
        super(const DocumentInitial());

  /// Get the current borrower's ID from auth state.
  String? get _currentBorrowerId {
    if (_authState is AuthAuthenticated) {
      return (_authState as AuthAuthenticated).user.id;
    }
    return null;
  }

  /// Load all KYC documents for the current borrower.
  Future<void> loadDocuments() async {
    final borrowerId = _currentBorrowerId;
    if (borrowerId == null) {
      state = const DocumentError('Not authenticated.');
      return;
    }

    state = const DocumentLoading();

    final result = await _repository.list(borrowerId: borrowerId);

    state = result.fold(
      (failure) => DocumentError(failure.message, failure: failure),
      (documents) => DocumentsLoaded(documents: documents),
    );
  }

  /// Upload a KYC document.
  Future<void> uploadDocument({
    required DocumentType documentType,
    required String filePath,
    required String fileName,
  }) async {
    final borrowerId = _currentBorrowerId;
    if (borrowerId == null) {
      state = const DocumentError('Not authenticated.');
      return;
    }

    state = DocumentUploading(
      progress: 0.0,
      documentType: documentType,
    );

    final result = await _repository.upload(
      borrowerId: borrowerId,
      documentType: documentType.toApiString(),
      filePath: filePath,
      fileName: fileName,
      onProgress: (sent, total) {
        final progress = total > 0 ? sent / total : 0.0;
        state = DocumentUploading(
          progress: progress,
          documentType: documentType,
        );
      },
    );

    state = result.fold(
      (failure) => DocumentError(failure.message, failure: failure),
      (document) => DocumentUploaded(document: document),
    );
  }

  /// Generate a signed URL for a document.
  Future<void> getSignedUrl({required String filePath}) async {
    final result = await _repository.getSignedUrl(filePath: filePath);

    state = result.fold(
      (failure) => DocumentError(failure.message, failure: failure),
      (url) => SignedUrlLoaded(url: url),
    );
  }

  /// Delete a document.
  Future<void> deleteDocument({
    required String documentId,
    required String filePath,
  }) async {
    final result = await _repository.delete(
      documentId: documentId,
      filePath: filePath,
    );

    state = result.fold(
      (failure) => DocumentError(failure.message, failure: failure),
      (_) => const DocumentDeleted(),
    );
  }

  /// Reset state to initial.
  void resetState() {
    state = const DocumentInitial();
  }
}
