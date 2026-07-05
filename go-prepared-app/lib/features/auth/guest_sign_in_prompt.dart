import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_logo.dart';

/// Shown on /me when the user is not signed in (works inside shell — no redirect fight).
class GuestSignInPrompt extends StatelessWidget {
  const GuestSignInPrompt({super.key, this.from = '/me'});

  final String from;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Center(child: AppLogo(size: 88)),
        const SizedBox(height: 20),
        Text(
          'Sign in to GoPrepared',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Track journeys, checklists, and your profile across devices.',
          style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.go('/login?from=${Uri.encodeComponent(from)}'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Sign in'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.go('/explore'),
          child: const Text('Browse Explore without signing in'),
        ),
      ],
    );
  }
}
