import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/token_storage.dart';
import 'core/config/app_config.dart';
import 'core/config/url_strategy_stub.dart'
    if (dart.library.html) 'core/config/url_strategy_web.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'features/auth/auth_providers.dart';
import 'core/network/api_client.dart';

/// Prevents Material 3 primary-colored stretch glow on web scroll.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class GoPreparedApp extends ConsumerWidget {
  const GoPreparedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'GoPrepared',
      theme: AppTheme.light(),
      scrollBehavior: _AppScrollBehavior(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ColoredBox(
          color: Colors.white,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  AppConfig.init();
  final storedToken = await tokenStorage.readToken();
  final hasStoredToken = storedToken != null && storedToken.isNotEmpty;
  runApp(
    ProviderScope(
      overrides: [
        authBootstrapHintProvider.overrideWith((ref) => hasStoredToken),
        authRepositoryProvider.overrideWith(
          (ref) => AuthRepository(ref.watch(dioProvider), navigatorKey: rootNavigatorKey),
        ),
      ],
      child: const GoPreparedApp(),
    ),
  );
}
