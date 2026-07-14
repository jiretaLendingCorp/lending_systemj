// lib/features/payments/presentation/providers/payment_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:jireta_loan/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:jireta_loan/features/payments/domain/entities/payment.dart';
import 'package:jireta_loan/features/payments/domain/repositories/payment_repository.dart';
import 'package:jireta_loan/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:jireta_loan/features/payments/domain/usecases/get_payments_usecase.dart';


sealed class PaymentFeatureState {
  const PaymentFeatureState();
}

class PaymentInitial extends PaymentFeatureState {
  const PaymentInitial();
}

class PaymentsLoading extends PaymentFeatureState {
  const PaymentsLoading();
}

class PaymentCreating extends PaymentFeatureState {
  const PaymentCreating();
}

class PaymentsLoaded extends PaymentFeatureState {
  final List<Payment> payments;
  final int total;
  final String? activeStatusFilter;
  final String? activeMethodFilter;
  final int currentPage;

  const PaymentsLoaded({
    required this.payments,
    required this.total,
    this.activeStatusFilter,
    this.activeMethodFilter,
    this.currentPage = 1,
  });

  bool get hasMore => payments.length < total;
}

class PaymentDetailLoaded extends PaymentFeatureState {
  final Payment payment;

  const PaymentDetailLoaded({required this.payment});
}

class PaymentOperationSuccess extends PaymentFeatureState {
  final Payment payment;
  final String message;

  const PaymentOperationSuccess({
    required this.payment,
    required this.message,
  });
}

class PaymentError extends PaymentFeatureState {
  final String message;
  final Failure? failure;

  const PaymentError(this.message, {this.failure});
}


final paymentRemoteDataSourceProvider =
    Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSource(dio: ref.watch(dioProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    remoteDataSource: ref.watch(paymentRemoteDataSourceProvider),
  );
});

final createPaymentUseCaseProvider = Provider<CreatePaymentUseCase>((ref) {
  return CreatePaymentUseCase(repository: ref.watch(paymentRepositoryProvider));
});

final getPaymentsUseCaseProvider = Provider<GetPaymentsUseCase>((ref) {
  return GetPaymentsUseCase(repository: ref.watch(paymentRepositoryProvider));
});

final paymentFeatureProvider =
    StateNotifierProvider<PaymentNotifier, PaymentFeatureState>((ref) {
  return PaymentNotifier(
    createPaymentUseCase: ref.watch(createPaymentUseCaseProvider),
    getPaymentsUseCase: ref.watch(getPaymentsUseCaseProvider),
    repository: ref.watch(paymentRepositoryProvider),
  );
});

final paymentUserRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AppAuthAuthenticated) {
    return authState.role;
  }
  return null;
});


class PaymentNotifier extends StateNotifier<PaymentFeatureState> {
  final CreatePaymentUseCase _createPaymentUseCase;
  final GetPaymentsUseCase _getPaymentsUseCase;
  final PaymentRepository _repository;

  PaymentNotifier({
    required CreatePaymentUseCase createPaymentUseCase,
    required GetPaymentsUseCase getPaymentsUseCase,
    required PaymentRepository repository,
  })  : _createPaymentUseCase = createPaymentUseCase,
        _getPaymentsUseCase = getPaymentsUseCase,
        _repository = repository,
        super(const PaymentInitial());

  Future<void> loadPayments({
    String? loanId,
    String? lenderId,
    String? status,
    String? method,
    int page = 1,
  }) async {
    if (page == 1) {
      state = const PaymentsLoading();
    }

    final result = await _getPaymentsUseCase(
      GetPaymentsParams(
        loanId: loanId,
        lenderId: lenderId,
        status: status,
        method: method,
        page: page,
      ),
    );

    state = result.fold(
      (failure) => PaymentError(failure.message, failure: failure),
      (paymentListResult) {
        final existingPayments =
            state is PaymentsLoaded && page > 1
                ? (state as PaymentsLoaded).payments
                : <Payment>[];
        return PaymentsLoaded(
          payments: [...existingPayments, ...paymentListResult.payments],
          total: paymentListResult.total,
          activeStatusFilter: status,
          activeMethodFilter: method,
          currentPage: page,
        );
      },
    );
  }

  Future<void> loadMore({
    String? loanId,
    String? lenderId,
  }) async {
    if (state is! PaymentsLoaded) return;
    final current = state as PaymentsLoaded;
    if (!current.hasMore) return;

    await loadPayments(
      loanId: loanId,
      lenderId: lenderId,
      status: current.activeStatusFilter,
      method: current.activeMethodFilter,
      page: current.currentPage + 1,
    );
  }

  Future<void> loadPaymentDetail(String paymentId) async {
    state = const PaymentsLoading();

    final result = await _repository.detail(paymentId);
    state = result.fold(
      (failure) => PaymentError(failure.message, failure: failure),
      (payment) => PaymentDetailLoaded(payment: payment),
    );
  }

  Future<void> createPayment({
    required String loanId,
    required double amount,
    required PaymentMethod method,
  }) async {
    state = const PaymentCreating();

    final result = await _createPaymentUseCase(
      CreatePaymentParams(
        loanId: loanId,
        amount: amount,
        method: method,
      ),
    );

    state = result.fold(
      (failure) => PaymentError(failure.message, failure: failure),
      (payment) => PaymentOperationSuccess(
        payment: payment,
        message: method == PaymentMethod.gcash
            ? 'GCash payment initiated. Please complete the transaction.'
            : method == PaymentMethod.office
                ? 'Office payment recorded successfully.'
                : 'Cash collection requested. A rider will be assigned.',
      ),
    );
  }

  Future<void> verifyPayment(String paymentId) async {
    final result = await _repository.verify(paymentId);
    state = result.fold(
      (failure) => PaymentError(failure.message, failure: failure),
      (payment) => PaymentOperationSuccess(
        payment: payment,
        message: 'Payment verified successfully.',
      ),
    );
  }

  Future<void> rejectPayment(String paymentId, {String? reason}) async {
    final result = await _repository.reject(paymentId, reason: reason);
    state = result.fold(
      (failure) => PaymentError(failure.message, failure: failure),
      (payment) => PaymentOperationSuccess(
        payment: payment,
        message: 'Payment rejected.',
      ),
    );
  }

  void resetState() {
    state = const PaymentInitial();
  }
}
