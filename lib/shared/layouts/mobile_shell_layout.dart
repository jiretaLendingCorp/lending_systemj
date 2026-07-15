// lib/shared/layouts/mobile_shell_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jireta_loan/core/auth/auth_provider.dart';
import 'package:jireta_loan/core/theme/color_tokens.dart';
import 'package:jireta_loan/features/riders/presentation/pages/rider_today_page.dart';
import 'package:jireta_loan/features/riders/presentation/pages/rider_map_page.dart';
import 'package:jireta_loan/features/riders/presentation/pages/rider_history_page.dart';
import 'package:jireta_loan/features/riders/presentation/pages/rider_profile_page.dart';
import 'package:jireta_loan/features/borrowers/presentation/pages/borrower_loan_page.dart';
import 'package:jireta_loan/features/borrowers/presentation/pages/borrower_payments_page.dart';
import 'package:jireta_loan/features/borrowers/presentation/pages/borrower_notifications_page.dart';
import 'package:jireta_loan/features/borrowers/presentation/pages/borrower_profile_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    icon: LucideIcons.calendarCheck,
    activeIcon: LucideIcons.calendarCheck,
    route: '/rider/today',
  ),
  _MobileNavItem(
    label: 'Map',
    icon: LucideIcons.map,
    activeIcon: LucideIcons.map,
    route: '/rider/map',
  ),
  _MobileNavItem(
    label: 'History',
    icon: LucideIcons.history,
    activeIcon: LucideIcons.history,
    route: '/rider/history',
  ),
  _MobileNavItem(
    label: 'Profile',
    icon: LucideIcons.user,
    activeIcon: LucideIcons.user,
    route: '/rider/profile',
  ),
];

const _borrowerNavItems = [
  _MobileNavItem(
    label: 'My Loan',
    icon: LucideIcons.wallet,
    activeIcon: LucideIcons.wallet,
    route: '/lender/loan',
  ),
  _MobileNavItem(
    label: 'Payments',
    icon: LucideIcons.creditCard,
    activeIcon: LucideIcons.creditCard,
    route: '/lender/payments',
  ),
  _MobileNavItem(
    label: 'Notifications',
    icon: LucideIcons.bell,
    activeIcon: LucideIcons.bell,
    route: '/lender/notifications',
  ),
  _MobileNavItem(
    label: 'Profile',
    icon: LucideIcons.user,
    activeIcon: LucideIcons.user,
    route: '/lender/profile',
  ),
];

class MobileShellLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MobileShellLayout({super.key, required this.child});

  @override
  ConsumerState<MobileShellLayout> createState() => _MobileShellLayoutState();
}

class _MobileShellLayoutState extends ConsumerState<MobileShellLayout> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_MobileNavItem> get _navItems {
    final authState = ref.read(authProvider);
    if (authState is AppAuthAuthenticated) {
      if (authState.isRider) return _riderNavItems;
      if (authState.isLender) return _borrowerNavItems;
    }
    return _borrowerNavItems;
  }

  List<Widget> get _pages {
    final authState = ref.read(authProvider);
    if (authState is AppAuthAuthenticated) {
      if (authState.isRider) {
        return const [
          RiderTodayPage(),
          RiderMapPage(),
          RiderHistoryPage(),
          RiderProfilePage(),
        ];
      }
      if (authState.isLender) {
        return const [
          LenderLoanPage(),
          LenderPaymentsPage(),
          LenderNotificationsPage(),
          LenderProfilePage(),
        ];
      }
    }
    return const [
      LenderLoanPage(),
      LenderPaymentsPage(),
      LenderNotificationsPage(),
      LenderProfilePage(),
    ];
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    final navItems = _navItems;
    if (index < navItems.length) {
      context.go(navItems[index].route);
    }
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final navItems = _navItems;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
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
              final isActive = index == _currentIndex;

              return _FloatingNavItem(
                item: item,
                isActive: isActive,
                isLight: isLight,
                onTap: () => _onNavItemTapped(index),
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
