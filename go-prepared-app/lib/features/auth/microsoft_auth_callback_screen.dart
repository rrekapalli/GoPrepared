import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/oauth_browser.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_providers.dart';

/// Handles Microsoft OAuth redirect flow completion at `/auth`.
class MicrosoftAuthCallbackScreen extends ConsumerStatefulWidget {
  const MicrosoftAuthCallbackScreen({super.key});

  @override
  ConsumerState<MicrosoftAuthCallbackScreen> createState() => _MicrosoftAuthCallbackScreenState();
}

class _MicrosoftAuthCallbackScreenState extends ConsumerState<MicrosoftAuthCallbackScreen> {
  String? _error;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  Future<void> _complete() async {
    if (_started) return;
    _started = true;

    if (isMicrosoftOAuthSessionInProgress) {
      if (mounted) {
        setState(() => _error = 'Microsoft sign-in is already in progress. Close extra tabs and try again.');
      }
      return;
    }
    setMicrosoftOAuthSessionFlag();

    final msalError = takeMicrosoftOAuthError();
    if (msalError != null) {
      clearMicrosoftOAuthSessionFlag();
      clearMicrosoftOAuthRedirectState();
      if (mounted) setState(() => _error = msalError);
      return;
    }

    try {
      await ref.read(oauthConfigProvider.future);
      await ref.read(authNotifierProvider.notifier).completeMicrosoftRedirect();
      if (mounted) context.go('/home');
    } on AuthCancelledException {
      clearMicrosoftOAuthSessionFlag();
      clearMicrosoftOAuthRedirectState();
      clearOAuthBrowserUrl('/login');
      if (mounted) context.go('/login');
    } catch (e) {
      clearMicrosoftOAuthSessionFlag();
      clearMicrosoftOAuthRedirectState();
      clearOAuthBrowserUrl('/login');
      if (mounted) {
        setState(() => _error = _formatAuthError(e));
      }
    }
  }

  String _formatAuthError(Object error) {
    if (error is DioException) {
      return friendlyApiError(error);
    }
    final text = error.toString();
    return text.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_error == null) ...[
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Completing Microsoft sign-in…',
                      style: TextStyle(color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Back to sign in'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
