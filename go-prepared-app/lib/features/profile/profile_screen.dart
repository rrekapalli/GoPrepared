import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/journey_repository.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/auth/guest_sign_in_prompt.dart';
import '../../shared/widgets/app_logo.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  ProfileStatsModel? _stats;
  bool _loadingStats = true;
  bool _reminders = true;
  bool _checklistUpdates = true;
  bool _communityAlerts = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      await ref.read(sessionProvider.future);
      final stats = await ref.read(journeyRepositoryProvider).profileStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final user = auth.valueOrNull?.user;
    final stats = _stats;

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return const Scaffold(body: GuestSignInPrompt(from: '/me'));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: user.profilePicture != null
                  ? CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: NetworkImage(user.profilePicture!),
                    )
                  : const AppLogo(size: 88),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(user.email, style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Center(
              child: Chip(
                avatar: Icon(Icons.check_circle, size: 16, color: Colors.green),
                label: Text('Account Connected'),
              ),
            ),
            const SizedBox(height: 24),
            if (_loadingStats)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard('${stats?.journeysCreated ?? 0}', 'Journeys Created'),
                  _StatCard('${stats?.cardsCompleted ?? 0}', 'Cards Completed'),
                  _StatCard('${stats?.checklistItemsCompleted ?? 0}', 'Checklist Done'),
                  _StatCard('${stats?.impactScore ?? 0}', 'Impact Score'),
                ],
              ),
            const SizedBox(height: 24),
            const Text(
              'NOTIFICATION SETTINGS',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
            ),
            SwitchListTile(
              title: const Text('Reminders'),
              subtitle: const Text('Journey deadlines and prep nudges'),
              value: _reminders,
              onChanged: (v) => setState(() => _reminders = v),
            ),
            SwitchListTile(
              title: const Text('Checklist Updates'),
              subtitle: const Text('When checklist items are suggested'),
              value: _checklistUpdates,
              onChanged: (v) => setState(() => _checklistUpdates = v),
            ),
            SwitchListTile(
              title: const Text('Community Alerts'),
              subtitle: const Text('New tips for your journey types'),
              value: _communityAlerts,
              onChanged: (v) => setState(() => _communityAlerts = v),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
