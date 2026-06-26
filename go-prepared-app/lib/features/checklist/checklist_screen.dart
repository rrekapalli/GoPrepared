import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/journey_repository.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/ui_helpers.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key, required this.journeyId});
  final int journeyId;

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  ChecklistModel? _checklist;
  List<CardModel> _cards = [];
  bool _loading = true;
  bool _asking = false;

  String get _hubFallback => '/journeys/${widget.journeyId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await ref.read(sessionProvider.future);
      final repo = ref.read(journeyRepositoryProvider);
      final checklist = await repo.getChecklist(widget.journeyId);
      List<CardModel> cards = [];
      try {
        cards = await repo.getCards(widget.journeyId);
      } catch (_) {}
      if (mounted) setState(() { _checklist = checklist; _cards = cards; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  CardModel? _cardForCategory(String category) {
    final c = category.toLowerCase();
    for (final card in _cards) {
      if (card.category.toLowerCase().contains(c) || card.title.toLowerCase().contains(c)) {
        return card;
      }
    }
    return null;
  }

  Future<void> _toggle(int itemId) async {
    try {
      final updated = await ref.read(journeyRepositoryProvider).toggleChecklistItem(itemId);
      if (!mounted || _checklist == null) return;
      final items = _checklist!.items.map((i) => i.id == itemId ? updated : i).toList();
      final done = items.where((i) => i.completed).length;
      setState(() {
        _checklist = ChecklistModel(
          journeyId: _checklist!.journeyId,
          title: _checklist!.title,
          completionPercent: items.isEmpty ? 0 : (done * 100 / items.length).round(),
          items: items,
        );
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update item')));
    }
  }

  Future<void> _ask(String question) async {
    if (question.isEmpty) return;
    setState(() => _asking = true);
    try {
      final answer = await ref.read(journeyRepositoryProvider).askJourney(widget.journeyId, question);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Answer', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
            const SizedBox(height: 12),
            Text(answer),
          ]),
        ),
      );
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final checklist = _checklist;
    if (checklist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preparation Checklist'), leading: BackButton(onPressed: () => popOrGo(context, _hubFallback))),
        body: const Center(child: Text('Could not load checklist')),
      );
    }

    final grouped = <String, List<ChecklistItemModel>>{};
    for (final item in checklist.items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => popOrGo(context, _hubFallback)),
        title: const Text('Preparation Checklist', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          _summaryCard(checklist),
          ...grouped.entries.map((e) => _category(e.key, e.value)),
        ],
      ),
      bottomSheet: Material(
        color: Colors.transparent,
        child: QueryBar(
          hint: 'Ask about your ${checklist.title.replaceAll(' Essentials', '')} trip...',
          onSubmit: _ask,
          loading: _asking,
          leadingIcon: Icons.add,
          showAiButton: false,
        ),
      ),
    );
  }

  Widget _summaryCard(ChecklistModel checklist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.checklist, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(checklist.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                Text('Essential items curated for your journey.', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${checklist.completionPercent}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Complete', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _category(String title, List<ChecklistItemModel> items) {
    final icon = categoryIcon(title);
    final relatedCard = _cardForCategory(title);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
            if (relatedCard != null)
              TextButton(
                onPressed: () => context.push('/cards/${relatedCard.id}?journeyId=${widget.journeyId}'),
                child: const Text('Related card'),
              ),
          ]),
        ),
        ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                leading: Checkbox(value: item.completed, onChanged: (_) => _toggle(item.id), activeColor: AppColors.primary),
                title: Text(item.title, style: TextStyle(decoration: item.completed ? TextDecoration.lineThrough : null)),
                subtitle: item.description.isNotEmpty ? Text(item.description, style: const TextStyle(fontSize: 12)) : null,
                trailing: Icon(Icons.check_circle_outline, color: item.completed ? AppColors.primary : Colors.grey.shade300),
              ),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}
