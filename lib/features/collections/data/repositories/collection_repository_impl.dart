import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/collections/data/datasources/collection_remote_datasource.dart'
    hide CollectionListResult, RiderBrief;
import 'package:lendflow/features/collections/domain/entities/collection.dart';
import 'package:lendflow/features/collections/domain/repositories/collection_repository.dart';

/// Concrete implementation of [CollectionRepository].
///
/// Delegates to [CollectionRemoteDataSource] for all network operations
/// and maps [AppException] subtypes to [Failure] subtypes.
class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionRemoteDataSource _remoteDataSource;

  CollectionRepositoryImpl({
    required CollectionRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, CollectionListResult>> list({
    String? status,
    String? method,
    String? riderId,
    String? borrowerId,
    String? date,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await _remoteDataSource.list(
        status: status,
        method: method,
        riderId: riderId,
        borrowerId: borrowerId,
        date: date,
        page: page,
        pageSize: pageSize,
      );
      return Right(CollectionListResult(
        collections: result.collections,
        total: result.total,
      ));
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
  Future<Either<Failure, Collection>> detail(
    String collectionId,
  ) async {
    try {
      final collection =
          await _remoteDataSource.detail(collectionId);
      return Right(collection);
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
  Future<Either<Failure, Collection>> assignRider({
    required String collectionId,
    required String riderId,
  }) async {
    try {
      final collection = await _remoteDataSource.assignRider(
        collectionId: collectionId,
        riderId: riderId,
      );
      return Right(collection);
    } on AuthException catch (e) {
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
  Future<Either<Failure, Collection>> markCollected({
    required String collectionId,
    required double latitude,
    required double longitude,
    String? photoReceiptUrl,
  }) async {
    try {
      final collection = await _remoteDataSource.markCollected(
        collectionId: collectionId,
        latitude: latitude,
        longitude: longitude,
        photoReceiptUrl: photoReceiptUrl,
      );
      return Right(collection);
    } on AuthException catch (e) {
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
  Future<Either<Failure, Collection>> markPartial({
    required String collectionId,
    required double collectedAmount,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final collection = await _remoteDataSource.markPartial(
        collectionId: collectionId,
        collectedAmount: collectedAmount,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(collection);
    } on AuthException catch (e) {
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
  Future<Either<Failure, Collection>> markFailed(
    String collectionId, {
    String? reason,
  }) async {
    try {
      final collection = await _remoteDataSource.markFailed(
        collectionId,
        reason: reason,
      );
      return Right(collection);
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
  Future<Either<Failure, List<CollectionRiderInfo>>>
      getAvailableRiders() async {
    try {
      final riders = await _remoteDataSource.getAvailableRiders();
      return Right(riders
          .map((r) => CollectionRiderInfo(
                id: r.id,
                name: r.name,
                phone: r.phone,
                isAvailable: r.isAvailable,
                activeCollections: r.activeCollections,
              ))
          .toList());
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
