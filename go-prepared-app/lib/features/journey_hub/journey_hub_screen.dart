import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/journey_repository.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/ui_helpers.dart';

class JourneyHubScreen extends ConsumerStatefulWidget {
  const JourneyHubScreen({super.key, required this.journeyId});

  final int journeyId;

  @override
  ConsumerState<JourneyHubScreen> createState() => _JourneyHubScreenState();
}

class _JourneyHubScreenState extends ConsumerState<JourneyHubScreen> {
  JourneyModel? _journey;
  JourneyStatusModel? _status;
  List<CardModel> _cards = [];
  ChecklistModel? _checklist;
  List<CommunityInsightModel> _insights = [];
  bool _loading = true;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (DemoData.isDemoJourney(widget.journeyId)) {
      final journey = DemoData.journeyById(widget.journeyId);
      if (journey == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final cards = DemoData.cardsForJourney(widget.journeyId);
      if (!mounted) return;
      setState(() {
        _journey = journey;
        _status = JourneyStatusModel(
          journeyId: journey.id,
          status: journey.status,
          progressPercent: journey.progressPercent,
          cardsCompleted: cards.where((c) => c.viewed).length,
          cardsTotal: cards.length,
          checklistCompleted: 0,
          checklistTotal: 0,
        );
        _cards = cards;
        _loading = false;
        _showCelebration = journey.progressPercent >= 100;
      });
      return;
    }

    try {
      await ref.read(sessionProvider.future);
      final repo = ref.read(journeyRepositoryProvider);
      final knowledgeRepo = ref.read(knowledgeRepositoryProvider);
      final results = await Future.wait([
        repo.getJourney(widget.journeyId),
        repo.getJourneyStatus(widget.journeyId),
        repo.getCards(widget.journeyId),
        repo.getChecklist(widget.journeyId),
        knowledgeRepo.communityForJourney(widget.journeyId),
      ]);
      if (!mounted) return;
      final journey = results[0] as JourneyModel;
      final status = results[1] as JourneyStatusModel;
      setState(() {
        _journey = journey;
        _status = status;
        _cards = results[2] as List<CardModel>;
        _checklist = results[3] as ChecklistModel;
        _insights = results[4] as List<CommunityInsightModel>;
        _loading = false;
        _showCelebration = status.progressPercent >= 100;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? get _firstUnviewedIndex {
    final idx = _cards.indexWhere((c) => !c.viewed);
    return idx >= 0 ? idx : null;
  }

  void _openDeck({int? cardIndex}) {
    final idx = cardIndex ?? _firstUnviewedIndex;
    final path = idx != null
        ? '/journeys/${widget.journeyId}/deck?cardIndex=$idx'
        : '/journeys/${widget.journeyId}/deck';
    context.push(path);
  }

  List<ChecklistItemModel> get _checklistPreview {
    final items = _checklist?.items ?? [];
    final incomplete = items.where((i) => !i.completed).take(3).toList();
    return incomplete.isNotEmpty ? incomplete : items.take(3).toList();
  }

  void _showContribute() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    var type = 'TIP';
    final journey = _journey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Share insight', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['TIP', 'WARNING', 'EXPERIENCE'].map((t) {
                  return ChoiceChip(
                    label: Text(t),
                    selected: type == t,
                    onSelected: (_) => setModalState(() => type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Your insight', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || contentCtrl.text.isEmpty) return;
                  try {
                    await ref.read(sessionProvider.future);
                    await ref.read(knowledgeRepositoryProvider).contribute(
                          insightType: type,
                          title: titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          journeyId: widget.journeyId > 0 ? widget.journeyId : null,
                          journeyContext: journey?.title,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (_) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Could not submit')));
                  }
                },
                child: const Text('Contribute'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final journey = _journey;
    final status = _status;
    if (journey == null || status == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/journeys'))),
        body: const Center(child: Text('Journey not found')),
      );
    }

    final nextCard = _firstUnviewedIndex != null ? _cards[_firstUnviewedIndex!] : null;
    final warnings = _insights.where((i) => i.insightType == 'WARNING').take(2).toList();
    final tips = _insights.where((i) => i.insightType == 'TIP').take(1).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppTopHeader(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => context.go('/journeys'),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (_showCelebration) _celebrationBanner(),
                  Text(
                    journey.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (journey.journeyType != null && journey.journeyType!.isNotEmpty)
                        Chip(label: Text(journey.journeyType!), visualDensity: VisualDensity.compact),
                      if (journey.journeySubtype != null && journey.journeySubtype!.isNotEmpty)
                        Chip(label: Text(journey.journeySubtype!), visualDensity: VisualDensity.compact),
                      if (journey.location != null && journey.location!.isNotEmpty)
                        Chip(label: Text(journey.location!), visualDensity: VisualDensity.compact),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _progressCard(status),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openDeck(),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(nextCard != null ? 'Continue prep: ${nextCard.title}' : 'Open prep deck'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _actionTile(Icons.style_outlined, 'Prep deck', '${status.cardsCompleted}/${status.cardsTotal} cards', () => _openDeck())),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionTile(
                          Icons.checklist,
                          'Checklist',
                          '${status.checklistCompleted}/${status.checklistTotal} done',
                          () => context.push('/journeys/${widget.journeyId}/checklist'),
                        ),
                      ),
                    ],
                  ),
                  if (_checklistPreview.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Checklist preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => context.push('/journeys/${widget.journeyId}/checklist'),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    ..._checklistPreview.map(_checklistPreviewTile),
                  ],
                  if (warnings.isNotEmpty || tips.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Community insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _showContribute,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Share tip'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...warnings.map((i) => _insightTile(i)),
                    ...tips.map((i) => _insightTile(i)),
                  ] else ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _showContribute,
                      icon: const Icon(Icons.add),
                      label: const Text('Share a tip for this journey'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _celebrationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade400]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.celebration, color: Colors.white, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prep kit complete!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('You are ready for your journey.', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard(JourneyStatusModel status) {
    final progress = (status.progressPercent / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white,
                  color: AppColors.primary,
                ),
                Text(
                  '${status.progressPercent}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statColumn('Cards', '${status.cardsCompleted}/${status.cardsTotal}'),
              _statColumn('Checklist', '${status.checklistCompleted}/${status.checklistTotal}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checklistPreviewTile(ChecklistItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        leading: Icon(
          item.completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: item.completed ? AppColors.primary : Colors.grey.shade400,
        ),
        title: Text(item.title, style: TextStyle(decoration: item.completed ? TextDecoration.lineThrough : null)),
        onTap: () => context.push('/journeys/${widget.journeyId}/checklist'),
      ),
    );
  }

  Widget _insightTile(CommunityInsightModel insight) {
    final color = insightTypeColor(insight.insightType);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.lightbulb_outline, color: color),
        title: Text(insight.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(insight.content, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
