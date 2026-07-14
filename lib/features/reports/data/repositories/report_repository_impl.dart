// lib/features/reports/data/repositories/report_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/reports/data/datasources/report_remote_datasource.dart';
import 'package:jireta_loan/features/reports/domain/entities/report_data.dart';
import 'package:jireta_loan/features/reports/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;

  ReportRepositoryImpl({required ReportRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, PortfolioReport>> getPortfolio({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final report = await _remoteDataSource.getPortfolio(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(report);
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
  Future<Either<Failure, OverdueReport>> getOverdue({
    DateTime? asOfDate,
  }) async {
    try {
      final report = await _remoteDataSource.getOverdue(asOfDate: asOfDate);
      return Right(report);
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
  Future<Either<Failure, CollectionEfficiencyReport>> getCollectionEfficiency({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final report = await _remoteDataSource.getCollectionEfficiency(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(report);
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
  Future<Either<Failure, String>> exportReport({
    required String reportType,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final url = await _remoteDataSource.exportReport(
        reportType: reportType,
        format: format,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(url);
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
