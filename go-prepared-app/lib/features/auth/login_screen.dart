import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/oauth_browser.dart';
import '../../core/config/app_config.dart';
import '../../core/config/oauth_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/app_logo.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;
  bool _showDevLogin = false;
  final _devEmailController = TextEditingController(text: 'dev@goprepared.app');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msalError = takeMicrosoftOAuthError();
      if (msalError != null && mounted) {
        setState(() => _error = msalError);
      }
    });
  }

  @override
  void dispose() {
    _devEmailController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) {
        final loggedIn = ref.read(authNotifierProvider).valueOrNull != null;
        if (loggedIn) {
          final from = GoRouterState.of(context).uri.queryParameters['from'];
          if (from != null && from.isNotEmpty) {
            context.go(from);
          } else {
            context.go('/home');
          }
        }
      }
    } on AuthCancelledException {
      if (mounted) setState(() => _loading = false);
      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _formatLoginError(e);
        });
      }
      return;
    }
    if (mounted) setState(() => _loading = false);
  }

  String _formatLoginError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 502 || status == 503) {
        return 'API server unavailable ($status). The backend may be restarting — try again in a minute.';
      }
      return friendlyApiError(error);
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final canDevLogin = kDebugMode && AppConfig.devAuthEnabled;
    final oauthAsync = ref.watch(oauthConfigProvider);
    final config = oauthAsync.value ?? OAuthConfig.fromAppConfig();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo(size: 88)),
                  const SizedBox(height: 24),
                  Text(
                    'Be Ready Anywhere',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to create journeys, track checklists, and join the community.',
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (oauthAsync.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Loading sign-in options…',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _buildSignInButtons(context, canDevLogin, config),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButtons(BuildContext context, bool canDevLogin, OAuthConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                  FilledButton.icon(
                    onPressed: _loading || !config.hasGoogle
                        ? null
                        : () => _run(() => ref.read(authNotifierProvider.notifier).loginWithGoogle()),
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (!config.hasGoogle)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Google sign-in requires GOOGLE_CLIENT_ID in API .env.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loading || !config.hasMicrosoft
                        ? null
                        : () => _run(() => ref.read(authNotifierProvider.notifier).loginWithMicrosoft()),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Continue with Microsoft'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  if (!config.hasMicrosoft)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Microsoft sign-in requires MICROSOFT_CLIENT_ID in API .env.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/explore'),
                    child: const Text('Browse Explore without signing in'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (canDevLogin) ...[
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _loading ? null : () => setState(() => _showDevLogin = !_showDevLogin),
                      child: Text(_showDevLogin ? 'Hide dev login' : 'Dev login'),
                    ),
                    if (_showDevLogin) ...[
                      TextField(
                        controller: _devEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Dev email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () => _run(() => ref.read(authNotifierProvider.notifier).devLogin(
                                  email: _devEmailController.text.trim(),
                                )),
                        child: const Text('Sign in as dev user'),
                      ),
                    ],
                  ],
      ],
    );
  }
}
