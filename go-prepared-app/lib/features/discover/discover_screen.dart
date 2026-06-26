import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/network/api_client.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/journey_repository.dart';
import '../../shared/widgets/ui_helpers.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  bool _loading = false;
  JourneyModel? _resumeJourney;

  @override
  void initState() {
    super.initState();
    _loadResume();
  }

  Future<void> _loadResume() async {
    try {
      await ref.read(sessionProvider.future);
      final list = await ref.read(journeyRepositoryProvider).listJourneys();
      final active = list.where((j) => j.progressPercent < 100).toList();
      if (mounted && active.isNotEmpty) {
        setState(() => _resumeJourney = active.first);
      }
    } catch (_) {}
  }

  Future<void> _generate(String query) async {
    if (query.isEmpty) return;

    try {
      await ref.read(sessionProvider.future);
      final repo = ref.read(journeyRepositoryProvider);
      final similar = await repo.findSimilarJourneys(query);
      final existing = similar.where((s) => s.isExistingJourney).toList();
      if (mounted && existing.isNotEmpty) {
        final choice = await _showSimilarSheet(existing.first);
        if (!mounted) return;
        if (choice == _SimilarChoice.resume) {
          context.go('/journeys/${existing.first.id}');
          return;
        }
        if (choice == _SimilarChoice.cancel) return;
      }
    } catch (_) {}

    setState(() => _loading = true);
    try {
      await ref.read(sessionProvider.future);
      final repo = ref.read(journeyRepositoryProvider);
      final journey = await repo.createJourney(query);

      if (mounted) {
        final confirmed = await _showClassificationSheet(journey);
        if (!mounted) return;
        if (!confirmed) {
          setState(() => _loading = false);
          return;
        }
      }

      await repo.generateCards(journey.id);
      if (mounted) context.go('/journeys/${journey.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<_SimilarChoice?> _showSimilarSheet(SimilarJourneyModel match) {
    return showModalBottomSheet<_SimilarChoice>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Similar preparation found', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('You already have "${match.title}". Resume it or create a new prep kit?'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, _SimilarChoice.resume),
              child: Text('Resume ${match.title}'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, _SimilarChoice.createNew),
              child: const Text('Create new'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx, _SimilarChoice.cancel), child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }

  Future<bool> _showClassificationSheet(JourneyModel journey) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('We understood:', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (journey.journeyType != null) Chip(label: Text(journey.journeyType!)),
                if (journey.journeySubtype != null) Chip(label: Text(journey.journeySubtype!)),
                if (journey.location != null && journey.location!.isNotEmpty) Chip(label: Text(journey.location!)),
              ],
            ),
            const SizedBox(height: 8),
            Text(journey.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate prep kit')),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Edit query')),
          ],
        ),
      ),
    );
    return result ?? false;
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
              if (_resumeJourney != null) _resumeCard(_resumeJourney!),
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
        child: QueryBar(
          hint: 'What are you preparing for?',
          onSubmit: _generate,
          loading: _loading,
          initialText: widget.initialQuery,
        ),
      ),
    );
  }

  Widget _resumeCard(JourneyModel journey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.go('/journeys/${journey.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resume preparation', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(journey.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${journey.progressPercent}% complete', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
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
      onTap: () => context.go('/explore'),
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

enum _SimilarChoice { resume, createNew, cancel }
