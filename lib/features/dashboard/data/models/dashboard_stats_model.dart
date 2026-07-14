import 'package:lendflow/features/dashboard/domain/entities/dashboard_stats.dart';

/// Data-layer representation of [DashboardStats], with JSON serialization.
class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    super.totalLoans = 0,
    super.activeLoans = 0,
    super.totalDisbursed = 0.0,
    super.totalCollected = 0.0,
    super.overdueCount = 0,
    super.pendingApprovals = 0,
    super.todayCollections = 0.0,
    super.todayDisbursements = 0.0,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalLoans: json['total_loans'] as int? ?? json['totalLoans'] as int? ?? 0,
      activeLoans: json['active_loans'] as int? ?? json['activeLoans'] as int? ?? 0,
      totalDisbursed: _parseDouble(json['total_disbursed'] ?? json['totalDisbursed']),
      totalCollected: _parseDouble(json['total_collected'] ?? json['totalCollected']),
      overdueCount: json['overdue_count'] as int? ?? json['overdueCount'] as int? ?? 0,
      pendingApprovals: json['pending_approvals'] as int? ?? json['pendingApprovals'] as int? ?? 0,
      todayCollections: _parseDouble(json['today_collections'] ?? json['todayCollections']),
      todayDisbursements: _parseDouble(json['today_disbursements'] ?? json['todayDisbursements']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_loans': totalLoans,
      'active_loans': activeLoans,
      'total_disbursed': totalDisbursed,
      'total_collected': totalCollected,
      'overdue_count': overdueCount,
      'pending_approvals': pendingApprovals,
      'today_collections': todayCollections,
      'today_disbursements': todayDisbursements,
    };
  }

  static double _parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}

/// Data-layer representation of [RecentActivity], with JSON serialization.
class RecentActivityModel extends RecentActivity {
  const RecentActivityModel({
    required super.id,
    required super.type,
    required super.description,
    required super.userId,
    required super.createdAt,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
