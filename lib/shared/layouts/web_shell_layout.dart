// lib/shared/layouts/web_shell_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/core/theme/text_styles.dart';
import 'package:jireta_loan/core/utils/constants.dart';
import 'package:jireta_loan/features/notifications/presentation/providers/notification_notifier.dart';
import 'package:jireta_loan/shared/widgets/avatar_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

const _adminNavItems = [
  _NavItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/head-employee/dashboard'),
  _NavItem(label: 'Users', icon: LucideIcons.users, route: '/head-employee/users'),
  _NavItem(label: 'Loans', icon: LucideIcons.landmark, route: '/head-employee/loans'),
  _NavItem(label: 'Lenders', icon: LucideIcons.building, route: '/head-employee/lenders'),
  _NavItem(label: 'Riders', icon: LucideIcons.bike, route: '/head-employee/riders'),
  _NavItem(label: 'Collections', icon: LucideIcons.banknote, route: '/head-employee/collections'),
  _NavItem(label: 'Reports', icon: LucideIcons.barChart, route: '/head-employee/reports'),
  _NavItem(label: 'Audit Logs', icon: LucideIcons.history, route: '/head-employee/audit'),
  _NavItem(label: 'Settings', icon: LucideIcons.settings, route: '/head-employee/settings'),
];

const _managerNavItems = [
  _NavItem(label: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/employee/dashboard'),
  _NavItem(label: 'Loans', icon: LucideIcons.landmark, route: '/employee/loans'),
  _NavItem(label: 'Lenders', icon: LucideIcons.building, route: '/employee/lenders'),
  _NavItem(label: 'Riders', icon: LucideIcons.bike, route: '/employee/riders'),
  _NavItem(label: 'Collections', icon: LucideIcons.banknote, route: '/employee/collections'),
  _NavItem(label: 'Profile', icon: LucideIcons.user, route: '/employee/profile'),
];

final _sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

final _themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class WebShellLayout extends ConsumerWidget {
  final Widget child;

  const WebShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AppAuthAuthenticated) return const SizedBox.shrink();

    final isCollapsed = ref.watch(_sidebarCollapsedProvider);
    final navItems = authState.isHeadManager
        ? _adminNavItems
        : authState.isEmployee
            ? _managerNavItems
            : <_NavItem>[];

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            navItems: navItems,
            isCollapsed: isCollapsed,
            onToggleCollapse: () =>
                ref.read(_sidebarCollapsedProvider.notifier).state =
                    !isCollapsed,
            user: authState,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(user: authState),
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

class _Sidebar extends ConsumerWidget {
  final List<_NavItem> navItems;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final AppAuthAuthenticated user;

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
          _SidebarHeader(
            isCollapsed: isCollapsed,
            onToggle: onToggleCollapse,
          ),
          const Divider(height: 1),
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
          _SidebarFooter(
            user: user,
            isCollapsed: isCollapsed,
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const _SidebarHeader({
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo.jpg',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo.jpg',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppConstants.appName,
              style: TextStyles.titleMedium(context).copyWith(
                fontWeight: FontWeight.w700,
                color: ColorTokens.accent,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.chevronLeft,
              size: 20,
            ),
            onPressed: onToggle,
            tooltip: 'Collapse sidebar',
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

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

class _SidebarFooter extends StatelessWidget {
  final AppAuthAuthenticated user;
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
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              LucideIcons.logOut,
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
      'head_manager' => ColorTokens.roleHeadManager,
      'employee' => ColorTokens.roleEmployee,
      'rider' => ColorTokens.roleRider,
      'lender' => ColorTokens.roleLender,
      _ => isLight ? ColorTokens.lightTextSecondary : ColorTokens.darkTextSecondary,
    };
  }

  void _handleSignOut(BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
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
    ).then((confirmed) async {
      if (confirmed == true) {
        final authNotifier = container.read(authProvider.notifier);
        await authNotifier.signOut();
      }
    });
  }
}

class _TopBar extends ConsumerWidget {
  final AppAuthAuthenticated user;

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
          Expanded(
            child: Text(
              _pageTitle(GoRouterState.of(context).matchedLocation),
              style: TextStyles.titleMedium(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell, size: 22),
                onPressed: () {
                  if (user.isHeadManager) {
                    context.go('/head-employee/dashboard');
                  } else if (user.isEmployee) {
                    context.go('/employee/dashboard');
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

          IconButton(
            icon: Icon(
              isLight ? LucideIcons.moon : LucideIcons.sun,
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
