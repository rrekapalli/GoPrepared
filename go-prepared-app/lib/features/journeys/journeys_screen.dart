import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/journey_repository.dart';
import '../../shared/widgets/ui_helpers.dart';

enum _JourneyFilter { recent, upcoming, archived }

class JourneysScreen extends ConsumerStatefulWidget {
  const JourneysScreen({super.key});

  @override
  ConsumerState<JourneysScreen> createState() => _JourneysScreenState();
}

class _JourneysScreenState extends ConsumerState<JourneysScreen> {
  List<JourneyModel> _journeys = [];
  bool _loading = true;
  bool _usingDemo = false;
  String _search = '';
  _JourneyFilter _filter = _JourneyFilter.recent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await ref.read(sessionProvider.future);
      final list = await ref.read(journeyRepositoryProvider).listJourneys();
      if (!mounted) return;
      setState(() {
        if (list.isEmpty) {
          _journeys = DemoData.journeysWithDates;
          _usingDemo = true;
        } else {
          _journeys = list;
          _usingDemo = false;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _journeys = DemoData.journeysWithDates;
          _usingDemo = true;
          _loading = false;
        });
      }
    }
  }

  List<JourneyModel> get _filtered {
    var list = _journeys;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((j) =>
          j.title.toLowerCase().contains(q) ||
          j.originalQuery.toLowerCase().contains(q)).toList();
    }
    return switch (_filter) {
      _JourneyFilter.recent => list,
      _JourneyFilter.upcoming => list.where((j) => !j.isComplete).toList(),
      _JourneyFilter.archived => list.where((j) => j.isComplete).toList(),
    };
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                        if (_usingDemo) const _DemoBanner(),
                        Text(
                          'Journeys',
                          style: TextStyle(
                            fontSize: 26,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _TopSearchField(
                          onChanged: (v) => setState(() => _search = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _FilterChip(
                              label: 'Recent',
                              selected: _filter == _JourneyFilter.recent,
                              onTap: () => setState(() => _filter = _JourneyFilter.recent),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Upcoming',
                              selected: _filter == _JourneyFilter.upcoming,
                              onTap: () => setState(() => _filter = _JourneyFilter.upcoming),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Archived',
                              selected: _filter == _JourneyFilter.archived,
                              onTap: () => setState(() => _filter = _JourneyFilter.archived),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._filtered.map((j) => _JourneyCard(journey: j)),
                        if (_filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Column(
                              children: [
                                Icon(Icons.explore_outlined, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  _journeys.isEmpty
                                      ? 'No journeys yet. Start from Home.'
                                      : 'No journeys match your search.',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 72),
                      ],
                    ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          elevation: 4,
          onPressed: () => context.go('/home'),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories_outlined, size: 18, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sample journeys — connect API for your own data',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSearchField extends StatelessWidget {
  const _TopSearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search your preparations...',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFECEFF1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF546E7A),
          ),
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.journey});
  final JourneyModel journey;

  String get _actionLabel => 'OPEN →';

  String get _subtitle {
    final q = journey.originalQuery;
    if (q.length > 42) return '${q.substring(0, 42)}...';
    return q;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/journeys/${journey.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              journeyThumbnail(journey, size: 76),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            journey.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade500),
                          padding: EdgeInsets.zero,
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'hub', child: Text('Open hub')),
                            const PopupMenuItem(value: 'deck', child: Text('Open deck')),
                            const PopupMenuItem(value: 'checklist', child: Text('Checklist')),
                          ],
                          onSelected: (v) {
                            if (v == 'hub') context.go('/journeys/${journey.id}');
                            if (v == 'deck') context.push('/journeys/${journey.id}/deck');
                            if (v == 'checklist') context.push('/journeys/${journey.id}/checklist');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatJourneyDate(journey.createdAt),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.go('/journeys/${journey.id}'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _actionLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
