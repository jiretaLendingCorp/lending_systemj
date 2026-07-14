// lib/features/loans/domain/entities/loan.dart
import 'package:equatable/equatable.dart';

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

  int installmentCount(int termDays) {
    return switch (this) {
      ScheduleType.daily => termDays,
      ScheduleType.weekly => (termDays / 7).floor() < 1 ? 1 : (termDays / 7).floor(),
      ScheduleType.monthly => (termDays / 30).floor() < 1 ? 1 : (termDays / 30).floor(),
    };
  }
}

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

  bool get isEditable => this == LoanStatus.draft;

  bool get isApprovable => this == LoanStatus.underReview;

  bool get isDisbursable => this == LoanStatus.approved;

  bool get isTerminal =>
      this == LoanStatus.paid ||
      this == LoanStatus.rejected ||
      this == LoanStatus.closed;

  bool get isActive =>
      this == LoanStatus.active ||
      this == LoanStatus.disbursed ||
      this == LoanStatus.defaulted;
}

class Loan extends Equatable {
  final String id;
  final String lenderId;
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
    required this.lenderId,
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

  double get interestAmount => principal * interestRate;

  double get amountPaid => totalPayable + penaltyAmount - finalBalance;

  double get outstandingBalance => finalBalance;

  double get repaymentProgress =>
      totalPayable > 0 ? (amountPaid / totalPayable).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [
        id,
        lenderId,
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
