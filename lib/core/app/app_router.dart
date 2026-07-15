// lib/core/app/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/utils/constants.dart';
import 'package:jireta_loan/shared/layouts/mobile_shell_layout.dart';
import 'package:jireta_loan/shared/layouts/web_shell_layout.dart';
import 'package:jireta_loan/features/auth/presentation/pages/login_page.dart';
import 'package:jireta_loan/features/auth/presentation/pages/signup_page.dart';
import 'package:jireta_loan/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:jireta_loan/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:jireta_loan/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:jireta_loan/features/dashboard/presentation/pages/manager_dashboard_page.dart';
import 'package:jireta_loan/features/users/presentation/pages/user_list_page.dart';
import 'package:jireta_loan/features/users/presentation/pages/user_create_page.dart';
import 'package:jireta_loan/features/users/presentation/pages/user_detail_page.dart';
import 'package:jireta_loan/features/loans/presentation/pages/loan_list_page.dart';
import 'package:jireta_loan/features/loans/presentation/pages/loan_detail_page.dart';
import 'package:jireta_loan/features/loans/presentation/pages/loan_application_page.dart';
import 'package:jireta_loan/features/collections/presentation/pages/collection_list_page.dart';
import 'package:jireta_loan/features/collections/presentation/pages/collection_detail_page.dart';
import 'package:jireta_loan/features/reports/presentation/pages/portfolio_report_page.dart';
import 'package:jireta_loan/features/reports/presentation/pages/overdue_report_page.dart';
import 'package:jireta_loan/features/reports/presentation/pages/collection_efficiency_page.dart';
import 'package:jireta_loan/features/audit_logs/presentation/pages/audit_log_page.dart';
import 'package:jireta_loan/features/settings/presentation/pages/settings_page.dart';
import 'package:jireta_loan/features/riders/presentation/pages/rider_today_page.dart';
import 'package:jireta_loan/features/riders/presentation/pages/rider_map_page.dart';
import 'package:jireta_loan/features/riders/presentation/pages/rider_history_page.dart';
import 'package:jireta_loan/features/riders/presentation/pages/rider_profile_page.dart';
import 'package:jireta_loan/features/borrowers/presentation/pages/borrower_loan_page.dart';
import 'package:jireta_loan/features/borrowers/presentation/pages/borrower_payments_page.dart';
import 'package:jireta_loan/features/borrowers/presentation/pages/borrower_notifications_page.dart';
import 'package:jireta_loan/features/borrowers/presentation/pages/borrower_profile_page.dart';
import 'package:jireta_loan/features/documents/presentation/pages/kyc_upload_page.dart';
import 'package:jireta_loan/features/payments/presentation/pages/payment_page.dart';
import 'package:jireta_loan/features/payments/presentation/pages/payment_history_page.dart';
import 'package:jireta_loan/features/payments/presentation/pages/payment_receipt_page.dart';
import 'package:jireta_loan/features/disbursements/presentation/pages/disbursement_list_page.dart';
import 'package:jireta_loan/features/disbursements/presentation/pages/disbursement_detail_page.dart';
import 'package:jireta_loan/features/notifications/presentation/pages/notification_center_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppRouter {
  AppRouter._();

  static final provider = Provider<GoRouter>((ref) {
    final authState = ref.watch(authProvider);
    final isWideScreen = kIsWeb;

    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode,
      redirect: (context, state) => _guard(authState, state),
      routes: [
        GoRoute(
          path: '/auth/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/auth/signup',
          name: 'signup',
          builder: (context, state) => const SignupPage(),
        ),
        GoRoute(
          path: '/auth/otp',
          name: 'otp',
          builder: (context, state) {
            String phone = state.uri.queryParameters['phone'] ?? '';
            if (phone.isEmpty) {
              final extra = state.extra;
              if (extra is Map) {
                phone = extra['phone'] as String? ?? '';
              }
            }
            return OtpVerificationPage(phone: phone);
          },
        ),
        GoRoute(
          path: '/auth/forgot-password',
          name: 'forgotPassword',
          builder: (context, state) => const ForgotPasswordPage(),
        ),

        ShellRoute(
          builder: (context, state, child) {
            if (isWideScreen) {
              return WebShellLayout(child: child);
            }
            return MobileShellLayout(child: child);
          },
          routes: [
            GoRoute(
              path: '/head-employee/dashboard',
              name: 'headManagerDashboard',
              builder: (context, state) => const AdminDashboardPage(),
            ),
            GoRoute(
              path: '/head-employee/users',
              name: 'headManagerUsers',
              builder: (context, state) => const UserListPage(),
              routes: [
                GoRoute(
                  path: 'create',
                  name: 'headManagerUserCreate',
                  builder: (context, state) => const UserCreatePage(),
                ),
                GoRoute(
                  path: ':userId',
                  name: 'headManagerUserDetail',
                  builder: (context, state) => UserDetailPage(
                    userId: state.pathParameters['userId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/head-employee/loans',
              name: 'headManagerLoans',
              builder: (context, state) => const LoanListPage(),
              routes: [
                GoRoute(
                  path: ':loanId',
                  name: 'headManagerLoanDetail',
                  builder: (context, state) => LoanDetailPage(
                    loanId: state.pathParameters['loanId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/head-employee/lenders',
              name: 'headManagerLenders',
              builder: (context, state) => const _PlaceholderPage(title: 'Lender Management'),
            ),
            GoRoute(
              path: '/head-employee/riders',
              name: 'headManagerRiders',
              builder: (context, state) => const _PlaceholderPage(title: 'Rider Management'),
            ),
            GoRoute(
              path: '/head-employee/collections',
              name: 'headManagerCollections',
              builder: (context, state) => const CollectionListPage(),
              routes: [
                GoRoute(
                  path: ':collectionId',
                  name: 'headManagerCollectionDetail',
                  builder: (context, state) => CollectionDetailPage(
                    collectionId: state.pathParameters['collectionId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/head-employee/reports',
              name: 'headManagerReports',
              builder: (context, state) => const PortfolioReportPage(),
              routes: [
                GoRoute(
                  path: 'overdue',
                  name: 'headManagerReportOverdue',
                  builder: (context, state) => const OverdueReportPage(),
                ),
                GoRoute(
                  path: 'collection-efficiency',
                  name: 'headManagerReportEfficiency',
                  builder: (context, state) => const CollectionEfficiencyPage(),
                ),
              ],
            ),
            GoRoute(
              path: '/head-employee/audit',
              name: 'headManagerAudit',
              builder: (context, state) => const AuditLogPage(),
            ),
            GoRoute(
              path: '/head-employee/settings',
              name: 'headManagerSettings',
              builder: (context, state) => const SettingsPage(),
            ),

            GoRoute(
              path: '/employee/dashboard',
              name: 'employeeDashboard',
              builder: (context, state) => const EmployeeDashboardPage(),
            ),
            GoRoute(
              path: '/employee/loans',
              name: 'managerLoans',
              builder: (context, state) => const LoanListPage(),
              routes: [
                GoRoute(
                  path: ':loanId',
                  name: 'managerLoanDetail',
                  builder: (context, state) => LoanDetailPage(
                    loanId: state.pathParameters['loanId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/employee/lenders',
              name: 'managerLenders',
              builder: (context, state) => const _PlaceholderPage(title: 'Lender Overview'),
            ),
            GoRoute(
              path: '/employee/riders',
              name: 'managerRiders',
              builder: (context, state) => const _PlaceholderPage(title: 'Rider Overview'),
            ),
            GoRoute(
              path: '/employee/collections',
              name: 'managerCollections',
              builder: (context, state) => const CollectionListPage(),
              routes: [
                GoRoute(
                  path: ':collectionId',
                  name: 'managerCollectionDetail',
                  builder: (context, state) => CollectionDetailPage(
                    collectionId: state.pathParameters['collectionId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/employee/profile',
              name: 'managerProfile',
              builder: (context, state) => const SettingsPage(),
            ),

            GoRoute(
              path: '/rider/today',
              name: 'riderToday',
              builder: (context, state) => const RiderTodayPage(),
            ),
            GoRoute(
              path: '/rider/map',
              name: 'riderMap',
              builder: (context, state) => const RiderMapPage(),
            ),
            GoRoute(
              path: '/rider/history',
              name: 'riderHistory',
              builder: (context, state) => const RiderHistoryPage(),
            ),
            GoRoute(
              path: '/rider/profile',
              name: 'riderProfile',
              builder: (context, state) => const RiderProfilePage(),
            ),

            GoRoute(
              path: '/lender/loan',
              name: 'borrowerLoan',
              builder: (context, state) => const LenderLoanPage(),
              routes: [
                GoRoute(
                  path: 'apply',
                  name: 'borrowerLoanApply',
                  builder: (context, state) => const LoanApplicationPage(),
                ),
              ],
            ),
            GoRoute(
              path: '/lender/payments',
              name: 'lenderPayments',
              builder: (context, state) => const LenderPaymentsPage(),
            ),
            GoRoute(
              path: '/lender/notifications',
              name: 'lenderNotifications',
              builder: (context, state) => const LenderNotificationsPage(),
            ),
            GoRoute(
              path: '/lender/profile',
              name: 'lenderProfile',
              builder: (context, state) => const LenderProfilePage(),
            ),
            GoRoute(
              path: '/lender/kyc',
              name: 'lenderKyc',
              builder: (context, state) => const KycUploadPage(),
            ),

            GoRoute(
              path: '/loans/:loanId',
              name: 'loanDetail',
              builder: (context, state) => LoanDetailPage(
                loanId: state.pathParameters['loanId']!,
              ),
            ),
            GoRoute(
              path: '/payments',
              name: 'payment',
              builder: (context, state) => const PaymentPage(),
            ),
            GoRoute(
              path: '/payments/history',
              name: 'paymentHistory',
              builder: (context, state) => const PaymentHistoryPage(),
            ),
            GoRoute(
              path: '/payments/:paymentId/receipt',
              name: 'paymentReceipt',
              builder: (context, state) => PaymentReceiptPage(
                paymentId: state.pathParameters['paymentId']!,
              ),
            ),
            GoRoute(
              path: '/disbursements',
              name: 'disbursementList',
              builder: (context, state) => const DisbursementListPage(),
              routes: [
                GoRoute(
                  path: ':disbursementId',
                  name: 'disbursementDetail',
                  builder: (context, state) => DisbursementDetailPage(
                    disbursementId: state.pathParameters['disbursementId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/notifications',
              name: 'notificationCenter',
              builder: (context, state) => const NotificationCenterPage(),
            ),
          ],
        ),

        GoRoute(
          path: '/',
          name: 'root',
          redirect: (context, state) => _roleBasedHome(authState),
        ),
      ],
    );
  });

  static String? _guard(AppAuthState authState, GoRouterState state) {
    final currentPath = state.matchedLocation;

    if (authState is AppAuthLoading) {
      return null;
    }

    final isPublicRoute = currentPath.startsWith('/auth');

    if (authState is AppAuthUnauthenticated) {
      if (!isPublicRoute) {
        return '/auth/login';
      }
      return null;
    }

    if (authState is AppAuthAuthenticated) {
      if (isPublicRoute) {
        return _roleBasedHome(authState);
      }

      if (!_hasRoleAccess(authState.role, currentPath)) {
        return _roleBasedHome(authState);
      }

      return null;
    }

    return null;
  }

  static String _roleBasedHome(AppAuthState authState) {
    if (authState is! AppAuthAuthenticated) return '/auth/login';

    return switch (authState.role) {
      AppConstants.roleHeadManager => '/head-employee/dashboard',
      AppConstants.roleEmployee => '/employee/dashboard',
      AppConstants.roleRider => '/rider/today',
      AppConstants.roleLender => '/lender/loan',
      _ => '/auth/login',
    };
  }

  static bool _hasRoleAccess(String role, String path) {
    if (role == AppConstants.roleHeadManager) {
      return true;
    }

    if (path.startsWith('/head-employee')) {
      return false;
    }
    if (path.startsWith('/employee')) {
      return role == AppConstants.roleEmployee;
    }
    if (path.startsWith('/rider')) {
      return role == AppConstants.roleRider;
    }
    if (path.startsWith('/lender')) {
      return role == AppConstants.roleLender;
    }

    return true;
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.construction,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
