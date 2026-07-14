import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/documents/data/datasources/document_remote_datasource.dart';
import 'package:lendflow/features/documents/domain/entities/kyc_document.dart';
import 'package:lendflow/features/documents/domain/repositories/document_repository.dart';

/// Concrete implementation of [DocumentRepository].
///
/// Delegates to [DocumentRemoteDataSource] for all network and storage
/// operations, and maps [AppException] subtypes to [Failure] subtypes.
class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource _remoteDataSource;

  DocumentRepositoryImpl({required DocumentRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, KycDocument>> upload({
    required String borrowerId,
    required String documentType,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final document = await _remoteDataSource.upload(
        borrowerId: borrowerId,
        documentType: documentType,
        file: File(filePath),
        fileName: fileName,
        onProgress: onProgress,
      );
      return Right(document);
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<KycDocument>>> list({
    required String borrowerId,
  }) async {
    try {
      final documents = await _remoteDataSource.list(
        borrowerId: borrowerId,
      );
      return Right(documents);
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getSignedUrl({
    required String filePath,
    int expiresIn = 3600,
  }) async {
    try {
      final url = await _remoteDataSource.getSignedUrl(
        filePath: filePath,
        expiresIn: expiresIn,
      );
      return Right(url);
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete({
    required String documentId,
    required String filePath,
  }) async {
    try {
      await _remoteDataSource.delete(
        documentId: documentId,
        filePath: filePath,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
