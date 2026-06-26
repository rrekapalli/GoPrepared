import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/journey_repository.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/ui_helpers.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({
    super.key,
    required this.journeyId,
    this.categoryFilter,
    this.pageTitle,
  });

  final int journeyId;
  final String? categoryFilter;
  final String? pageTitle;

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  ChecklistModel? _checklist;
  bool _loading = true;

  String get _hubFallback => '/journeys/${widget.journeyId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await ref.read(sessionProvider.future);
      final checklist = await ref.read(journeyRepositoryProvider).getChecklist(widget.journeyId);
      if (mounted) setState(() { _checklist = checklist; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ChecklistItemModel> get _visibleItems {
    final items = _checklist?.items ?? [];
    final filter = widget.categoryFilter;
    if (filter == null || filter.isEmpty) return items;
    return items.where((item) => checklistItemMatchesCategory(item, filter)).toList();
  }

  int _completionPercent(List<ChecklistItemModel> items) {
    if (items.isEmpty) return 0;
    final done = items.where((i) => i.completed).length;
    return (done * 100 / items.length).round();
  }

  Future<void> _toggle(int itemId) async {
    try {
      final updated = await ref.read(journeyRepositoryProvider).toggleChecklistItem(itemId);
      if (!mounted || _checklist == null) return;
      final items = _checklist!.items.map((i) => i.id == itemId ? updated : i).toList();
      setState(() {
        _checklist = ChecklistModel(
          journeyId: _checklist!.journeyId,
          title: _checklist!.title,
          completionPercent: _completionPercent(_visibleItems.map((v) {
            final match = items.firstWhere((i) => i.id == v.id, orElse: () => v);
            return match;
          }).toList()),
          items: items,
        );
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update item')));
    }
  }

  Future<void> _deleteItem(ChecklistItemModel item) async {
    try {
      await ref.read(journeyRepositoryProvider).deleteChecklistItem(item.id);
      if (!mounted || _checklist == null) return;
      final items = _checklist!.items.where((i) => i.id != item.id).toList();
      setState(() {
        _checklist = ChecklistModel(
          journeyId: _checklist!.journeyId,
          title: _checklist!.title,
          completionPercent: _completionPercent(_visibleItems.where((i) => i.id != item.id).toList()),
          items: items,
        );
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not remove item')));
    }
  }

  void _showAddItemSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final defaultCategory = widget.categoryFilter ?? 'My items';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add checklist item', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Item', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                try {
                  await ref.read(sessionProvider.future);
                  final added = await ref.read(journeyRepositoryProvider).addChecklistItem(
                        widget.journeyId,
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        category: defaultCategory,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!mounted || _checklist == null) return;
                  final items = [..._checklist!.items, added];
                  setState(() {
                    _checklist = ChecklistModel(
                      journeyId: _checklist!.journeyId,
                      title: _checklist!.title,
                      completionPercent: _completionPercent([..._visibleItems, added]),
                      items: items,
                    );
                  });
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Could not add item')));
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: AppBottomNav(selectedIndex: 1),
      );
    }

    final checklist = _checklist;
    if (checklist == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => popOrGo(context, _hubFallback)),
          title: Text(widget.pageTitle ?? 'Preparation Checklist'),
        ),
        body: const Center(child: Text('Could not load checklist')),
        bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
      );
    }

    final items = _visibleItems;
    final grouped = <String, List<ChecklistItemModel>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => popOrGo(context, _hubFallback)),
        title: Text(
          widget.pageTitle ?? 'Preparation Checklist',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        children: [
          _summaryCard(items),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No checklist items yet. Tap + to add your own.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          ...grouped.entries.map((e) => _category(e.key, e.value)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
    );
  }

  Widget _summaryCard(List<ChecklistItemModel> items) {
    final percent = _completionPercent(items);
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
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
                Text(
                  widget.pageTitle ?? _checklist!.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                ),
                Text(
                  widget.categoryFilter != null
                      ? 'Items for ${widget.categoryFilter}.'
                      : 'Essential items curated for your journey.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$percent%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Complete', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _category(String title, List<ChecklistItemModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(categoryIcon(title), color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
            ],
          ),
        ),
        ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                leading: Checkbox(value: item.completed, onChanged: (_) => _toggle(item.id), activeColor: AppColors.primary),
                title: Text(item.title, style: TextStyle(decoration: item.completed ? TextDecoration.lineThrough : null)),
                subtitle: item.description.isNotEmpty ? Text(item.description, style: const TextStyle(fontSize: 12)) : null,
                trailing: item.userAdded
                    ? IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.grey.shade500),
                        onPressed: () => _deleteItem(item),
                      )
                    : Icon(Icons.check_circle_outline, color: item.completed ? AppColors.primary : Colors.grey.shade300),
              ),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}
