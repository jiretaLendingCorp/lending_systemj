import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:lendflow/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:lendflow/features/payments/domain/entities/payment.dart';
import 'package:lendflow/features/payments/domain/repositories/payment_repository.dart';
import 'package:lendflow/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:lendflow/features/payments/domain/usecases/get_payments_usecase.dart';

// ─────────────────────────────────────────────────────────────────
// Payment state model
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level payment state managed by [PaymentNotifier].
sealed class PaymentFeatureState {
  const PaymentFeatureState();
}

/// Initial state.
class PaymentInitial extends PaymentFeatureState {
  const PaymentInitial();
}

/// Payments are being loaded.
class PaymentsLoading extends PaymentFeatureState {
  const PaymentsLoading();
}

/// Creating a payment.
class PaymentCreating extends PaymentFeatureState {
  const PaymentCreating();
}

/// Payments loaded successfully.
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

  /// Whether there are more pages to load.
  bool get hasMore => payments.length < total;
}

/// Single payment detail loaded.
class PaymentDetailLoaded extends PaymentFeatureState {
  final Payment payment;

  const PaymentDetailLoaded({required this.payment});
}

/// Payment operation succeeded (create, verify, reject).
class PaymentOperationSuccess extends PaymentFeatureState {
  final Payment payment;
  final String message;

  const PaymentOperationSuccess({
    required this.payment,
    required this.message,
  });
}

/// An error occurred.
class PaymentError extends PaymentFeatureState {
  final String message;
  final Failure? failure;

  const PaymentError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [PaymentRemoteDataSource].
final paymentRemoteDataSourceProvider =
    Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Provides the [PaymentRepository] implementation.
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(
    remoteDataSource: ref.watch(paymentRemoteDataSourceProvider),
  );
});

/// Provides the [CreatePaymentUseCase].
final createPaymentUseCaseProvider = Provider<CreatePaymentUseCase>((ref) {
  return CreatePaymentUseCase(repository: ref.watch(paymentRepositoryProvider));
});

/// Provides the [GetPaymentsUseCase].
final getPaymentsUseCaseProvider = Provider<GetPaymentsUseCase>((ref) {
  return GetPaymentsUseCase(repository: ref.watch(paymentRepositoryProvider));
});

/// Provides the [PaymentNotifier] for payment feature screens.
final paymentFeatureProvider =
    StateNotifierProvider<PaymentNotifier, PaymentFeatureState>((ref) {
  return PaymentNotifier(
    createPaymentUseCase: ref.watch(createPaymentUseCaseProvider),
    getPaymentsUseCase: ref.watch(getPaymentsUseCaseProvider),
    repository: ref.watch(paymentRepositoryProvider),
  );
});

/// Provider for the current user's role (for role-based payment UI).
final paymentUserRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.role;
  }
  return null;
});

// ─────────────────────────────────────────────────────────────────
// Payment notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing payment feature UI state.
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

  /// Load payments with optional filters.
  Future<void> loadPayments({
    String? loanId,
    String? borrowerId,
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
        borrowerId: borrowerId,
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

  /// Load more payments (pagination).
  Future<void> loadMore({
    String? loanId,
    String? borrowerId,
  }) async {
    if (state is! PaymentsLoaded) return;
    final current = state as PaymentsLoaded;
    if (!current.hasMore) return;

    await loadPayments(
      loanId: loanId,
      borrowerId: borrowerId,
      status: current.activeStatusFilter,
      method: current.activeMethodFilter,
      page: current.currentPage + 1,
    );
  }

  /// Load a single payment's detail.
  Future<void> loadPaymentDetail(String paymentId) async {
    state = const PaymentsLoading();

    final result = await _repository.detail(paymentId);
    state = result.fold(
      (failure) => PaymentError(failure.message, failure: failure),
      (payment) => PaymentDetailLoaded(payment: payment),
    );
  }

  /// Create a new payment.
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

  /// Verify a payment (admin/manager).
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

  /// Reject a payment (admin/manager).
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

  /// Reset state to initial.
  void resetState() {
    state = const PaymentInitial();
  }
}
