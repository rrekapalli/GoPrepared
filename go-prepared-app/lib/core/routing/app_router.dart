import 'package:go_router/go_router.dart';
import '../../features/card_detail/card_detail_screen.dart';
import '../../features/checklist/checklist_screen.dart';
import '../../features/deck/deck_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/journey_hub/journey_hub_screen.dart';
import '../../features/journeys/journeys_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../shared/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final path = state.uri.path;
    if (path == '/discover') return '/home';
    if (path == '/knowledge') return '/explore';
    if (path == '/community') return '/journeys';
    return null;
  },
  routes: [
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
