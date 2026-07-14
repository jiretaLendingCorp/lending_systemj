// lib/features/reports/data/models/report_models.dart
import 'package:jireta_loan/features/reports/domain/entities/report_data.dart';

class PortfolioReportModel extends PortfolioReport {
  PortfolioReportModel({
    super.totalDisbursed = 0.0,
    super.totalOutstanding = 0.0,
    super.totalCollected = 0.0,
    super.totalInterestEarned = 0.0,
    super.totalLoans = 0,
    super.activeLoans = 0,
    super.paidLoans = 0,
    super.overdueLoans = 0,
    super.pendingLoans = 0,
    super.generatedAt,
  });

  factory PortfolioReportModel.fromJson(Map<String, dynamic> json) {
    return PortfolioReportModel(
      totalDisbursed: _parseDouble(json['total_disbursed'] ?? json['totalDisbursed']),
      totalOutstanding: _parseDouble(json['total_outstanding'] ?? json['totalOutstanding']),
      totalCollected: _parseDouble(json['total_collected'] ?? json['totalCollected']),
      totalInterestEarned: _parseDouble(json['total_interest_earned'] ?? json['totalInterestEarned']),
      totalLoans: json['total_loans'] as int? ?? json['totalLoans'] as int? ?? 0,
      activeLoans: json['active_loans'] as int? ?? json['activeLoans'] as int? ?? 0,
      paidLoans: json['paid_loans'] as int? ?? json['paidLoans'] as int? ?? 0,
      overdueLoans: json['overdue_loans'] as int? ?? json['overdueLoans'] as int? ?? 0,
      pendingLoans: json['pending_loans'] as int? ?? json['pendingLoans'] as int? ?? 0,
      generatedAt: _parseDateTime(json['generated_at'] ?? json['generatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_disbursed': totalDisbursed,
      'total_outstanding': totalOutstanding,
      'total_collected': totalCollected,
      'total_interest_earned': totalInterestEarned,
      'total_loans': totalLoans,
      'active_loans': activeLoans,
      'paid_loans': paidLoans,
      'overdue_loans': overdueLoans,
      'pending_loans': pendingLoans,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

class OverdueReportModel extends OverdueReport {
  OverdueReportModel({
    super.days1to7 = 0,
    super.days8to30 = 0,
    super.days30Plus = 0,
    super.amount1to7 = 0.0,
    super.amount8to30 = 0.0,
    super.amount30Plus = 0.0,
    super.overdueLenders = const [],
    super.generatedAt,
  });

  factory OverdueReportModel.fromJson(Map<String, dynamic> json) {
    return OverdueReportModel(
      days1to7: json['days_1_to_7'] as int? ?? json['days1to7'] as int? ?? 0,
      days8to30: json['days_8_to_30'] as int? ?? json['days8to30'] as int? ?? 0,
      days30Plus: json['days_30_plus'] as int? ?? json['days30Plus'] as int? ?? 0,
      amount1to7: _parseDouble(json['amount_1_to_7'] ?? json['amount1to7']),
      amount8to30: _parseDouble(json['amount_8_to_30'] ?? json['amount8to30']),
      amount30Plus: _parseDouble(json['amount_30_plus'] ?? json['amount30Plus']),
      overdueLenders: (json['overdue_lenders'] as List<dynamic>? ?? [])
          .map((e) => OverdueBorrowerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: _parseDateTime(json['generated_at'] ?? json['generatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days_1_to_7': days1to7,
      'days_8_to_30': days8to30,
      'days_30_plus': days30Plus,
      'amount_1_to_7': amount1to7,
      'amount_8_to_30': amount8to30,
      'amount_30_plus': amount30Plus,
      'overdue_lenders': overdueLenders
          .map((e) => (e as OverdueBorrowerModel).toJson())
          .toList(),
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

class OverdueBorrowerModel extends OverdueLender {
  const OverdueBorrowerModel({
    required super.lenderId,
    required super.lenderName,
    required super.loanId,
    required super.overdueAmount,
    required super.daysOverdue,
    required super.dueDate,
  });

  factory OverdueBorrowerModel.fromJson(Map<String, dynamic> json) {
    return OverdueBorrowerModel(
      lenderId: json['lender_id'] as String? ?? json['lenderId'] as String? ?? '',
      lenderName: json['lender_name'] as String? ?? json['lenderName'] as String? ?? '',
      loanId: json['loan_id'] as String? ?? json['loanId'] as String? ?? '',
      overdueAmount: _parseDouble(json['overdue_amount'] ?? json['overdueAmount']),
      daysOverdue: json['days_overdue'] as int? ?? json['daysOverdue'] as int? ?? 0,
      dueDate: _parseDateTime(json['due_date'] ?? json['dueDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lender_id': lenderId,
      'lender_name': lenderName,
      'loan_id': loanId,
      'overdue_amount': overdueAmount,
      'days_overdue': daysOverdue,
      'due_date': dueDate.toIso8601String(),
    };
  }
}

class CollectionEfficiencyReportModel extends CollectionEfficiencyReport {
  CollectionEfficiencyReportModel({
    super.totalExpected = 0.0,
    super.totalCollected = 0.0,
    super.totalPartial = 0.0,
    super.totalFailed = 0.0,
    super.efficiencyRate = 0.0,
    super.totalAttempts = 0,
    super.successfulAttempts = 0,
    super.failedAttempts = 0,
    super.averageCollectionTimeHours = 0.0,
    super.generatedAt,
  });

  factory CollectionEfficiencyReportModel.fromJson(Map<String, dynamic> json) {
    return CollectionEfficiencyReportModel(
      totalExpected: _parseDouble(json['total_expected'] ?? json['totalExpected']),
      totalCollected: _parseDouble(json['total_collected'] ?? json['totalCollected']),
      totalPartial: _parseDouble(json['total_partial'] ?? json['totalPartial']),
      totalFailed: _parseDouble(json['total_failed'] ?? json['totalFailed']),
      efficiencyRate: _parseDouble(json['efficiency_rate'] ?? json['efficiencyRate']),
      totalAttempts: json['total_attempts'] as int? ?? json['totalAttempts'] as int? ?? 0,
      successfulAttempts: json['successful_attempts'] as int? ?? json['successfulAttempts'] as int? ?? 0,
      failedAttempts: json['failed_attempts'] as int? ?? json['failedAttempts'] as int? ?? 0,
      averageCollectionTimeHours: _parseDouble(
        json['average_collection_time_hours'] ?? json['averageCollectionTimeHours'],
      ),
      generatedAt: _parseDateTime(json['generated_at'] ?? json['generatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_expected': totalExpected,
      'total_collected': totalCollected,
      'total_partial': totalPartial,
      'total_failed': totalFailed,
      'efficiency_rate': efficiencyRate,
      'total_attempts': totalAttempts,
      'successful_attempts': successfulAttempts,
      'failed_attempts': failedAttempts,
      'average_collection_time_hours': averageCollectionTimeHours,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}


double _parseDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
