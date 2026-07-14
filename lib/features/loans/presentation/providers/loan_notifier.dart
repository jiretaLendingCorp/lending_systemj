import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/error/failures.dart';
import 'package:lendflow/core/network/dio_client.dart';
import 'package:lendflow/core/utils/constants.dart';
import 'package:lendflow/features/loans/data/datasources/loan_remote_datasource.dart';
import 'package:lendflow/features/loans/data/repositories/loan_repository_impl.dart';
import 'package:lendflow/features/loans/domain/entities/loan.dart';
import 'package:lendflow/features/loans/domain/entities/loan_schedule.dart';
import 'package:lendflow/features/loans/domain/repositories/loan_repository.dart';
import 'package:lendflow/features/loans/domain/usecases/approve_loan_usecase.dart';
import 'package:lendflow/features/loans/domain/usecases/create_loan_usecase.dart';
import 'package:lendflow/features/loans/domain/usecases/get_loans_usecase.dart';
import 'package:lendflow/features/loans/domain/usecases/reject_loan_usecase.dart';

// ─────────────────────────────────────────────────────────────────
// Loan state model
// ─────────────────────────────────────────────────────────────────

/// Represents the feature-level loan state managed by [LoanNotifier].
sealed class LoanFeatureState {
  const LoanFeatureState();
}

/// Initial state.
class LoanInitial extends LoanFeatureState {
  const LoanInitial();
}

/// Loans are being loaded.
class LoansLoading extends LoanFeatureState {
  const LoansLoading();
}

/// Loans loaded successfully.
class LoansLoaded extends LoanFeatureState {
  final List<Loan> loans;
  final int total;
  final String? activeFilter;
  final int currentPage;

  const LoansLoaded({
    required this.loans,
    required this.total,
    this.activeFilter,
    this.currentPage = 1,
  });

  /// Whether there are more pages to load.
  bool get hasMore => loans.length < total;
}

/// Single loan detail loaded.
class LoanDetailLoaded extends LoanFeatureState {
  final Loan loan;
  final List<LoanSchedule> schedule;

  const LoanDetailLoaded({
    required this.loan,
    this.schedule = const [],
  });
}

/// Loan operation succeeded (create, approve, reject).
class LoanOperationSuccess extends LoanFeatureState {
  final Loan loan;
  final String message;

  const LoanOperationSuccess({
    required this.loan,
    required this.message,
  });
}

/// An error occurred.
class LoanError extends LoanFeatureState {
  final String message;
  final Failure? failure;

  const LoanError(this.message, {this.failure});
}

// ─────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────

/// Provides the [LoanRemoteDataSource].
final loanRemoteDataSourceProvider = Provider<LoanRemoteDataSource>((ref) {
  return LoanRemoteDataSource(dio: ref.watch(dioProvider));
});

/// Provides the [LoanRepository] implementation.
final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepositoryImpl(
    remoteDataSource: ref.watch(loanRemoteDataSourceProvider),
  );
});

/// Provides the [GetLoansUseCase].
final getLoansUseCaseProvider = Provider<GetLoansUseCase>((ref) {
  return GetLoansUseCase(repository: ref.watch(loanRepositoryProvider));
});

/// Provides the [CreateLoanUseCase].
final createLoanUseCaseProvider = Provider<CreateLoanUseCase>((ref) {
  return CreateLoanUseCase(repository: ref.watch(loanRepositoryProvider));
});

/// Provides the [ApproveLoanUseCase].
final approveLoanUseCaseProvider = Provider<ApproveLoanUseCase>((ref) {
  return ApproveLoanUseCase(repository: ref.watch(loanRepositoryProvider));
});

/// Provides the [RejectLoanUseCase].
final rejectLoanUseCaseProvider = Provider<RejectLoanUseCase>((ref) {
  return RejectLoanUseCase(repository: ref.watch(loanRepositoryProvider));
});

/// Provides the [LoanNotifier] for loan feature screens.
final loanFeatureProvider =
    StateNotifierProvider<LoanNotifier, LoanFeatureState>((ref) {
  return LoanNotifier(
    getLoansUseCase: ref.watch(getLoansUseCaseProvider),
    createLoanUseCase: ref.watch(createLoanUseCaseProvider),
    approveLoanUseCase: ref.watch(approveLoanUseCaseProvider),
    rejectLoanUseCase: ref.watch(rejectLoanUseCaseProvider),
    repository: ref.watch(loanRepositoryProvider),
  );
});

/// Provider for the current user's role (for role-based UI).
final loanUserRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.role;
  }
  return null;
});

/// Whether the current user can approve/reject loans.
final canApproveLoansProvider = Provider<bool>((ref) {
  final role = ref.watch(loanUserRoleProvider);
  return role == AppConstants.roleAdmin || role == AppConstants.roleManager;
});

// ─────────────────────────────────────────────────────────────────
// Loan notifier
// ─────────────────────────────────────────────────────────────────

