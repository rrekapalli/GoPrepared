import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/oauth_config.dart';
import '../../core/network/api_client.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/auth_repository.dart';

/// Public OAuth client IDs from compile-time defines or GET /auth/config.
final oauthConfigProvider = FutureProvider<OAuthConfig>((ref) async {
  final config = await OAuthConfig.load(ref.read(dioProvider));
  ref.read(authRepositoryProvider).applyOAuthConfig(config);
  return config;
});

/// Notifies [GoRouter] when auth state changes.
final routerRefreshNotifierProvider = Provider<GoRouterRefreshNotifier>((ref) {
  final notifier = GoRouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('authRepositoryProvider must be overridden');
});

/// Set at startup from secure storage — lets the router wait for session restore when a token exists.
final authBootstrapHintProvider = Provider<bool>((ref) => false);

class AuthSession {
  const AuthSession({required this.user});

  final UserModel user;
}

class AuthNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final repo = ref.read(authRepositoryProvider);
    if (!await repo.isAuthenticated()) return null;
    try {
      final user = await repo.me().timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw AuthSessionTimeoutException(),
      );
      return AuthSession(user: user);
    } on AuthSessionTimeoutException {
      await repo.logout();
      return null;
    } catch (_) {
      await repo.logout();
      return null;
    }
  }

  Future<UserModel> loginWithGoogle() async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).loginWithGoogle();
      final session = AuthSession(user: user);
      state = AsyncData(session);
      ref.read(routerRefreshNotifierProvider).refresh();
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<UserModel> loginWithMicrosoft() async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).loginWithMicrosoft();
      final session = AuthSession(user: user);
      state = AsyncData(session);
      ref.read(routerRefreshNotifierProvider).refresh();
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<UserModel> completeMicrosoftRedirect() async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).completeMicrosoftRedirect();
      final session = AuthSession(user: user);
      state = AsyncData(session);
      ref.read(routerRefreshNotifierProvider).refresh();
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<UserModel> devLogin({String email = 'dev@goprepared.app', String name = 'Dev User'}) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).devLogin(email: email, name: name);
      final session = AuthSession(user: user);
      state = AsyncData(session);
      ref.read(routerRefreshNotifierProvider).refresh();
      return user;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
    ref.read(routerRefreshNotifierProvider).refresh();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).currentUser();
      return user == null ? null : AuthSession(user: user);
    });
    ref.read(routerRefreshNotifierProvider).refresh();
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthSession?>(AuthNotifier.new);

/// Legacy hook for screens that awaited session bootstrap — no-op when router guards auth.
final sessionProvider = FutureProvider<void>((ref) async {
  await ref.watch(authNotifierProvider.future);
});

class GoRouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

class AuthSessionTimeoutException implements Exception {}
