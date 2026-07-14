// lib/features/loans/data/models/loan_model.dart
import 'package:jireta_loan/features/loans/domain/entities/loan.dart';

class LoanModel extends Loan {
  const LoanModel({
    required super.id,
    required super.lenderId,
    super.coMakerId,
    required super.principal,
    super.interestRate = 0.20,
    required super.totalPayable,
    required super.termDays,
    super.scheduleType = ScheduleType.monthly,
    super.status = LoanStatus.draft,
    super.approvedBy,
    super.approvedAt,
    super.disbursedAt,
    super.dueAt,
    super.penaltyAmount = 0.0,
    super.finalBalance = 0.0,
    required super.createdAt,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['id'] as String,
      lenderId: json['lender_id'] as String? ?? json['lenderId'] as String? ?? '',
      coMakerId: json['co_maker_id'] as String? ?? json['coMakerId'] as String?,
      principal: _parseDouble(json['principal']),
      interestRate: _parseDouble(json['interest_rate'] ?? json['interestRate'], fallback: 0.20),
      totalPayable: _parseDouble(json['total_payable'] ?? json['totalPayable']),
      termDays: json['term_days'] as int? ?? json['termDays'] as int? ?? 30,
      scheduleType: ScheduleType.fromString(
        json['schedule_type'] as String? ?? json['scheduleType'] as String?,
      ),
      status: LoanStatus.fromString(
        json['status'] as String?,
      ),
      approvedBy: json['approved_by'] as String? ?? json['approvedBy'] as String?,
      approvedAt: _parseDateTime(json['approved_at'] ?? json['approvedAt']),
      disbursedAt: _parseDateTime(json['disbursed_at'] ?? json['disbursedAt']),
      dueAt: _parseDateTime(json['due_at'] ?? json['dueAt']),
      penaltyAmount: _parseDouble(json['penalty_amount'] ?? json['penaltyAmount'], fallback: 0.0),
      finalBalance: _parseDouble(json['final_balance'] ?? json['finalBalance'], fallback: 0.0),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lender_id': lenderId,
      'co_maker_id': coMakerId,
      'principal': principal,
      'interest_rate': interestRate,
      'total_payable': totalPayable,
      'term_days': termDays,
      'schedule_type': scheduleType.toApiString(),
      'status': status.toApiString(),
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'disbursed_at': disbursedAt?.toIso8601String(),
      'due_at': dueAt?.toIso8601String(),
      'penalty_amount': penaltyAmount,
      'final_balance': finalBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LoanModel copyWith({
    String? id,
    String? lenderId,
    String? coMakerId,
    double? principal,
    double? interestRate,
    double? totalPayable,
    int? termDays,
    ScheduleType? scheduleType,
    LoanStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? disbursedAt,
    DateTime? dueAt,
    double? penaltyAmount,
    double? finalBalance,
    DateTime? createdAt,
  }) {
    return LoanModel(
      id: id ?? this.id,
      lenderId: lenderId ?? this.lenderId,
      coMakerId: coMakerId ?? this.coMakerId,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      totalPayable: totalPayable ?? this.totalPayable,
      termDays: termDays ?? this.termDays,
      scheduleType: scheduleType ?? this.scheduleType,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      dueAt: dueAt ?? this.dueAt,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      finalBalance: finalBalance ?? this.finalBalance,
      createdAt: createdAt ?? this.createdAt,
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
