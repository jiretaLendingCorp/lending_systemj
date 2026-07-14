// lib/features/loans/domain/entities/loan_schedule.dart
import 'package:equatable/equatable.dart';

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

  bool get isOverdue =>
      status != InstallmentStatus.paid &&
      dueDate.isBefore(DateTime.now());

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
