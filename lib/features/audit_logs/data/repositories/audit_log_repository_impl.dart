// lib/features/audit_logs/data/repositories/audit_log_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/audit_logs/data/datasources/audit_log_remote_datasource.dart'
    hide AuditLogListResult;
import 'package:jireta_loan/features/audit_logs/domain/entities/audit_log.dart';
import 'package:jireta_loan/features/audit_logs/domain/repositories/audit_log_repository.dart'
    as domain;

class AuditLogRepositoryImpl implements domain.AuditLogRepository {
  final AuditLogRemoteDataSource _remoteDataSource;

  AuditLogRepositoryImpl({required AuditLogRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, domain.AuditLogListResult>> list({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await _remoteDataSource.list(
        userId: userId,
        action: action,
        startDate: startDate,
        endDate: endDate,
        page: page,
        pageSize: pageSize,
      );
      return Right(domain.AuditLogListResult(
        logs: result.logs,
        total: result.total,
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
  Future<Either<Failure, AuditLog>> detail(String logId) async {
    try {
      final log = await _remoteDataSource.detail(logId);
      return Right(log);
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
  Future<Either<Failure, String>> export({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final url = await _remoteDataSource.export(
        userId: userId,
        action: action,
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
