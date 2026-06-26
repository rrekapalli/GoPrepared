import 'package:go_router/go_router.dart';
import '../../features/card_detail/card_detail_screen.dart';
import '../../features/checklist/checklist_screen.dart';
import '../../features/community/community_screen.dart';
import '../../features/deck/deck_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/journeys/journeys_screen.dart';
import '../../features/knowledge/knowledge_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../shared/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/discover',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/journeys', builder: (_, __) => const JourneysScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/knowledge', builder: (_, __) => const KnowledgeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/community', builder: (_, __) => const CommunityScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/me', builder: (_, __) => const ProfileScreen())]),
      ],
    ),
    GoRoute(
      path: '/journeys/:id/deck',
      builder: (_, state) => DeckScreen(journeyId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/cards/:id',
      builder: (_, state) => CardDetailScreen(cardId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/journeys/:id/checklist',
      builder: (_, state) => ChecklistScreen(journeyId: int.parse(state.pathParameters['id']!)),
    ),
  ],
);
