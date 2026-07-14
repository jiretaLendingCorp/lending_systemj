import 'package:dartz/dartz.dart';
import 'package:lendflow/core/error/exceptions.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/features/loans/data/datasources/loan_remote_datasource.dart' hide LoanListResult;
import 'package:lendflow/features/loans/data/models/create_loan_request.dart';
import 'package:lendflow/features/loans/domain/entities/loan.dart';
import 'package:lendflow/features/loans/domain/entities/loan_schedule.dart';
import 'package:lendflow/features/loans/domain/repositories/loan_repository.dart';

/// Concrete implementation of [LoanRepository].
///
/// Delegates to [LoanRemoteDataSource] for all network operations
/// and maps [AppException] subtypes to [Failure] subtypes.
class LoanRepositoryImpl implements LoanRepository {
  final LoanRemoteDataSource _remoteDataSource;

  LoanRepositoryImpl({required LoanRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, LoanListResult>> list({
    String? status,
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final result = await _remoteDataSource.list(
        status: status,
        page: page,
        pageSize: pageSize,
        search: search,
      );
      return Right(LoanListResult(
        loans: result.loans,
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
  Future<Either<Failure, Loan>> create({
    required double principal,
    required int termDays,
    required ScheduleType scheduleType,
    required String coMakerFullName,
    required String coMakerPhone,
    required String coMakerAddress,
    required String coMakerRelationship,
  }) async {
    try {
      final request = CreateLoanRequest(
        principal: principal,
        termDays: termDays,
        scheduleType: scheduleType,
        coMakerFullName: coMakerFullName,
        coMakerPhone: coMakerPhone,
        coMakerAddress: coMakerAddress,
        coMakerRelationship: coMakerRelationship,
      );
      final loan = await _remoteDataSource.create(request);
      return Right(loan);
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
  Future<Either<Failure, Loan>> detail(String loanId) async {
    try {
      final loan = await _remoteDataSource.detail(loanId);
      return Right(loan);
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
  Future<Either<Failure, List<LoanSchedule>>> schedule(String loanId) async {
    try {
      final schedules = await _remoteDataSource.schedule(loanId);
      return Right(schedules);
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
  Future<Either<Failure, Loan>> approve(String loanId) async {
    try {
      final loan = await _remoteDataSource.approve(loanId);
      return Right(loan);
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
  Future<Either<Failure, Loan>> reject(String loanId, {String? reason}) async {
    try {
      final loan = await _remoteDataSource.reject(loanId, reason: reason);
      return Right(loan);
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
  Future<Either<Failure, Loan>> computePenalty(String loanId) async {
    try {
      final loan = await _remoteDataSource.computePenalty(loanId);
      return Right(loan);
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
