// lib/features/documents/presentation/providers/document_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/features/documents/data/datasources/document_remote_datasource.dart';
import 'package:jireta_loan/features/documents/data/repositories/document_repository_impl.dart';
import 'package:jireta_loan/features/documents/domain/entities/kyc_document.dart';
import 'package:jireta_loan/features/documents/domain/repositories/document_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


sealed class DocumentFeatureState {
  const DocumentFeatureState();
}

class DocumentInitial extends DocumentFeatureState {
  const DocumentInitial();
}

class DocumentLoading extends DocumentFeatureState {
  const DocumentLoading();
}

class DocumentUploading extends DocumentFeatureState {
  final double progress;
  final DocumentType documentType;

  const DocumentUploading({
    required this.progress,
    required this.documentType,
  });
}

class DocumentsLoaded extends DocumentFeatureState {
  final List<KycDocument> documents;

  const DocumentsLoaded({required this.documents});

  KycDocument? findByType(DocumentType type) {
    try {
      return documents.firstWhere((d) => d.documentType == type);
    } catch (_) {
      return null;
    }
  }

  bool get hasAllDocuments =>
      findByType(DocumentType.governmentId) != null &&
      findByType(DocumentType.proofOfBilling) != null &&
      findByType(DocumentType.selfie) != null &&
      findByType(DocumentType.proofOfIncome) != null;

  bool get allVerified =>
      documents.isNotEmpty &&
      documents.every((d) => d.status.isVerified);
}

class DocumentUploaded extends DocumentFeatureState {
  final KycDocument document;

  const DocumentUploaded({required this.document});
}

class SignedUrlLoaded extends DocumentFeatureState {
  final String url;

  const SignedUrlLoaded({required this.url});
}

class DocumentDeleted extends DocumentFeatureState {
  const DocumentDeleted();
}

class DocumentError extends DocumentFeatureState {
  final String message;
  final Failure? failure;

  const DocumentError(this.message, {this.failure});
}


final documentSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final documentRemoteDataSourceProvider =
    Provider<DocumentRemoteDataSource>((ref) {
  return DocumentRemoteDataSource(
    supabaseClient: ref.watch(documentSupabaseClientProvider),
    dio: ref.watch(dioProvider),
  );
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepositoryImpl(
    remoteDataSource: ref.watch(documentRemoteDataSourceProvider),
  );
});

final documentFeatureProvider =
    StateNotifierProvider<DocumentNotifier, DocumentFeatureState>((ref) {
  return DocumentNotifier(
    repository: ref.watch(documentRepositoryProvider),
    authProvider: ref.watch(authProvider),
  );
});


class DocumentNotifier extends StateNotifier<DocumentFeatureState> {
  final DocumentRepository _repository;
  final AppAuthState _authState;

  DocumentNotifier({
    required DocumentRepository repository,
    required AppAuthState authProvider,
  })  : _repository = repository,
        _authState = authProvider,
        super(const DocumentInitial());

  String? get _currentBorrowerId {
    final auth = _authState;
    if (auth is AppAuthAuthenticated) {
      return auth.userId;
    }
    return null;
  }

  Future<void> loadDocuments() async {
    final lenderId = _currentBorrowerId;
    if (lenderId == null) {
      state = const DocumentError('Not authenticated.');
      return;
    }

    state = const DocumentLoading();

    final result = await _repository.list(lenderId: lenderId);

    state = result.fold(
      (failure) => DocumentError(failure.message, failure: failure),
      (documents) => DocumentsLoaded(documents: documents),
    );
  }

  Future<void> uploadDocument({
    required DocumentType documentType,
    required String filePath,
    required String fileName,
  }) async {
    final lenderId = _currentBorrowerId;
    if (lenderId == null) {
      state = const DocumentError('Not authenticated.');
      return;
    }

    state = DocumentUploading(
      progress: 0.0,
      documentType: documentType,
    );

    final result = await _repository.upload(
      lenderId: lenderId,
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

  Future<void> getSignedUrl({required String filePath}) async {
    final result = await _repository.getSignedUrl(filePath: filePath);

    state = result.fold(
      (failure) => DocumentError(failure.message, failure: failure),
      (url) => SignedUrlLoaded(url: url),
    );
  }

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

  void resetState() {
    state = const DocumentInitial();
  }
}
