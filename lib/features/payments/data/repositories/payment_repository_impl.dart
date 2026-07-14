// lib/features/payments/data/repositories/payment_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:jireta_loan/core/error/exceptions.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/features/payments/data/datasources/payment_remote_datasource.dart'
    hide PaymentListResult;
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';
import 'package:jireta_loan/features/payments/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;

  PaymentRepositoryImpl({required PaymentRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, Payment>> create({
    required String loanId,
    required double amount,
    required PaymentMethod method,
  }) async {
    try {
      final payment = await _remoteDataSource.create(
        loanId: loanId,
        amount: amount,
        method: method.toApiString(),
      );
      return Right(payment);
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
  Future<Either<Failure, PaymentListResult>> list({
    String? loanId,
    String? lenderId,
    String? status,
    String? method,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await _remoteDataSource.list(
        loanId: loanId,
        lenderId: lenderId,
        status: status,
        method: method,
        page: page,
        pageSize: pageSize,
      );
      return Right(PaymentListResult(
        payments: result.payments,
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
  Future<Either<Failure, PaymentListResult>> getByLoanId(
    String loanId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result =
          await _remoteDataSource.getByLoanId(loanId, page: page, pageSize: pageSize);
      return Right(PaymentListResult(
        payments: result.payments,
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
  Future<Either<Failure, Payment>> detail(String paymentId) async {
    try {
      final payment = await _remoteDataSource.detail(paymentId);
      return Right(payment);
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
  Future<Either<Failure, Payment>> verify(String paymentId) async {
    try {
      final payment = await _remoteDataSource.verify(paymentId);
      return Right(payment);
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
  Future<Either<Failure, Payment>> reject(String paymentId, {String? reason}) async {
    try {
      final payment = await _remoteDataSource.reject(paymentId, reason: reason);
      return Right(payment);
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
