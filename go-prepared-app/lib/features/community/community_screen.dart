import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/journey_repository.dart';
import '../../shared/widgets/ui_helpers.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key, this.embedded = false, this.journeyId, this.journeyContext});

  final bool embedded;
  final int? journeyId;
  final String? journeyContext;

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  List<CommunityInsightModel> _insights = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(knowledgeRepositoryProvider);
      final insights = widget.journeyId != null
          ? await repo.communityForJourney(widget.journeyId!)
          : await repo.community();
      if (mounted) setState(() { _insights = insights; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _vote(int id, bool helpful) async {
    try {
      await ref.read(sessionProvider.future);
      final votes = await ref.read(knowledgeRepositoryProvider).voteInsight(id, helpful: helpful);
      if (!mounted) return;
      setState(() {
        _insights = _insights.map((i) => i.id == id ? CommunityInsightModel(
          id: i.id,
          insightType: i.insightType,
          title: i.title,
          content: i.content,
          journeyContext: i.journeyContext,
          severity: i.severity,
          votes: votes,
        ) : i).toList();
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to vote')));
    }
  }

  void _showContributeSheet() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    var type = 'TIP';

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
              Text('Share your wisdom', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: ['TIP', 'WARNING', 'EXPERIENCE', 'UPDATE'].map((t) {
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
              TextField(controller: contentCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'What do you wish you had known?', border: OutlineInputBorder())),
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
                          journeyId: widget.journeyId,
                          journeyContext: widget.journeyContext,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (_) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Could not submit insight')));
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
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, widget.embedded ? 24 : 88),
              children: [
                GestureDetector(
                  onTap: _showContributeSheet,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Share your wisdom', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Share something you wish you had known beforehand to help others stay prepared', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Featured Insights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_insights.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No insights yet. Be the first to contribute!', style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
                  ),
                ..._insights.map((i) => _InsightCard(insight: i, onVote: _vote)),
              ],
            ),
          );

    if (widget.embedded) {
      return Stack(
        children: [
          body,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _showContributeSheet,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Contribute', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showContributeSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Contribute', style: TextStyle(color: Colors.white)),
      ),
      body: body,
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.onVote});
  final CommunityInsightModel insight;
  final void Function(int id, bool helpful) onVote;

  @override
  Widget build(BuildContext context) {
    final typeColor = insightTypeColor(insight.insightType);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(insightTypeLabel(insight.insightType), style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                if (insight.journeyContext != null)
                  Text(insight.journeyContext!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(insight.content),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${insight.votes}', style: TextStyle(color: Colors.grey.shade700)),
                const Spacer(),
                TextButton(onPressed: () => onVote(insight.id, true), child: const Text('Helpful')),
                TextButton(onPressed: () => onVote(insight.id, false), child: const Text('Not really')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
