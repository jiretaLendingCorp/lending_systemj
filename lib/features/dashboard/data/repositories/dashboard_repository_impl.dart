// lib/features/dashboard/data/repositories/dashboard_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/dashboard/data/datasources/dashboard_remote_datasource.dart'
    as data;

import 'package:jireta_loan/features/dashboard/domain/repositories/dashboard_repository.dart';

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
  Future<Either<Failure, DashboardData>> getManagerStats() async {
    try {
      final result = await _remoteDataSource.getManagerStats();
      return Right(DashboardData(
        stats: result.stats,
        recentActivity: result.recentActivity,
      ));
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
