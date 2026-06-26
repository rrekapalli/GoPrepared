import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/journey_repository.dart';

class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  List<KnowledgeCategoryModel> _categories = [];
  List<KnowledgeEdgeModel> _edges = [];
  List<KnowledgeNodeModel> _nodes = [];
  List<KnowledgeTemplateModel> _templates = [];
  String? _selectedCategory;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(knowledgeRepositoryProvider);
      final categories = await repo.categories();
      final edges = await repo.relationships();
      final nodes = await repo.nodes();
      if (mounted) {
        setState(() {
          _categories = categories;
          _edges = edges;
          _nodes = nodes;
          _selectedCategory = categories.isNotEmpty ? categories.first.name : null;
          _loading = false;
        });
        if (_selectedCategory != null) _loadTemplates(_selectedCategory!);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTemplates(String category) async {
    try {
      final templates = await ref.read(knowledgeRepositoryProvider).templates(journeyType: category);
      if (mounted) setState(() => _templates = templates);
    } catch (_) {}
  }

  Future<void> _selectCategory(String name) async {
    setState(() => _selectedCategory = name);
    await _loadTemplates(name);
  }

  List<String> _pathForCategory(String category) {
    final path = <String>[category];
    var current = category;
    for (var depth = 0; depth < 5; depth++) {
      final edge = _edges.where((e) => e.sourceName == current).firstOrNull;
      if (edge == null) break;
      path.add(edge.targetName);
      current = edge.targetName;
    }
    return path;
  }

  List<KnowledgeNodeModel> _nodesForCategory(String category) {
    final path = _pathForCategory(category);
    final names = path.map((n) => n.toLowerCase()).toSet();
    return _nodes.where((n) {
      final type = n.nodeType.toLowerCase();
      final name = n.name.toLowerCase();
      return names.contains(type) || names.contains(name) || type == category.toLowerCase();
    }).toList();
  }

  IconData _categoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'travel':
        return Icons.flight;
      case 'sports':
        return Icons.sports_soccer;
      case 'education':
        return Icons.school;
      case 'career':
        return Icons.work_outline;
      case 'finance':
        return Icons.account_balance;
      case 'health':
        return Icons.favorite_border;
      default:
        return Icons.category_outlined;
    }
  }

  void _showNodeDetail(KnowledgeNodeModel node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(node.name, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(node.nodeType, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Text(node.description.isNotEmpty ? node.description : 'Explore preparation topics for ${node.name}.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                final query = 'Prepare for ${node.name}';
                context.go('/home?q=${Uri.encodeComponent(query)}');
              },
              child: Text('Prepare for ${node.name}'),
            ),
          ],
        ),
      ),
    );
  }

  void _prepareFromTemplate(KnowledgeTemplateModel template) {
    final query = template.suggestedQuery ?? template.title;
    context.go('/home?q=${Uri.encodeComponent(query)}');
  }

  @override
  Widget build(BuildContext context) {
    final path = _selectedCategory != null ? _pathForCategory(_selectedCategory!) : <String>[];
    final categoryNodes = _selectedCategory != null ? _nodesForCategory(_selectedCategory!) : <KnowledgeNodeModel>[];

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PREPARATION PATH', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: path.isEmpty
                            ? [const Chip(label: Text('Select a category below'))]
                            : path.asMap().entries.map((e) {
                                final isLast = e.key == path.length - 1;
                                return Chip(
                                  label: Text(e.value),
                                  backgroundColor: isLast ? AppColors.primary.withValues(alpha: 0.12) : null,
                                  labelStyle: TextStyle(color: isLast ? AppColors.primary : null, fontWeight: isLast ? FontWeight.w600 : null),
                                );
                              }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Navigate preparation nodes curated from journeys and community insights.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 120, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final c = _categories[i];
                    final selected = _selectedCategory == c.name;
                    return InkWell(
                      onTap: () => _selectCategory(c.name),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: selected ? Border.all(color: AppColors.primary, width: 2) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(_categoryIcon(c.name), color: AppColors.primary),
                            const Spacer(),
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${c.journeyCount}+ journeys', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_templates.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Trending preparations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._templates.take(6).map((t) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text([t.journeyType, t.location].where((s) => s != null && s.isNotEmpty).join(' · ')),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => _prepareFromTemplate(t),
                        ),
                      )),
                ],
                if (categoryNodes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Knowledge nodes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...categoryNodes.take(12).map((n) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(n.name),
                        subtitle: Text(n.nodeType, style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showNodeDetail(n),
                      )),
                ],
              ],
            ),
          );

    if (widget.embedded) return body;
    return Scaffold(body: body);
  }
}
