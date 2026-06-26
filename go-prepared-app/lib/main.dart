import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// Prevents Material 3 primary-colored stretch glow on web scroll.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class GoPreparedApp extends StatelessWidget {
  const GoPreparedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GoPrepared',
      theme: AppTheme.light(),
      scrollBehavior: _AppScrollBehavior(),
      routerConfig: appRouter,
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init();
  runApp(const ProviderScope(child: GoPreparedApp()));
}
