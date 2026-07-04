import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/card_detail/card_detail_screen.dart';
import '../../features/checklist/checklist_screen.dart';
import '../../features/deck/deck_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/journey_hub/journey_hub_screen.dart';
import '../../features/journeys/journeys_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../shared/widgets/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

bool isPublicRoute(String location) {
  return location == '/login' || location.startsWith('/explore');
}

bool isProtectedRoute(String location) {
  if (isPublicRoute(location)) return false;
  return location.startsWith('/home') ||
      location.startsWith('/journeys') ||
      location.startsWith('/me') ||
      location.startsWith('/cards');
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshNotifierProvider);

  ref.listen(authNotifierProvider, (_, __) => refresh.refresh());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final auth = ref.read(authNotifierProvider);

      if (auth.isLoading) return null;

      final loggedIn = auth.valueOrNull != null;
      final onLogin = location == '/login';

      if (!loggedIn && isProtectedRoute(location)) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }

      if (loggedIn && onLogin) {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty && isProtectedRoute(from)) {
          return from;
        }
        return '/home';
      }

      if (location == '/discover') return '/home';
      if (location == '/knowledge') return '/explore';
      if (location == '/community') return '/journeys';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (_, state) {
                final q = state.uri.queryParameters['q'];
                return DiscoverScreen(initialQuery: q);
              },
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/journeys', builder: (_, __) => const JourneysScreen())]),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/explore', builder: (_, __) => const ExploreScreen()),
            ],
          ),
          StatefulShellBranch(routes: [GoRoute(path: '/me', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
      GoRoute(
        path: '/journeys/:id',
        builder: (_, state) {
          final tab = state.uri.queryParameters['tab'];
          final initialTab = tab == 'community' ? 1 : 0;
          return JourneyHubScreen(
            journeyId: int.parse(state.pathParameters['id']!),
            initialTab: initialTab,
          );
        },
      ),
      GoRoute(
        path: '/journeys/:id/deck',
        builder: (_, state) {
          final cardIndex = int.tryParse(state.uri.queryParameters['cardIndex'] ?? '');
          return DeckScreen(
            journeyId: int.parse(state.pathParameters['id']!),
            initialCardIndex: cardIndex,
          );
        },
      ),
      GoRoute(
        path: '/cards/:id',
        builder: (_, state) {
          final journeyId = int.tryParse(state.uri.queryParameters['journeyId'] ?? '');
          return CardDetailScreen(
            cardId: int.parse(state.pathParameters['id']!),
            journeyId: journeyId,
          );
        },
      ),
      GoRoute(
        path: '/journeys/:id/checklist',
        builder: (_, state) => ChecklistScreen(
          journeyId: int.parse(state.pathParameters['id']!),
          categoryFilter: state.uri.queryParameters['category'],
          pageTitle: state.uri.queryParameters['title'],
        ),
      ),
    ],
  );
});
