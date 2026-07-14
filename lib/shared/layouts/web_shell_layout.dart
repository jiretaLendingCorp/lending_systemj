import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lendflow/core/auth/auth_provider.dart';
import 'package:lendflow/core/theme/color_tokens.dart';
import 'package:lendflow/core/theme/text_styles.dart';
import 'package:lendflow/core/utils/constants.dart';
import 'package:lendflow/features/notifications/presentation/providers/notification_notifier.dart';
import 'package:lendflow/shared/widgets/avatar_widget.dart';

// ─────────────────────────────────────────────────────────────────
// Sidebar navigation item model
// ─────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

// ─────────────────────────────────────────────────────────────────
// Role-based navigation definitions
// ─────────────────────────────────────────────────────────────────

const _adminNavItems = [
  _NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/admin/dashboard'),
  _NavItem(label: 'Users', icon: Icons.people_rounded, route: '/admin/users'),
  _NavItem(label: 'Loans', icon: Icons.account_balance_rounded, route: '/admin/loans'),
  _NavItem(label: 'Lenders', icon: Icons.business_rounded, route: '/admin/lenders'),
  _NavItem(label: 'Riders', icon: Icons.two_wheeler_rounded, route: '/admin/riders'),
  _NavItem(label: 'Collections', icon: Icons.payments_rounded, route: '/admin/collections'),
  _NavItem(label: 'Reports', icon: Icons.assessment_rounded, route: '/admin/reports'),
  _NavItem(label: 'Audit Logs', icon: Icons.history_rounded, route: '/admin/audit'),
  _NavItem(label: 'Settings', icon: Icons.settings_rounded, route: '/admin/settings'),
];

const _managerNavItems = [
  _NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/manager/dashboard'),
  _NavItem(label: 'Loans', icon: Icons.account_balance_rounded, route: '/manager/loans'),
  _NavItem(label: 'Lenders', icon: Icons.business_rounded, route: '/manager/lenders'),
  _NavItem(label: 'Riders', icon: Icons.two_wheeler_rounded, route: '/manager/riders'),
  _NavItem(label: 'Collections', icon: Icons.payments_rounded, route: '/manager/collections'),
  _NavItem(label: 'Profile', icon: Icons.person_rounded, route: '/manager/profile'),
];

// ─────────────────────────────────────────────────────────────────
// Sidebar collapsed width provider
// ─────────────────────────────────────────────────────────────────

final _sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────────────────────────────
// Theme mode provider
// ─────────────────────────────────────────────────────────────────

final _themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// ─────────────────────────────────────────────────────────────────
// WebShellLayout
// ─────────────────────────────────────────────────────────────────

/// Web shell layout with fixed left sidebar, top bar, and content area.
///
/// Features:
/// - 280px fixed sidebar with role-filtered navigation
/// - Collapsible sidebar on smaller screens
/// - Top bar with user avatar, notifications badge, and theme toggle
/// - Active navigation item highlighted with accent colour (#4CA5D2)
/// - Logo at sidebar top, user info at sidebar bottom
class WebShellLayout extends ConsumerWidget {
  final Widget child;

  const WebShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final isCollapsed = ref.watch(_sidebarCollapsedProvider);
    final navItems = authState.isAdmin
        ? _adminNavItems
        : authState.isManager
            ? _managerNavItems
            : <_NavItem>[];

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────
          _Sidebar(
            navItems: navItems,
            isCollapsed: isCollapsed,
            onToggleCollapse: () =>
                ref.read(_sidebarCollapsedProvider.notifier).state =
                    !isCollapsed,
            user: authState,
          ),
          // ── Main area ────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────────────
                _TopBar(user: authState),
                // ── Content ───────────────────────────────────────
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────

class _Sidebar extends ConsumerWidget {
  final List<_NavItem> navItems;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final AuthAuthenticated user;

