// lib/shared/layouts/mobile_shell_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';

class _MobileNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _MobileNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

const _riderNavItems = [
  _MobileNavItem(
    label: 'Today',
    icon: Icons.today_outlined,
    activeIcon: Icons.today,
    route: '/rider/today',
  ),
  _MobileNavItem(
    label: 'Map',
    icon: Icons.map_outlined,
    activeIcon: Icons.map,
    route: '/rider/map',
  ),
  _MobileNavItem(
    label: 'History',
    icon: Icons.history_outlined,
    activeIcon: Icons.history,
    route: '/rider/history',
  ),
  _MobileNavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    route: '/rider/profile',
  ),
];

const _borrowerNavItems = [
  _MobileNavItem(
    label: 'My Loan',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet,
    route: '/lender/loan',
  ),
  _MobileNavItem(
    label: 'Payments',
    icon: Icons.payment_outlined,
    activeIcon: Icons.payment,
    route: '/lender/payments',
  ),
  _MobileNavItem(
    label: 'Notifications',
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications,
    route: '/lender/notifications',
  ),
  _MobileNavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    route: '/lender/profile',
  ),
];

class MobileShellLayout extends ConsumerWidget {
  final Widget child;

  const MobileShellLayout({super.key, required this.child});

  List<_MobileNavItem> _navItemsFor(AppAuthState authState) {
    if (authState is AppAuthAuthenticated) {
      if (authState.isRider) return _riderNavItems;
      if (authState.isLender) return _borrowerNavItems;
    }
    return _borrowerNavItems;
  }

  int _currentIndexFor(String location, List<_MobileNavItem> items) {
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final authState = ref.watch(authProvider);
    final navItems = _navItemsFor(authState);
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndexFor(location, navItems);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
        height: 70,
        child: Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : ColorTokens.darkSurface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isActive = index == currentIndex;

              return _FloatingNavItem(
                item: item,
                isActive: isActive,
                isLight: isLight,
                onTap: () => context.go(item.route),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  final _MobileNavItem item;
  final bool isActive;
  final bool isLight;
  final VoidCallback onTap;

  const _FloatingNavItem({
    required this.item,
    required this.isActive,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 24 : 0,
                height: 3,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isActive ? ColorTokens.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 24,
                color: isActive
                    ? ColorTokens.accent
                    : (isLight
                        ? ColorTokens.lightDisabled
                        : ColorTokens.darkDisabled),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? ColorTokens.accent
                      : (isLight
                          ? ColorTokens.lightDisabled
                          : ColorTokens.darkDisabled),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
