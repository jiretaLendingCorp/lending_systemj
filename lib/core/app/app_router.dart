import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/utils/constants.dart';

/// GoRouter configuration with auth guard and role-based routing.
///
/// Route structure:
/// - /auth/*          → public routes (no auth required)
/// - /admin/*         → admin-only routes
/// - /manager/*       → manager-only routes
/// - /rider/*         → rider-only routes
/// - /borrower/*      → borrower-only routes
/// - /                → redirects to role-based dashboard
class AppRouter {
  AppRouter._();

  /// Provider for the [GoRouter] instance.
  ///
  /// Listens to [authProvider] so that the router automatically
  /// re-evaluates redirects when auth state changes.
  static final provider = Provider<GoRouter>((ref) {
    final authState = ref.watch(authProvider);

    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      redirect: (context, state) => _guard(authState, state),
      routes: [
        // ── Auth routes (public) ────────────────────────────────
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

        // ── Admin routes ────────────────────────────────────────
        GoRoute(
          path: '/admin/dashboard',
          name: 'adminDashboard',
          builder: (context, state) => const _PlaceholderPage(title: 'Admin Dashboard'),
        ),
        GoRoute(
          path: '/admin/users',
          name: 'adminUsers',
          builder: (context, state) => const _PlaceholderPage(title: 'User Management'),
        ),
        GoRoute(
          path: '/admin/loans',
          name: 'adminLoans',
          builder: (context, state) => const _PlaceholderPage(title: 'Loan Management'),
        ),
        GoRoute(
          path: '/admin/lenders',
          name: 'adminLenders',
          builder: (context, state) => const _PlaceholderPage(title: 'Lender Management'),
        ),
        GoRoute(
          path: '/admin/riders',
          name: 'adminRiders',
          builder: (context, state) => const _PlaceholderPage(title: 'Rider Management'),
        ),
        GoRoute(
          path: '/admin/collections',
          name: 'adminCollections',
          builder: (context, state) => const _PlaceholderPage(title: 'Collections Management'),
        ),
        GoRoute(
          path: '/admin/reports',
          name: 'adminReports',
          builder: (context, state) => const _PlaceholderPage(title: 'Reports'),
        ),
        GoRoute(
          path: '/admin/audit',
          name: 'adminAudit',
          builder: (context, state) => const _PlaceholderPage(title: 'Audit Log'),
        ),
        GoRoute(
          path: '/admin/settings',
          name: 'adminSettings',
          builder: (context, state) => const _PlaceholderPage(title: 'Settings'),
        ),

        // ── Manager routes ──────────────────────────────────────
        GoRoute(
          path: '/manager/dashboard',
          name: 'managerDashboard',
          builder: (context, state) => const _PlaceholderPage(title: 'Manager Dashboard'),
        ),
        GoRoute(
          path: '/manager/loans',
          name: 'managerLoans',
          builder: (context, state) => const _PlaceholderPage(title: 'Loan Processing'),
        ),
        GoRoute(
          path: '/manager/lenders',
          name: 'managerLenders',
          builder: (context, state) => const _PlaceholderPage(title: 'Lender Overview'),
        ),
        GoRoute(
          path: '/manager/riders',
          name: 'managerRiders',
          builder: (context, state) => const _PlaceholderPage(title: 'Rider Overview'),
        ),
        GoRoute(
          path: '/manager/collections',
          name: 'managerCollections',
          builder: (context, state) => const _PlaceholderPage(title: 'Collections Overview'),
        ),
        GoRoute(
          path: '/manager/profile',
          name: 'managerProfile',
          builder: (context, state) => const _PlaceholderPage(title: 'Manager Profile'),
        ),

        // ── Rider routes ────────────────────────────────────────
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

        // ── Borrower routes ─────────────────────────────────────
        GoRoute(
          path: '/borrower/loan',
          name: 'borrowerLoan',
          builder: (context, state) => const _PlaceholderPage(title: 'My Loan'),
        ),
        GoRoute(
          path: '/borrower/payments',
          name: 'borrowerPayments',
          builder: (context, state) => const _PlaceholderPage(title: 'My Payments'),
        ),
        GoRoute(
          path: '/borrower/notifications',
          name: 'borrowerNotifications',
          builder: (context, state) => const _PlaceholderPage(title: 'Notifications'),
        ),
        GoRoute(
          path: '/borrower/profile',
          name: 'borrowerProfile',
          builder: (context, state) => const _PlaceholderPage(title: 'My Profile'),
        ),

        // ── Root redirect ───────────────────────────────────────
        GoRoute(
          path: '/',
          name: 'root',
          redirect: (context, state) => _roleBasedHome(authState),
        ),
      ],
    );
  });

  /// Central auth + role guard.
  ///
  /// - Unauthenticated users trying to access protected routes → /auth/login
  /// - Authenticated users trying to access /auth/* → role-based home
  /// - Authenticated users trying to access routes outside their role → role-based home
  /// - Loading state → no redirect (show splash)
  static String? _guard(AuthState authState, GoRouterState state) {
    final currentPath = state.matchedLocation;

    // While auth is loading, don't redirect (show splash screen)
    if (authState is AuthLoading) {
      return null;
    }

    // Public routes that don't require auth
    final isPublicRoute = currentPath.startsWith('/auth');

    // Unauthenticated user
    if (authState is AuthUnauthenticated) {
      if (!isPublicRoute) {
        // Redirect to login, preserving the intended destination
        return '/auth/login';
      }
      return null;
    }

    // Authenticated user
    if (authState is AuthAuthenticated) {
      // If trying to access auth pages, redirect to home
      if (isPublicRoute) {
        return _roleBasedHome(authState);
      }

      // Check role-based access
      if (!_hasRoleAccess(authState.role, currentPath)) {
        return _roleBasedHome(authState);
      }

      return null;
    }

    return null;
  }

  /// Get the default home route for a given role.
  static String _roleBasedHome(AuthState authState) {
    if (authState is! AuthAuthenticated) return '/auth/login';

    return switch (authState.role) {
      AppConstants.roleAdmin => '/admin/dashboard',
      AppConstants.roleManager => '/manager/dashboard',
      AppConstants.roleRider => '/rider/today',
      AppConstants.roleBorrower => '/borrower/loan',
      _ => '/auth/login',
    };
  }

  /// Check if a user with [role] is allowed to access [path].
  static bool _hasRoleAccess(String role, String path) {
    // Admin can access everything
    if (role == AppConstants.roleAdmin) return true;

    // Role-specific access checks
    if (path.startsWith('/admin')) return false;
    if (path.startsWith('/manager')) {
      return role == AppConstants.roleManager;
    }
    if (path.startsWith('/rider')) {
      return role == AppConstants.roleRider;
    }
    if (path.startsWith('/borrower')) {
      return role == AppConstants.roleBorrower;
    }

    // Root and other paths are accessible
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────
// Placeholder page (will be replaced by real feature pages)
// ─────────────────────────────────────────────────────────────────

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
