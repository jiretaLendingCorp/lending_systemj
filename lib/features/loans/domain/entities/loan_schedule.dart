import 'package:equatable/equatable.dart';

/// Installment status for a loan schedule entry.
enum InstallmentStatus {
  pending,
  paid,
  overdue;

  static InstallmentStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'paid' => InstallmentStatus.paid,
      'overdue' => InstallmentStatus.overdue,
      _ => InstallmentStatus.pending,
    };
  }

  String toApiString() => name;

  String get label => switch (this) {
        InstallmentStatus.pending => 'Pending',
        InstallmentStatus.paid => 'Paid',
        InstallmentStatus.overdue => 'Overdue',
      };
}

/// A single installment in a loan's repayment schedule.
///
/// Each [LoanSchedule] entry represents one payment due date
/// with its amount and current status.
class LoanSchedule extends Equatable {
  final String id;
  final String loanId;
  final int installmentNumber;
  final double amountDue;
  final DateTime dueDate;
  final InstallmentStatus status;

  const LoanSchedule({
    required this.id,
    required this.loanId,
    required this.installmentNumber,
    required this.amountDue,
    required this.dueDate,
    this.status = InstallmentStatus.pending,
  });

  /// Whether this installment is past due but not yet paid.
  bool get isOverdue =>
      status != InstallmentStatus.paid &&
      dueDate.isBefore(DateTime.now());

  /// Whether this installment has been paid.
  bool get isPaid => status == InstallmentStatus.paid;

  @override
  List<Object?> get props => [
        id,
        loanId,
        installmentNumber,
        amountDue,
        dueDate,
        status,
      ];
}
