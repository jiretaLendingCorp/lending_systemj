/// App-wide constants for LendFlow.
///
/// Single source of truth for business rules, limits, and magic numbers.
class AppConstants {
  AppConstants._();

  // ── App metadata ───────────────────────────────────────────────
  static const String appName = 'LendFlow';
  static const String appVersion = '1.0.0';
  static const String currencyCode = 'PHP';
  static const String currencySymbol = '₱';
  static const String locale = 'en_PH';
  static const String timezone = 'Asia/Manila';

  // ── Loan parameters ────────────────────────────────────────────
  static const double minLoanAmount = 3000.0;
  static const double maxLoanAmount = 500000.0;
  static const double interestRate = 0.20; // 20% per term
  static const double penaltyRate = 0.20; // 20% of overdue amount
  static const int loanTermDays = 30;
  static const int gracePeriodDays = 3;

  // ── Payment ────────────────────────────────────────────────────
  static const double minPaymentAmount = 100.0;
  static const int paymentOverdueGraceDays = 3;

  // ── Pagination ─────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ── Auth / session ─────────────────────────────────────────────
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 5;
  static const int refreshTokenExpiryDays = 30;
  static const int accessTokenExpiryMinutes = 60;
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;

  // ── Retry / network ────────────────────────────────────────────
  static const int maxRetryAttempts = 2;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  static const Duration maxRetryDelay = Duration(seconds: 8);

  // ── Storage keys ───────────────────────────────────────────────
  static const String accessTokenKey = 'auth_access_token';
  static const String refreshTokenKey = 'auth_refresh_token';
  static const String userIdKey = 'auth_user_id';
  static const String userRoleKey = 'auth_user_role';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String themeKey = 'app_theme';

  // ── User roles ─────────────────────────────────────────────────
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleRider = 'rider';
  static const String roleBorrower = 'borrower';

  static const List<String> validRoles = [
    roleAdmin,
    roleManager,
    roleRider,
    roleBorrower,
  ];

  // ── Loan statuses ──────────────────────────────────────────────
  static const String loanStatusPending = 'pending';
  static const String loanStatusApproved = 'approved';
  static const String loanStatusActive = 'active';
  static const String loanStatusOverdue = 'overdue';
  static const String loanStatusPaid = 'paid';
  static const String loanStatusRejected = 'rejected';
  static const String loanStatusCancelled = 'cancelled';

  // ── Payment statuses ───────────────────────────────────────────
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';

  // ── Collection statuses ────────────────────────────────────────
  static const String collectionStatusAssigned = 'assigned';
  static const String collectionStatusInTransit = 'in_transit';
  static const String collectionStatusCollected = 'collected';
  static const String collectionStatusPartial = 'partial';
  static const String collectionStatusFailed = 'failed';

  // ── Date formats ───────────────────────────────────────────────
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayDateTimeFormat = 'MMM dd, yyyy hh:mm a';
  static const String timeFormat = 'hh:mm a';
}
