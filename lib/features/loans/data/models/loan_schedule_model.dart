import 'package:lendflow/features/loans/domain/entities/loan_schedule.dart';

/// Data-layer representation of a [LoanSchedule], with JSON serialization.
class LoanScheduleModel extends LoanSchedule {
  const LoanScheduleModel({
    required super.id,
    required super.loanId,
    required super.installmentNumber,
    required super.amountDue,
    required super.dueDate,
    super.status = InstallmentStatus.pending,
  });

  factory LoanScheduleModel.fromJson(Map<String, dynamic> json) {
    return LoanScheduleModel(
      id: json['id'] as String,
      loanId: json['loan_id'] as String? ?? json['loanId'] as String? ?? '',
      installmentNumber:
          json['installment_number'] as int? ?? json['installmentNumber'] as int? ?? 0,
      amountDue: _parseDouble(json['amount_due'] ?? json['amountDue']),
      dueDate: _parseDateTime(json['due_date'] ?? json['dueDate']) ?? DateTime.now(),
      status: InstallmentStatus.fromString(
        json['status'] as String?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'installment_number': installmentNumber,
      'amount_due': amountDue,
      'due_date': dueDate.toIso8601String(),
      'status': status.toApiString(),
    };
  }

  LoanScheduleModel copyWith({
    String? id,
    String? loanId,
    int? installmentNumber,
    double? amountDue,
    DateTime? dueDate,
    InstallmentStatus? status,
  }) {
    return LoanScheduleModel(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amountDue: amountDue ?? this.amountDue,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }

  static double _parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
