import 'package:equatable/equatable.dart';

/// Loan schedule type: determines the payment frequency.
enum ScheduleType {
  daily,
  weekly,
  monthly;

  static ScheduleType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'daily' => ScheduleType.daily,
      'weekly' => ScheduleType.weekly,
      'monthly' => ScheduleType.monthly,
      _ => ScheduleType.monthly,
    };
  }

  String toApiString() => name;

  String get label => switch (this) {
        ScheduleType.daily => 'Daily',
        ScheduleType.weekly => 'Weekly',
        ScheduleType.monthly => 'Monthly',
      };

  /// Number of installments for a given term in days.
  int installmentCount(int termDays) {
    return switch (this) {
      ScheduleType.daily => termDays,
      ScheduleType.weekly => (termDays / 7).ceil(),
      ScheduleType.monthly => (termDays / 30).ceil(),
    };
  }
}

/// Loan status lifecycle:
///   draft → submitted → under_review → approved → disbursed → active → paid → closed
///                                                                ↘ defaulted → closed
///                                                                ↗ rejected
enum LoanStatus {
  draft,
  submitted,
  underReview,
  approved,
  disbursed,
  active,
  paid,
  defaulted,
  rejected,
  closed;

  static LoanStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'draft' => LoanStatus.draft,
      'submitted' => LoanStatus.submitted,
      'under_review' => LoanStatus.underReview,
      'approved' => LoanStatus.approved,
      'disbursed' => LoanStatus.disbursed,
      'active' => LoanStatus.active,
      'paid' => LoanStatus.paid,
      'defaulted' => LoanStatus.defaulted,
      'rejected' => LoanStatus.rejected,
      'closed' => LoanStatus.closed,
      _ => LoanStatus.draft,
    };
  }

  String toApiString() => switch (this) {
        LoanStatus.underReview => 'under_review',
        _ => name,
      };

  String get label => switch (this) {
        LoanStatus.draft => 'Draft',
        LoanStatus.submitted => 'Submitted',
        LoanStatus.underReview => 'Under Review',
        LoanStatus.approved => 'Approved',
        LoanStatus.disbursed => 'Disbursed',
        LoanStatus.active => 'Active',
        LoanStatus.paid => 'Paid',
        LoanStatus.defaulted => 'Defaulted',
        LoanStatus.rejected => 'Rejected',
        LoanStatus.closed => 'Closed',
      };

  /// Whether this status allows the loan to be edited by the borrower.
  bool get isEditable => this == LoanStatus.draft;

  /// Whether this status can be approved/rejected by a manager.
  bool get isApprovable => this == LoanStatus.underReview;

  /// Whether this status can be disbursed.
  bool get isDisbursable => this == LoanStatus.approved;

  /// Whether the loan is in a terminal (final) state.
  bool get isTerminal =>
      this == LoanStatus.paid ||
      this == LoanStatus.rejected ||
      this == LoanStatus.closed;

  /// Whether the loan is in an active/repayment state.
  bool get isActive =>
      this == LoanStatus.active ||
      this == LoanStatus.disbursed ||
      this == LoanStatus.defaulted;
}

/// Core loan entity representing a lending application.
///
/// This is the domain-level representation. Data-layer concerns
/// (JSON serialization) live in [LoanModel].
class Loan extends Equatable {
  final String id;
  final String borrowerId;
  final String? coMakerId;
  final double principal;
  final double interestRate;
  final double totalPayable;
  final int termDays;
  final ScheduleType scheduleType;
  final LoanStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? disbursedAt;
  final DateTime? dueAt;
  final double penaltyAmount;
  final double finalBalance;
  final DateTime createdAt;

  const Loan({
    required this.id,
    required this.borrowerId,
    this.coMakerId,
    required this.principal,
    this.interestRate = 0.20,
    required this.totalPayable,
    required this.termDays,
    this.scheduleType = ScheduleType.monthly,
    this.status = LoanStatus.draft,
    this.approvedBy,
    this.approvedAt,
    this.disbursedAt,
    this.dueAt,
    this.penaltyAmount = 0.0,
    this.finalBalance = 0.0,
    required this.createdAt,
  });

  /// The interest amount for this loan.
  double get interestAmount => principal * interestRate;

  /// The total amount paid so far.
  double get amountPaid => totalPayable + penaltyAmount - finalBalance;

  /// The remaining balance.
  double get outstandingBalance => finalBalance;

  /// Progress ratio (0.0 to 1.0) of repayment.
  double get repaymentProgress =>
      totalPayable > 0 ? (amountPaid / totalPayable).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [
        id,
        borrowerId,
        coMakerId,
        principal,
        interestRate,
        totalPayable,
        termDays,
        scheduleType,
        status,
        approvedBy,
        approvedAt,
        disbursedAt,
        dueAt,
        penaltyAmount,
        finalBalance,
        createdAt,
      ];
}
