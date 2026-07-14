// lib/features/disbursements/data/repositories/disbursement_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/disbursements/data/datasources/disbursement_remote_datasource.dart'
    hide DisbursementListResult, RiderInfo;
import 'package:jireta_loan/features/disbursements/domain/entities/disbursement.dart';
import 'package:jireta_loan/features/disbursements/domain/repositories/disbursement_repository.dart';

class DisbursementRepositoryImpl implements DisbursementRepository {
  final DisbursementRemoteDataSource _remoteDataSource;

  DisbursementRepositoryImpl({
    required DisbursementRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, DisbursementListResult>> list({
    String? status,
    String? method,
    String? riderId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await _remoteDataSource.list(
        status: status,
        method: method,
        riderId: riderId,
        page: page,
        pageSize: pageSize,
      );
      return Right(DisbursementListResult(
        disbursements: result.disbursements,
        total: result.total,
      ));
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
  Future<Either<Failure, Disbursement>> detail(
    String disbursementId,
  ) async {
    try {
      final disbursement =
          await _remoteDataSource.detail(disbursementId);
      return Right(disbursement);
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
  Future<Either<Failure, Disbursement>> assignRider({
    required String disbursementId,
    required String riderId,
  }) async {
    try {
      final disbursement = await _remoteDataSource.assignRider(
        disbursementId: disbursementId,
        riderId: riderId,
      );
      return Right(disbursement);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
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
  Future<Either<Failure, Disbursement>> markDelivered({
    required String disbursementId,
    required double latitude,
    required double longitude,
    String? receiptPhotoUrl,
  }) async {
    try {
      final disbursement = await _remoteDataSource.markDelivered(
        disbursementId: disbursementId,
        latitude: latitude,
        longitude: longitude,
        receiptPhotoUrl: receiptPhotoUrl,
      );
      return Right(disbursement);
    } on AppAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        requiresReAuth: e.requiresReAuth,
      ));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
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
  Future<Either<Failure, Disbursement>> markInTransit(
    String disbursementId,
  ) async {
    try {
      final disbursement =
          await _remoteDataSource.markInTransit(disbursementId);
      return Right(disbursement);
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
  Future<Either<Failure, Disbursement>> markFailed(
    String disbursementId, {
    String? reason,
  }) async {
    try {
      final disbursement =
          await _remoteDataSource.markFailed(disbursementId, reason: reason);
      return Right(disbursement);
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
  Future<Either<Failure, List<RiderInfo>>> getAvailableRiders() async {
    try {
      final riders = await _remoteDataSource.getAvailableRiders();
      return Right(riders
          .map((r) => RiderInfo(
                id: r.id,
                name: r.name,
                phone: r.phone,
                isAvailable: r.isAvailable,
                activeDeliveries: r.activeDeliveries,
              ))
          .toList());
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
