import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ai_models.dart';

class QueryBar extends StatefulWidget {
  const QueryBar({
    super.key,
    required this.hint,
    required this.onSubmit,
    this.loading = false,
    this.leadingIcon = Icons.search,
    this.showAiButton = true,
    this.initialText,
  });

  final String hint;
  final ValueChanged<String> onSubmit;
  final bool loading;
  final IconData leadingIcon;
  final bool showAiButton;
  final String? initialText;

  @override
  State<QueryBar> createState() => _QueryBarState();
}

class _QueryBarState extends State<QueryBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.loading) return;
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(widget.leadingIcon, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: widget.hint, border: InputBorder.none),
              textInputAction: TextInputAction.send,
              onSubmitted: widget.loading ? null : (_) => _submit(),
            ),
          ),
          if (widget.showAiButton)
            IconButton(
              onPressed: widget.loading ? null : _submit,
              icon: widget.loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 18,
                      child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    ),
            )
          else
            IconButton(
              onPressed: widget.loading ? null : _submit,
              icon: widget.loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 18,
                      child: Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                    ),
            ),
        ],
      ),
    );
  }
}

IconData categoryIcon(String category) {
  final c = category.toLowerCase();
  if (c.contains('visa') || c.contains('document')) return Icons.description_outlined;
  if (c.contains('weather')) return Icons.wb_sunny_outlined;
  if (c.contains('pack') || c.contains('checklist')) return Icons.checklist;
  if (c.contains('safety') || c.contains('health')) return Icons.health_and_safety_outlined;
  if (c.contains('transport')) return Icons.directions_car_outlined;
  if (c.contains('currency') || c.contains('money')) return Icons.payments_outlined;
  if (c.contains('culture') || c.contains('local')) return Icons.temple_hindu_outlined;
  return Icons.lightbulb_outline;
}

Color categoryColor(int index) {
  const colors = [
    Color(0xFFE3F2FD),
    Color(0xFFE8F5E9),
    Color(0xFFFFF9C4),
    Color(0xFFFCE4EC),
    Color(0xFFEDE7F6),
    Color(0xFFE0F7FA),
  ];
  return colors[index % colors.length];
}

Color categoryAccent(int index) {
  const colors = [
    Color(0xFF1565C0),
    Color(0xFFEF6C00),
    Color(0xFF2E7D32),
    Color(0xFF5E35B1),
    Color(0xFFC2185B),
    Color(0xFF00838F),
  ];
  return colors[index % colors.length];
}

/// Deck stack palette — matches preparation_deck mockup order.
class DeckCardStyle {
  const DeckCardStyle(this.background, this.accent, this.iconBg);
  final Color background;
  final Color accent;
  final Color iconBg;

  static DeckCardStyle forCard(CardModel card, int index) {
    final styles = [
      const DeckCardStyle(Color(0xFFE8F4FD), Color(0xFF1565C0), Colors.white),
      const DeckCardStyle(Color(0xFFFFF8E1), Color(0xFFEF6C00), Colors.white),
      const DeckCardStyle(Color(0xFFE8F5E9), Color(0xFF2E7D32), Colors.white),
      const DeckCardStyle(Color(0xFFEDE7F6), Color(0xFF5E35B1), Colors.white),
      const DeckCardStyle(Color(0xFFFCE4EC), Color(0xFFC2185B), Colors.white),
      const DeckCardStyle(Color(0xFFE0F7FA), Color(0xFF00838F), Colors.white),
    ];
    return styles[index % styles.length];
  }
}

String formatJourneyDate(DateTime? date) {
  if (date == null) return 'Recently';
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

Widget journeyThumbnail(JourneyModel journey, {double size = 72}) {
  final type = (journey.journeyType ?? journey.title).toLowerCase();
  IconData icon = Icons.explore;
  List<Color> gradient = [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
  if (type.contains('travel') || type.contains('bali') || type.contains('vacation')) {
    icon = Icons.temple_hindu;
    gradient = [const Color(0xFF5E35B1), const Color(0xFF7E57C2)];
  } else if (type.contains('sport') || type.contains('run') || type.contains('marathon')) {
    icon = Icons.directions_run;
    gradient = [const Color(0xFF2E7D32), const Color(0xFF66BB6A)];
  } else if (type.contains('health') || type.contains('medical') || type.contains('angiogram')) {
    icon = Icons.medical_services;
    gradient = [const Color(0xFFC62828), const Color(0xFFEF5350)];
  } else if (type.contains('education') || type.contains('gre') || type.contains('exam')) {
    icon = Icons.school;
    gradient = [const Color(0xFFEF6C00), const Color(0xFFFFB74D)];
  }
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: Icon(icon, color: Colors.white, size: size * 0.45),
  );
}

String insightTypeLabel(String type) {
  switch (type.toUpperCase()) {
    case 'WARNING':
      return 'Warning';
    case 'EXPERIENCE':
      return 'Experience';
    case 'UPDATE':
      return 'Update';
    default:
      return 'Tip';
  }
}

Color insightTypeColor(String type) {
  switch (type.toUpperCase()) {
    case 'WARNING':
      return Colors.red.shade700;
    case 'EXPERIENCE':
      return Colors.purple.shade700;
    case 'UPDATE':
      return Colors.orange.shade800;
    default:
      return AppColors.primary;
  }
}

bool isChecklistCard(CardModel card) {
  final category = card.category.toLowerCase();
  final title = card.title.toLowerCase();
  return category.contains('checklist') || title.contains('checklist');
}

String checklistCategoryForCard(CardModel card) {
  final title = card.title.trim();
  final lower = title.toLowerCase();
  if (lower.endsWith(' checklist')) {
    return title.substring(0, title.length - 10);
  }
  if (lower.contains('race day')) return 'Race Day';
  return card.category == 'Checklist' ? 'General' : card.category;
}

bool checklistItemMatchesCategory(ChecklistItemModel item, String categoryFilter) {
  final filter = categoryFilter.toLowerCase();
  final itemCategory = item.category.toLowerCase();
  return itemCategory == filter ||
      itemCategory.contains(filter) ||
      filter.contains(itemCategory);
}

void openJourneyCard(BuildContext context, CardModel card, int journeyId, {bool replace = false}) {
  if (isChecklistCard(card)) {
    final category = checklistCategoryForCard(card);
    final route =
        '/journeys/$journeyId/checklist?category=${Uri.encodeComponent(category)}&title=${Uri.encodeComponent(card.title)}';
    if (replace) {
      context.pushReplacement(route);
    } else {
      context.push(route);
    }
    return;
  }
  final cardRoute = '/cards/${card.id}?journeyId=$journeyId';
  if (replace) {
    context.pushReplacement(cardRoute);
  } else {
    context.push(cardRoute);
  }
}
