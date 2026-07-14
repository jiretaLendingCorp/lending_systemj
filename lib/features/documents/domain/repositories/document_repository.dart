// lib/features/documents/domain/repositories/document_repository.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/documents/domain/entities/kyc_document.dart';

abstract class DocumentRepository {
  Future<Either<Failure, KycDocument>> upload({
    required String lenderId,
    required String documentType,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  });

  Future<Either<Failure, List<KycDocument>>> list({
    required String lenderId,
  });

  Future<Either<Failure, String>> getSignedUrl({
    required String filePath,
    int expiresIn = 3600,
  });

  Future<Either<Failure, void>> delete({
    required String documentId,
    required String filePath,
  });
}