  const _Sidebar({
    required this.navItems,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : ColorTokens.darkSurface;
    final borderColor = isLight ? ColorTokens.lightBorder : ColorTokens.darkBorder;

    final sidebarWidth = isCollapsed ? 72.0 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── Logo + collapse toggle ───────────────────────────────
          _SidebarHeader(
            isCollapsed: isCollapsed,
            onToggle: onToggleCollapse,
          ),
          const Divider(height: 1),
          // ── Navigation items ─────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final item in navItems)
                  _NavItemTile(
                    item: item,
                    isCollapsed: isCollapsed,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── User info at bottom ──────────────────────────────────
          _SidebarFooter(
            user: user,
            isCollapsed: isCollapsed,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Sidebar header (logo + collapse toggle)
// ─────────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const _SidebarHeader({
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          // Logo icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ColorTokens.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'LF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppConstants.appName,
                style: TextStyles.titleMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: ColorTokens.accent,
                ),
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: Icon(
              isCollapsed
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              size: 20,
            ),
            onPressed: onToggle,
            tooltip: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Navigation item tile
// ─────────────────────────────────────────────────────────────────

class _NavItemTile extends StatelessWidget {
  final _NavItem item;
  final bool isCollapsed;

  const _NavItemTile({
    required this.item,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isActive = currentRoute == item.route ||
        (currentRoute.startsWith(item.route) && item.route != '/');
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final activeBg = ColorTokens.accent.withValues(alpha: 0.1);
    final activeIconColor = ColorTokens.accent;
    final inactiveIconColor = isLight
        ? ColorTokens.lightTextSecondary
        : ColorTokens.darkTextSecondary;
    final activeTextColor = ColorTokens.accent;
    final inactiveTextColor = isLight
        ? ColorTokens.lightText
        : ColorTokens.darkText;

    final iconColor = isActive ? activeIconColor : inactiveIconColor;
    final textColor = isActive ? activeTextColor : inactiveTextColor;

    Widget tile;
    if (isCollapsed) {
      tile = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Tooltip(
          message: item.label,
          preferBelow: false,
          child: Material(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.go(item.route),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Center(
                  child: Icon(item.icon, size: 22, color: iconColor),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      tile = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.go(item.route),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                children: [
                  Icon(item.icon, size: 22, color: iconColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyles.bodyMedium(context).copyWith(
                        color: textColor,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: ColorTokens.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return tile;
  }
}

// ─────────────────────────────────────────────────────────────────
// Sidebar footer (user info)
// ─────────────────────────────────────────────────────────────────

class _SidebarFooter extends StatelessWidget {
  final AuthAuthenticated user;
  final bool isCollapsed;

  const _SidebarFooter({
    required this.user,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Tooltip(
          message: user.fullName ?? user.email,
          preferBelow: false,
          child: AvatarWidget(
            fullName: user.fullName ?? user.email,
            role: user.role,
            avatarUrl: user.avatarUrl,
            radius: 18,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          AvatarWidget(
            fullName: user.fullName ?? user.email,
            role: user.role,
            avatarUrl: user.avatarUrl,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.fullName ?? user.email,
                  style: TextStyles.labelLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  user.role.toUpperCase(),
                  style: TextStyles.labelSmall(context).copyWith(
                    color: _roleTextColor(user.role, isLight),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              size: 18,
              color: isLight
                  ? ColorTokens.lightTextSecondary
                  : ColorTokens.darkTextSecondary,
            ),
            onPressed: () => _handleSignOut(context),
            tooltip: 'Sign out',
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Color _roleTextColor(String role, bool isLight) {
    return switch (role.toLowerCase()) {
      'admin' => ColorTokens.roleAdmin,
      'manager' => ColorTokens.roleManager,
      'rider' => ColorTokens.roleRider,
      'borrower' => ColorTokens.roleBorrower,
      _ => isLight ? ColorTokens.lightTextSecondary : ColorTokens.darkTextSecondary,
    };
  }

  void _handleSignOut(BuildContext context) {
    // The actual sign-out is handled by the auth provider.
    // We navigate to login after confirming.
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorTokens.lightError,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        // Navigation to /auth/login is handled by the router's
        // redirect logic when auth state changes to unauthenticated.
        // The AuthNotifier's signOut() clears the session.
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  final AuthAuthenticated user;

  const _TopBar({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgColor = isLight ? Colors.white : ColorTokens.darkSurface;
    final borderColor = isLight ? ColorTokens.lightBorder : ColorTokens.darkBorder;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── Page title (from route) ───────────────────────────────
          Expanded(
            child: Text(
              _pageTitle(GoRouterState.of(context).matchedLocation),
              style: TextStyles.titleMedium(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ── Notifications button ──────────────────────────────────
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () {
                  // Navigate to the appropriate notification center
                  if (user.isAdmin) {
                    context.go('/admin/dashboard');
                  } else if (user.isManager) {
                    context.go('/manager/dashboard');
                  }
                },
                tooltip: 'Notifications',
                splashRadius: 18,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: ColorTokens.lightError,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 8),

          // ── Theme toggle ──────────────────────────────────────────
          IconButton(
            icon: Icon(
              isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              size: 22,
            ),
            onPressed: () {
              final current = ref.read(_themeModeProvider);
              final next = current == ThemeMode.light
                  ? ThemeMode.dark
                  : current == ThemeMode.dark
                      ? ThemeMode.system
                      : ThemeMode.light;
              ref.read(_themeModeProvider.notifier).state = next;
            },
            tooltip: 'Toggle theme',
            splashRadius: 18,
          ),

          const SizedBox(width: 8),

          // ── User avatar ───────────────────────────────────────────
          AvatarWidget(
            fullName: user.fullName ?? user.email,
            role: user.role,
            avatarUrl: user.avatarUrl,
            radius: 16,
          ),
        ],
      ),
    );
  }

  String _pageTitle(String route) {
    if (route.contains('dashboard')) return 'Dashboard';
    if (route.contains('users')) return 'User Management';
    if (route.contains('loans')) return 'Loan Management';
    if (route.contains('lenders')) return 'Lenders';
    if (route.contains('riders')) return 'Riders';
    if (route.contains('collections')) return 'Collections';
    if (route.contains('reports')) return 'Reports';
    if (route.contains('audit')) return 'Audit Logs';
    if (route.contains('settings')) return 'Settings';
    if (route.contains('profile')) return 'Profile';
    return AppConstants.appName;
  }
}
