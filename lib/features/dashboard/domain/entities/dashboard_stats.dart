import 'package:equatable/equatable.dart';

/// Dashboard statistics entity.
///
/// Contains all KPIs displayed on admin and manager dashboards.
/// Manager dashboard is scoped to their own branch.
class DashboardStats extends Equatable {
  final int totalLoans;
  final int activeLoans;
  final double totalDisbursed;
  final double totalCollected;
  final int overdueCount;
  final int pendingApprovals;
  final double todayCollections;
  final double todayDisbursements;

  const DashboardStats({
    this.totalLoans = 0,
    this.activeLoans = 0,
    this.totalDisbursed = 0.0,
    this.totalCollected = 0.0,
    this.overdueCount = 0,
    this.pendingApprovals = 0,
    this.todayCollections = 0.0,
    this.todayDisbursements = 0.0,
  });

  /// Collection rate as percentage.
  double get collectionRate =>
      totalDisbursed > 0 ? (totalCollected / totalDisbursed) * 100 : 0.0;

  /// Outstanding balance.
  double get outstandingBalance => totalDisbursed - totalCollected;

  /// Overdue rate as percentage of active loans.
  double get overdueRate =>
      activeLoans > 0 ? (overdueCount / activeLoans) * 100 : 0.0;

  @override
  List<Object?> get props => [
        totalLoans,
        activeLoans,
        totalDisbursed,
        totalCollected,
        overdueCount,
        pendingApprovals,
        todayCollections,
        todayDisbursements,
      ];
}

/// Recent activity entry for the dashboard.
class RecentActivity extends Equatable {
  final String id;
  final String type;
  final String description;
  final String userId;
  final DateTime createdAt;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.userId,
    required this.createdAt,
  });

  /// Icon for the activity type.
  String get icon => switch (type) {
        'loan_created' => 'loan',
        'loan_approved' => 'approve',
        'loan_rejected' => 'reject',
        'payment_received' => 'payment',
        'disbursement' => 'disburse',
        'collection' => 'collect',
        'user_created' => 'user',
        _ => 'default',
      };

  @override
  List<Object?> get props => [id, type, description, userId, createdAt];
}
