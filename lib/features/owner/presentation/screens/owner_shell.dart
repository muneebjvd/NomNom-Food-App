import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

import '../../../../core/theme/app_theme.dart';

class OwnerShell extends ConsumerWidget {
  const OwnerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/owner/orders')) {
      currentIndex = 1;
    } else if (location.startsWith('/owner/menu')) {
      currentIndex = 2;
    } else if (location.startsWith('/owner/analytics')) {
      currentIndex = 3;
    } else if (location.startsWith('/owner/profile')) {
      currentIndex = 4;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: false,
      body: child,
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: AppColors.surfaceLighter, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _OwnerNavItem(icon: IconlyLight.home, activeIcon: IconlyBold.home, label: 'Dashboard', isActive: currentIndex == 0, onTap: () => context.go('/owner/dashboard')),
            _OwnerNavItem(icon: IconlyLight.bag2, activeIcon: IconlyBold.bag2, label: 'Orders', isActive: currentIndex == 1, onTap: () => context.go('/owner/orders')),
            _OwnerNavItem(icon: IconlyLight.document, activeIcon: IconlyBold.document, label: 'Menu', isActive: currentIndex == 2, onTap: () => context.go('/owner/menu')),
            _OwnerNavItem(icon: IconlyLight.chart, activeIcon: IconlyBold.chart, label: 'Analytics', isActive: currentIndex == 3, onTap: () => context.go('/owner/analytics')),
            _OwnerNavItem(icon: IconlyLight.profile, activeIcon: IconlyBold.profile, label: 'Profile', isActive: currentIndex == 4, onTap: () => context.go('/owner/profile')),
          ],
        ),
      ),
    );
  }
}

class _OwnerNavItem extends StatelessWidget {
  const _OwnerNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.primaryDark : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive ? AppColors.primaryDark : AppColors.textMuted,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                fontSize: 11,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
