import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

import '../../core/responsive/breakpoints.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/journey_repository.dart';

import '../../shared/widgets/ui_helpers.dart';



class DiscoverScreen extends ConsumerStatefulWidget {

  const DiscoverScreen({super.key});



  @override

  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();

}



class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {

  bool _loading = false;



  Future<void> _generate(String query) async {

    if (query.isEmpty) return;

    setState(() => _loading = true);

    try {

      await ref.read(sessionProvider.future);

      final journey = await ref.read(journeyRepositoryProvider).createJourney(query);

      await ref.read(journeyRepositoryProvider).generateCards(journey.id);

      if (mounted) context.go('/journeys/${journey.id}/deck');

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyApiError(e))));

      }

    } finally {

      if (mounted) setState(() => _loading = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    final maxW = Breakpoints.contentMaxWidth(context);

    return Scaffold(
      body: Center(

        child: ConstrainedBox(

          constraints: BoxConstraints(maxWidth: maxW),

          child: ListView(

            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),

            children: [

              RichText(

                text: TextSpan(

                  style: Theme.of(context).textTheme.headlineLarge,

                  children: [

                    const TextSpan(text: 'Every journey begins with '),

                    TextSpan(text: 'Preparation.', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),

                  ],

                ),

              ),

              const SizedBox(height: 8),

              Text(

                'AI-powered checklists and guides tailored to your specific situation, from travel to healthcare.',

                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),

              ),

              const SizedBox(height: 20),

              Text('Try these:', style: Theme.of(context).textTheme.labelLarge),

              const SizedBox(height: 8),

              Wrap(

                spacing: 8,

                runSpacing: 8,

                children: [

                  _chip('Vacation to Bali', () => _generate('Vacation to Bali')),

                  _chip('10K Run in Vizag', () => _generate('10K Run in Vizag')),

                  _chip('Going for an angiogram', () => _generate('Going for an angiogram')),

                ],

              ),

              const SizedBox(height: 24),

              _featureCard('Location Aware', 'Weather and local regulations integrated automatically.', Icons.explore, Colors.grey.shade100),

              _featureCard('Expert Verified', 'Medical and safety tips sourced from official guidelines.', Icons.verified_user, AppColors.primary, lightText: true),

              _featureCard('Save for Later', 'Access your prep kits offline, anytime, anywhere.', Icons.bookmark_border, Colors.grey.shade100),

              const SizedBox(height: 16),

              _exploreCard(context),

            ],

          ),

        ),

      ),

      bottomSheet: Material(

        color: Colors.transparent,

        child: QueryBar(hint: 'What are you preparing for?', onSubmit: _generate, loading: _loading),

      ),

    );

  }



  Widget _chip(String label, VoidCallback onTap) => ActionChip(

        label: Text(label),

        backgroundColor: Colors.grey.shade100,

        onPressed: _loading ? null : onTap,

      );



  Widget _featureCard(String title, String body, IconData icon, Color bg, {bool lightText = false}) {

    return Container(

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppColors.cardRadius)),

      child: Row(

        children: [

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: lightText ? Colors.white : Colors.black)),

                const SizedBox(height: 4),

                Text(body, style: TextStyle(color: lightText ? Colors.white70 : Colors.black54)),

              ],

            ),

          ),

          CircleAvatar(

            backgroundColor: lightText ? Colors.white.withValues(alpha: 0.24) : AppColors.primary.withValues(alpha: 0.1),

            child: Icon(icon, color: lightText ? Colors.white : AppColors.primary),

          ),

        ],

      ),

    );

  }



  Widget _exploreCard(BuildContext context) {

    return GestureDetector(

      onTap: () => context.go('/knowledge'),

      child: Container(

        height: 160,

        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(AppColors.cardRadius),

          gradient: const LinearGradient(

            colors: [Color(0xFF0277BD), Color(0xFF4FC3F7)],

            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

          ),

        ),

        child: Stack(

          children: [

            Positioned(

              right: -20,

              bottom: -20,

              child: Icon(Icons.luggage, size: 120, color: Colors.white.withValues(alpha: 0.15)),

            ),

            Padding(

              padding: const EdgeInsets.all(20),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                mainAxisAlignment: MainAxisAlignment.end,

                children: [

                  Text('Explore Prep Guides', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 4),

                  Text('Trending preparations for the season', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }

}