/// Riverpod [StateNotifier] managing loan feature UI state.
class LoanNotifier extends StateNotifier<LoanFeatureState> {
  final GetLoansUseCase _getLoansUseCase;
  final CreateLoanUseCase _createLoanUseCase;
  final ApproveLoanUseCase _approveLoanUseCase;
  final RejectLoanUseCase _rejectLoanUseCase;
  final LoanRepository _repository;

  LoanNotifier({
    required GetLoansUseCase getLoansUseCase,
    required CreateLoanUseCase createLoanUseCase,
    required ApproveLoanUseCase approveLoanUseCase,
    required RejectLoanUseCase rejectLoanUseCase,
    required LoanRepository repository,
  })  : _getLoansUseCase = getLoansUseCase,
        _createLoanUseCase = createLoanUseCase,
        _approveLoanUseCase = approveLoanUseCase,
        _rejectLoanUseCase = rejectLoanUseCase,
        _repository = repository,
        super(const LoanInitial());

  /// Load loans with optional status filter.
  Future<void> loadLoans({
    String? status,
    int page = 1,
    String? search,
  }) async {
    if (page == 1) {
      state = const LoansLoading();
    }

    final result = await _getLoansUseCase(
      GetLoansParams(
        status: status,
        page: page,
        search: search,
      ),
    );

    state = result.fold(
      (failure) => LoanError(failure.message, failure: failure),
      (loanListResult) {
        final existingLoans = state is LoansLoaded && page > 1
            ? (state as LoansLoaded).loans
            : <Loan>[];
        return LoansLoaded(
          loans: [...existingLoans, ...loanListResult.loans],
          total: loanListResult.total,
          activeFilter: status,
          currentPage: page,
        );
      },
    );
  }

  /// Load more loans (pagination).
  Future<void> loadMore({String? search}) async {
    if (state is! LoansLoaded) return;
    final current = state as LoansLoaded;
    if (!current.hasMore) return;

    await loadLoans(
      status: current.activeFilter,
      page: current.currentPage + 1,
      search: search,
    );
  }

  /// Load a single loan's detail and schedule.
  Future<void> loadLoanDetail(String loanId) async {
    state = const LoansLoading();

    final detailResult = await _repository.detail(loanId);
    final result = detailResult.fold(
      (failure) => LoanError(failure.message, failure: failure),
      (loan) => loan,
    );

    if (result is LoanError) {
      state = result;
      return;
    }

    final scheduleResult = await _repository.schedule(loanId);
    scheduleResult.fold(
      (failure) {
        // Schedule load failure is non-fatal — show loan detail without schedule
        state = LoanDetailLoaded(loan: result as Loan);
      },
      (schedule) {
        state = LoanDetailLoaded(
          loan: result as Loan,
          schedule: schedule,
        );
      },
    );
  }

  /// Create a new loan application.
  Future<void> createLoan({
    required double principal,
    required int termDays,
    required ScheduleType scheduleType,
    required String coMakerFullName,
    required String coMakerPhone,
    required String coMakerAddress,
    required String coMakerRelationship,
  }) async {
    state = const LoansLoading();

    final result = await _createLoanUseCase(
      CreateLoanParams(
        principal: principal,
        termDays: termDays,
        scheduleType: scheduleType,
        coMakerFullName: coMakerFullName,
        coMakerPhone: coMakerPhone,
        coMakerAddress: coMakerAddress,
        coMakerRelationship: coMakerRelationship,
      ),
    );

    state = result.fold(
      (failure) => LoanError(failure.message, failure: failure),
      (loan) => LoanOperationSuccess(
        loan: loan,
        message: 'Loan application submitted successfully.',
      ),
    );
  }

  /// Approve a loan.
  Future<void> approveLoan(String loanId) async {
    final result = await _approveLoanUseCase(
      ApproveLoanParams(loanId: loanId),
    );

    state = result.fold(
      (failure) => LoanError(failure.message, failure: failure),
      (loan) => LoanOperationSuccess(
        loan: loan,
        message: 'Loan approved successfully.',
      ),
    );
  }

  /// Reject a loan.
  Future<void> rejectLoan(String loanId, {String? reason}) async {
    final result = await _rejectLoanUseCase(
      RejectLoanParams(loanId: loanId, reason: reason),
    );

    state = result.fold(
      (failure) => LoanError(failure.message, failure: failure),
      (loan) => LoanOperationSuccess(
        loan: loan,
        message: 'Loan rejected.',
      ),
    );
  }

  /// Compute penalty for an overdue loan.
  Future<void> computePenalty(String loanId) async {
    final result = await _repository.computePenalty(loanId);
    state = result.fold(
      (failure) => LoanError(failure.message, failure: failure),
      (loan) {
        if (state is LoanDetailLoaded) {
          return LoanDetailLoaded(
            loan: loan,
            schedule: (state as LoanDetailLoaded).schedule,
          );
        }
        return LoanOperationSuccess(
          loan: loan,
          message: 'Penalty computed.',
        );
      },
    );
  }

  /// Reset state to initial.
  void resetState() {
    state = const LoanInitial();
  }
}
