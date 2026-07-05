import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/routing/route_policy.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_providers.dart';
import 'app_logo.dart';

/// Fixed top bar — same on every main tab (matches bottom nav persistence).
class AppTopHeader extends StatelessWidget {
  const AppTopHeader({super.key, this.onNotifications, this.leading});

  final VoidCallback? onNotifications;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Row(
              children: [
                if (leading != null) leading!,
                const AppLogo(size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GoPrepared',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'BE READY ANYWHERE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.1,
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onNotifications,
                  icon: const Icon(Icons.notifications_none, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key, this.selectedIndex = 1, this.navigationShell});

  /// 0=Home, 1=Journeys, 2=Explore, 3=Me
  final int selectedIndex;
  final StatefulNavigationShell? navigationShell;

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    final route = AppShell.tabs[index];
    final auth = ref.read(authNotifierProvider);
    final loggedIn = auth.hasValue && auth.valueOrNull != null;
    final awaitingSession = auth.isLoading && ref.read(authBootstrapHintProvider);

    if (isProtectedRoute(route) && !loggedIn && !awaitingSession) {
      context.go('/login?from=${Uri.encodeComponent(route)}');
      return;
    }

    if (navigationShell != null) {
      navigationShell!.goBranch(index);
    } else {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                selected: selectedIndex == 0,
                onTap: () => _onTap(context, ref, 0),
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: 'Journeys',
                selected: selectedIndex == 1,
                onTap: () => _onTap(context, ref, 1),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book,
                label: 'Explore',
                selected: selectedIndex == 2,
                onTap: () => _onTap(context, ref, 2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Me',
                selected: selectedIndex == 3,
                onTap: () => _onTap(context, ref, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const tabs = ['/home', '/journeys', '/explore', '/me'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiHealth = ref.watch(apiHealthProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppTopHeader(),
          apiHealth.when(
            data: (ok) => ok ? const SizedBox.shrink() : _ApiOfflineBanner(onRetry: () => ref.invalidate(apiHealthProvider)),
            loading: () => const SizedBox(height: 2),
            error: (_, __) => _ApiOfflineBanner(onRetry: () => ref.invalidate(apiHealthProvider)),
          ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: AppBottomNav(selectedIndex: navigationShell.currentIndex, navigationShell: navigationShell),
    );
  }
}

class _ApiOfflineBanner extends StatelessWidget {
  const _ApiOfflineBanner({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 18, color: Colors.orange.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppConfig.apiUnreachableHint,
                style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry', style: TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: selected ? BoxDecoration(color: AppColors.primary, shape: BoxShape.circle) : null,
              child: Icon(selected ? selectedIcon : icon, size: 20, color: selected ? Colors.white : Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
