import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

import '../../data/models/ai_models.dart';

import '../../data/repositories/journey_repository.dart';



class ProfileScreen extends ConsumerStatefulWidget {

  const ProfileScreen({super.key});



  @override

  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();

}



class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  UserModel? _user;

  ProfileStatsModel? _stats;

  bool _loading = true;

  bool _reminders = true;

  bool _checklistUpdates = true;

  bool _communityAlerts = false;



  @override

  void initState() {

    super.initState();

    _load();

  }



  Future<void> _load() async {

    try {

      await ref.read(sessionProvider.future);

      final user = await ref.read(authRepositoryProvider).me();

      final stats = await ref.read(journeyRepositoryProvider).profileStats();

      if (mounted) setState(() { _user = user; _stats = stats; _loading = false; });

    } catch (_) {

      if (mounted) setState(() => _loading = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    final user = _user;

    final stats = _stats;



    return Scaffold(

      body: _loading

          ? const Center(child: CircularProgressIndicator())

          : RefreshIndicator(

              onRefresh: _load,

              child: ListView(

                padding: const EdgeInsets.all(16),

                children: [

                  Center(

                    child: CircleAvatar(

                      radius: 44,

                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),

                      backgroundImage: user?.profilePicture != null ? NetworkImage(user!.profilePicture!) : null,

                      child: user?.profilePicture == null ? Text(user?.name.substring(0, 1).toUpperCase() ?? '?', style: const TextStyle(fontSize: 32, color: AppColors.primary)) : null,

                    ),

                  ),

                  const SizedBox(height: 12),

                  Text(user?.name ?? 'Guest', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),

                  Text(user?.email ?? '', style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),

                  const SizedBox(height: 8),

                  Center(

                    child: Chip(

                      avatar: Icon(user != null ? Icons.check_circle : Icons.info_outline, size: 16, color: user != null ? Colors.green : Colors.grey),

                      label: Text(user != null ? 'Account Connected' : 'Not signed in'),

                    ),

                  ),

                  const SizedBox(height: 24),

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

                  const Text('NOTIFICATION SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),

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

                    onPressed: () async {

                      await ref.read(authRepositoryProvider).devLogin(email: user?.email ?? 'dev@goprepared.app', name: user?.name ?? 'Dev User');

                      _load();

                    },

                    icon: const Icon(Icons.refresh),

                    label: const Text('Refresh session'),

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

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),

          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),

        ]),

      ),

    );

  }

}


