import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/dashboard/data/datasources/dashboard_remote_datasource.dart'
    as data;
import 'package:lendflow/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:lendflow/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Concrete implementation of [DashboardRepository].
///
/// Delegates to [DashboardRemoteDataSource] for all network operations
/// and maps [AppException] subtypes to [Failure] subtypes.
class DashboardRepositoryImpl implements DashboardRepository {
  final data.DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl({
    required data.DashboardRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, DashboardData>> getAdminStats() async {
    try {
      final result = await _remoteDataSource.getAdminStats();
      return Right(DashboardData(
        stats: result.stats,
        recentActivity: result.recentActivity,
      ));
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
  Future<Either<Failure, DashboardData>> getManagerStats() async {
    try {
      final result = await _remoteDataSource.getManagerStats();
      return Right(DashboardData(
        stats: result.stats,
        recentActivity: result.recentActivity,
      ));
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
