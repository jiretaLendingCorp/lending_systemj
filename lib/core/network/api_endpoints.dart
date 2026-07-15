// lib/core/network/api_endpoints.dart
class ApiEndpoints {
  ApiEndpoints._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lcelzrvpqwlbeccrwpkp.supabase.co',
  );

  static const String baseUrl = '$supabaseUrl/functions/v1';

  static const String authLogin = '/auth/login';
  static const String authSignup = '/auth/signup';
  static const String authOtpSend = '/auth/otp-send';
  static const String authOtpVerify = '/auth/otp-verify';
  static const String authOtpResend = '/auth/otp-resend';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  static const String users = '/users';
  static const String usersMe = '/users/me';
  static const String usersById = '/users/{id}';
  static const String usersChangePassword = '/users/change-password';
  static const String usersUploadAvatar = '/users/avatar';

  static const String loans = '/loans';
  static const String loansById = '/loans/{id}';
  static const String loansApply = '/loans/apply';
  static const String loansPreview = '/loans/preview';
  static const String loansApprove = '/loans/{id}/approve';
  static const String loansReject = '/loans/{id}/reject';
  static const String loansDisburse = '/loans/{id}/disburse';
  static const String loansCancel = '/loans/{id}/cancel';
  static const String loansSchedule = '/loans/{id}/schedule';
  static const String loansSummary = '/loans/summary';
  static const String loansLender = '/loans/lender/{lenderId}';
  static const String loansOverdue = '/loans/overdue';

  static const String payments = '/payments';
  static const String paymentsById = '/payments/{id}';
  static const String paymentsByLoan = '/payments/loan/{loanId}';
  static const String paymentsRecord = '/payments/record';
  static const String paymentsVerify = '/payments/{id}/verify';
  static const String paymentsReject = '/payments/{id}/reject';
  static const String paymentsReceipt = '/payments/{id}/receipt';

  static const String lenders = '/lenders';
  static const String lendersById = '/lenders/{id}';
  static const String lendersCreate = '/lenders/create';
  static const String lendersUpdate = '/lenders/{id}/update';
  static const String lendersPortfolio = '/lenders/{id}/portfolio';
  static const String lendersLoans = '/lenders/{id}/loans';
  static const String lendersSummary = '/lenders/summary';

  static const String riders = '/riders';
  static const String ridersById = '/riders/{id}';
  static const String ridersCreate = '/riders/create';
  static const String ridersUpdate = '/riders/{id}/update';
  static const String ridersAssignments = '/riders/{id}/assignments';
  static const String ridersTodayRoute = '/riders/{id}/today-route';
  static const String ridersLocation = '/riders/{id}/location';
  static const String ridersUpdateLocation = '/riders/{id}/update-location';

  static const String collections = '/collections';
  static const String collectionsById = '/collections/{id}';
  static const String collectionsAssign = '/collections/assign';
  static const String collectionsComplete = '/collections/{id}/complete';
  static const String collectionsPartial = '/collections/{id}/partial';
  static const String collectionsFail = '/collections/{id}/fail';
  static const String collectionsByRider = '/collections/rider/{riderId}';
  static const String collectionsByDate = '/collections/date/{date}';
  static const String collectionsToday = '/collections/today';
  static const String collectionsSummary = '/collections/summary';

  static const String notifications = '/notifications';
  static const String notificationsById = '/notifications/{id}';
  static const String notificationsMarkRead = '/notifications/{id}/read';
  static const String notificationsMarkAllRead = '/notifications/read-all';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsRegisterDevice = '/notifications/register-device';
  static const String notificationsUnregisterDevice = '/notifications/unregister-device';

  static const String reports = '/reports';
  static const String reportsLoanPortfolio = '/reports/loan-portfolio';
  static const String reportsCollectionEfficiency = '/reports/collection-efficiency';
  static const String reportsOverdue = '/reports/overdue';
  static const String reportsRevenue = '/reports/revenue';
  static const String reportsRiderPerformance = '/reports/rider-performance';
  static const String reportsLenderPerformance = '/reports/lender-performance';
  static const String reportsLenderActivity = '/reports/lender-activity';
  static const String reportsExport = '/reports/export';

  static const String audit = '/audit';
  static const String auditLog = '/audit/log';
  static const String auditByUser = '/audit/user/{userId}';
  static const String auditByEntity = '/audit/entity/{entityType}/{entityId}';
  static const String auditByDateRange = '/audit/date-range';

  static const String settings = '/settings';
  static const String settingsInterestRates = '/settings/interest-rates';
  static const String settingsPenaltyRates = '/settings/penalty-rates';
  static const String settingsLoanLimits = '/settings/loan-limits';
  static const String settingsSystem = '/settings/system';
  static const String settingsNotifications = '/settings/notifications';

  static const String dashboardHeadManager = '/dashboard/head-manager';
  static const String dashboardEmployee = '/dashboard/employee';
  static const String dashboardRider = '/dashboard/rider';
  static const String dashboardLender = '/dashboard/lender';

  static const String uploads = '/uploads';
  static const String uploadsImage = '/uploads/image';
  static const String uploadsDocument = '/uploads/document';

  static const String health = '/health';
  static const String healthReady = '/health/ready';
  static const String healthLive = '/health/live';
}
