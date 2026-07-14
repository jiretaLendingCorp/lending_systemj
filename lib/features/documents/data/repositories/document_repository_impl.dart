// lib/features/documents/data/repositories/document_repository_impl.dart
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/documents/data/datasources/document_remote_datasource.dart';
import 'package:jireta_loan/features/documents/domain/entities/kyc_document.dart';
import 'package:jireta_loan/features/documents/domain/repositories/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource _remoteDataSource;

  DocumentRepositoryImpl({required DocumentRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, KycDocument>> upload({
    required String lenderId,
    required String documentType,
    required String filePath,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final document = await _remoteDataSource.upload(
        lenderId: lenderId,
        documentType: documentType,
        file: File(filePath),
        fileName: fileName,
        onProgress: onProgress,
      );
      return Right(document);
    } on AppAuthException catch (e) {
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
    required String lenderId,
  }) async {
    try {
      final documents = await _remoteDataSource.list(
        lenderId: lenderId,
      );
      return Right(documents);
    } on AppAuthException catch (e) {
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
    } on AppAuthException catch (e) {
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
    } on AppAuthException catch (e) {
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
