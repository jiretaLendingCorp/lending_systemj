// lib/core/app/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/utils/constants.dart';

class AppRouter {
  AppRouter._();

  static final provider = Provider<GoRouter>((ref) {
    final authState = ref.watch(authProvider);

    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      redirect: (context, state) => _guard(authState, state),
      routes: [
        GoRoute(
          path: '/auth/login',
          name: 'login',
          builder: (context, state) => const _PlaceholderPage(title: 'Login'),
        ),
        GoRoute(
          path: '/auth/signup',
          name: 'signup',
          builder: (context, state) => const _PlaceholderPage(title: 'Sign Up'),
        ),
        GoRoute(
          path: '/auth/otp',
          name: 'otp',
          builder: (context, state) => const _PlaceholderPage(title: 'OTP Verification'),
        ),
        GoRoute(
          path: '/auth/forgot-password',
          name: 'forgotPassword',
          builder: (context, state) => const _PlaceholderPage(title: 'Forgot Password'),
        ),

        GoRoute(
          path: '/head-employee/dashboard',
          name: 'headManagerDashboard',
          builder: (context, state) => const _PlaceholderPage(title: 'Head Employee Dashboard'),
        ),
        GoRoute(
          path: '/head-employee/users',
          name: 'headManagerUsers',
          builder: (context, state) => const _PlaceholderPage(title: 'User Management'),
        ),
        GoRoute(
          path: '/head-employee/loans',
          name: 'headManagerLoans',
          builder: (context, state) => const _PlaceholderPage(title: 'Loan Management'),
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
          builder: (context, state) => const _PlaceholderPage(title: 'Collections Management'),
        ),
        GoRoute(
          path: '/head-employee/reports',
          name: 'headManagerReports',
          builder: (context, state) => const _PlaceholderPage(title: 'Reports'),
        ),
        GoRoute(
          path: '/head-employee/audit',
          name: 'headManagerAudit',
          builder: (context, state) => const _PlaceholderPage(title: 'Audit Log'),
        ),
        GoRoute(
          path: '/head-employee/settings',
          name: 'headManagerSettings',
          builder: (context, state) => const _PlaceholderPage(title: 'Settings'),
        ),

        GoRoute(
          path: '/employee/dashboard',
          name: 'employeeDashboard',
          builder: (context, state) => const _PlaceholderPage(title: 'Employee Dashboard'),
        ),
        GoRoute(
          path: '/employee/loans',
          name: 'managerLoans',
          builder: (context, state) => const _PlaceholderPage(title: 'Loan Processing'),
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
          builder: (context, state) => const _PlaceholderPage(title: 'Collections Overview'),
        ),
        GoRoute(
          path: '/employee/profile',
          name: 'managerProfile',
          builder: (context, state) => const _PlaceholderPage(title: 'Employee Profile'),
        ),

        GoRoute(
          path: '/rider/today',
          name: 'riderToday',
          builder: (context, state) => const _PlaceholderPage(title: 'Today\'s Route'),
        ),
        GoRoute(
          path: '/rider/map',
          name: 'riderMap',
          builder: (context, state) => const _PlaceholderPage(title: 'Collection Map'),
        ),
        GoRoute(
          path: '/rider/history',
          name: 'riderHistory',
          builder: (context, state) => const _PlaceholderPage(title: 'Collection History'),
        ),
        GoRoute(
          path: '/rider/profile',
          name: 'riderProfile',
          builder: (context, state) => const _PlaceholderPage(title: 'Rider Profile'),
        ),

        GoRoute(
          path: '/lender/loan',
          name: 'borrowerLoan',
          builder: (context, state) => const _PlaceholderPage(title: 'My Loan'),
        ),
        GoRoute(
          path: '/lender/payments',
          name: 'lenderPayments',
          builder: (context, state) => const _PlaceholderPage(title: 'My Payments'),
        ),
        GoRoute(
          path: '/lender/notifications',
          name: 'lenderNotifications',
          builder: (context, state) => const _PlaceholderPage(title: 'Notifications'),
        ),
        GoRoute(
          path: '/lender/profile',
          name: 'lenderProfile',
          builder: (context, state) => const _PlaceholderPage(title: 'My Profile'),
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
    if (role == AppConstants.roleHeadManager) return true;

    if (path.startsWith('/head-manager')) return false;
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
              Icons.construction_rounded,
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
