// lib/features/loans/presentation/providers/loan_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/error/failures.dart';
import 'package:jireta_loan/core/network/dio_client.dart';
import 'package:jireta_loan/core/utils/constants.dart';
import 'package:jireta_loan/features/loans/data/datasources/loan_remote_datasource.dart';
import 'package:jireta_loan/features/loans/data/repositories/loan_repository_impl.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';
import 'package:jireta_loan/features/loans/domain/entities/loan_schedule.dart';
import 'package:jireta_loan/features/loans/domain/repositories/loan_repository.dart';
import 'package:jireta_loan/features/loans/domain/usecases/approve_loan_usecase.dart';
import 'package:jireta_loan/features/loans/domain/usecases/create_loan_usecase.dart';
import 'package:jireta_loan/features/loans/domain/usecases/get_loans_usecase.dart';
import 'package:jireta_loan/features/loans/domain/usecases/reject_loan_usecase.dart';

sealed class LoanFeatureState {
  const LoanFeatureState();
}

class LoanInitial extends LoanFeatureState {
  const LoanInitial();
}

class LoansLoading extends LoanFeatureState {
  const LoansLoading();
}

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

  bool get hasMore => loans.length < total;
}

class LoanDetailLoaded extends LoanFeatureState {
  final Loan loan;
  final List<LoanSchedule> schedule;

  const LoanDetailLoaded({
    required this.loan,
    this.schedule = const [],
  });
}

class LoanOperationSuccess extends LoanFeatureState {
  final Loan loan;
  final String message;

  const LoanOperationSuccess({
    required this.loan,
    required this.message,
  });
}

class LoanError extends LoanFeatureState {
  final String message;
  final Failure? failure;

  const LoanError(this.message, {this.failure});
}

final loanRemoteDataSourceProvider = Provider<LoanRemoteDataSource>((ref) {
  return LoanRemoteDataSource(dio: ref.watch(dioProvider));
});

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepositoryImpl(
    remoteDataSource: ref.watch(loanRemoteDataSourceProvider),
  );
});

final getLoansUseCaseProvider = Provider<GetLoansUseCase>((ref) {
  return GetLoansUseCase(repository: ref.watch(loanRepositoryProvider));
});

final createLoanUseCaseProvider = Provider<CreateLoanUseCase>((ref) {
  return CreateLoanUseCase(repository: ref.watch(loanRepositoryProvider));
});

final approveLoanUseCaseProvider = Provider<ApproveLoanUseCase>((ref) {
  return ApproveLoanUseCase(repository: ref.watch(loanRepositoryProvider));
});

final rejectLoanUseCaseProvider = Provider<RejectLoanUseCase>((ref) {
  return RejectLoanUseCase(repository: ref.watch(loanRepositoryProvider));
});

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

final loanUserRoleProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AppAuthAuthenticated) {
    return authState.role;
  }
  return null;
});

final canApproveLoansProvider = Provider<bool>((ref) {
  final role = ref.watch(loanUserRoleProvider);
  return role == AppConstants.roleHeadManager || role == AppConstants.roleEmployee;
});

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

  void resetState() {
    state = const LoanInitial();
  }
}
