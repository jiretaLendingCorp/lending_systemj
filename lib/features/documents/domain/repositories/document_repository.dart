import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/documents/domain/entities/kyc_document.dart';

/// Abstract interface for KYC document operations.
///
/// Follows the clean-architecture pattern: use cases depend on this
/// interface, and the data layer provides the concrete implementation.
abstract class DocumentRepository {
  /// Upload a KYC document file.
  Future<Either<Failure, KycDocument>> upload({
    required String borrowerId,
    required String documentType,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  });

  /// List all KYC documents for a borrower.
  Future<Either<Failure, List<KycDocument>>> list({
    required String borrowerId,
  });

  /// Generate a signed URL for secure document access.
  Future<Either<Failure, String>> getSignedUrl({
    required String filePath,
    int expiresIn = 3600,
  });

  /// Delete a KYC document.
  Future<Either<Failure, void>> delete({
    required String documentId,
    required String filePath,
  });
}
