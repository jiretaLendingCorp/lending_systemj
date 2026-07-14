import 'package:equatable/equatable.dart';

/// Portfolio report entity.
///
/// Summary of the loan portfolio including total disbursed,
/// outstanding, collected, and loan counts by status.
class PortfolioReport extends Equatable {
  final double totalDisbursed;
  final double totalOutstanding;
  final double totalCollected;
  final double totalInterestEarned;
  final int totalLoans;
  final int activeLoans;
  final int paidLoans;
  final int overdueLoans;
  final int pendingLoans;
  final DateTime generatedAt;

  const PortfolioReport({
    this.totalDisbursed = 0.0,
    this.totalOutstanding = 0.0,
    this.totalCollected = 0.0,
    this.totalInterestEarned = 0.0,
    this.totalLoans = 0,
    this.activeLoans = 0,
    this.paidLoans = 0,
    this.overdueLoans = 0,
    this.pendingLoans = 0,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? _defaultDate;

  static final _defaultDate = DateTime.now();

  /// Collection rate as a percentage (0.0 to 100.0).
  double get collectionRate =>
      totalDisbursed > 0 ? (totalCollected / totalDisbursed) * 100 : 0.0;

  /// Overdue rate as a percentage.
  double get overdueRate =>
      totalLoans > 0 ? (overdueLoans / totalLoans) * 100 : 0.0;

  @override
  List<Object?> get props => [
        totalDisbursed,
        totalOutstanding,
        totalCollected,
        totalInterestEarned,
        totalLoans,
        activeLoans,
        paidLoans,
        overdueLoans,
        pendingLoans,
        generatedAt,
      ];
}

/// Overdue report entity with aging buckets.
///
/// Groups overdue loans into aging buckets and includes
/// a list of overdue borrowers.
class OverdueReport extends Equatable {
  final int days1to7;
  final int days8to30;
  final int days30Plus;
  final double amount1to7;
  final double amount8to30;
  final double amount30Plus;
  final List<OverdueBorrower> overdueBorrowers;
  final DateTime generatedAt;

  const OverdueReport({
    this.days1to7 = 0,
    this.days8to30 = 0,
    this.days30Plus = 0,
    this.amount1to7 = 0.0,
    this.amount8to30 = 0.0,
    this.amount30Plus = 0.0,
    this.overdueBorrowers = const [],
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? _defaultDate;

  static final _defaultDate = DateTime.now();

  /// Total overdue count.
  int get totalOverdue => days1to7 + days8to30 + days30Plus;

  /// Total overdue amount.
  double get totalAmount => amount1to7 + amount8to30 + amount30Plus;

  @override
  List<Object?> get props => [
        days1to7,
        days8to30,
        days30Plus,
        amount1to7,
        amount8to30,
        amount30Plus,
        overdueBorrowers,
        generatedAt,
      ];
}

/// Individual overdue borrower in the overdue report.
class OverdueBorrower extends Equatable {
  final String borrowerId;
  final String borrowerName;
  final String loanId;
  final double overdueAmount;
  final int daysOverdue;
  final DateTime dueDate;

  const OverdueBorrower({
    required this.borrowerId,
    required this.borrowerName,
    required this.loanId,
    required this.overdueAmount,
    required this.daysOverdue,
    required this.dueDate,
  });

  /// Which aging bucket this borrower falls into.
  String get agingBucket {
    if (daysOverdue <= 7) return '1-7 days';
    if (daysOverdue <= 30) return '8-30 days';
    return '30+ days';
  }

  @override
  List<Object?> get props => [
        borrowerId,
        borrowerName,
        loanId,
        overdueAmount,
        daysOverdue,
        dueDate,
      ];
}

/// Collection efficiency report entity.
///
/// Metrics tracking how effectively the system collects payments.
class CollectionEfficiencyReport extends Equatable {
  final double totalExpected;
  final double totalCollected;
  final double totalPartial;
  final double totalFailed;
  final double efficiencyRate;
  final int totalAttempts;
  final int successfulAttempts;
  final int failedAttempts;
  final double averageCollectionTimeHours;
  final DateTime generatedAt;

  const CollectionEfficiencyReport({
    this.totalExpected = 0.0,
    this.totalCollected = 0.0,
    this.totalPartial = 0.0,
    this.totalFailed = 0.0,
    this.efficiencyRate = 0.0,
    this.totalAttempts = 0,
    this.successfulAttempts = 0,
    this.failedAttempts = 0,
    this.averageCollectionTimeHours = 0.0,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? _defaultDate;

  static final _defaultDate = DateTime.now();

  /// Success rate as a percentage.
  double get successRate =>
      totalAttempts > 0 ? (successfulAttempts / totalAttempts) * 100 : 0.0;

  /// Failure rate as a percentage.
  double get failureRate =>
      totalAttempts > 0 ? (failedAttempts / totalAttempts) * 100 : 0.0;

  @override
  List<Object?> get props => [
        totalExpected,
        totalCollected,
        totalPartial,
        totalFailed,
        efficiencyRate,
        totalAttempts,
        successfulAttempts,
        failedAttempts,
        averageCollectionTimeHours,
        generatedAt,
      ];
}
