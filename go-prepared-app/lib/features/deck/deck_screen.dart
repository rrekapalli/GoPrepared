import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/journey_repository.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/ui_helpers.dart';

/// Preparation deck — stacked cards for each aspect of a journey (preparation_deck mockup).
class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({super.key, required this.journeyId});
  final int journeyId;

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  JourneyModel? _journey;
  List<CardModel> _cards = [];
  int _index = 0;
  bool _loading = true;

  static const _layerStep = 28.0;
  static const _maxPeekLayers = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (DemoData.isDemoJourney(widget.journeyId)) {
      final journey = DemoData.journeyById(widget.journeyId);
      final cards = DemoData.cardsForJourney(widget.journeyId);
      if (mounted) {
        setState(() {
          _journey = journey;
          _cards = cards;
          _loading = false;
        });
      }
      return;
    }
    try {
      await ref.read(sessionProvider.future);
      final repo = ref.read(journeyRepositoryProvider);
      final journey = await repo.getJourney(widget.journeyId);
      final cards = await repo.getCards(widget.journeyId);
      if (mounted) setState(() { _journey = journey; _cards = cards; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _next() {
    if (_index < _cards.length - 1) setState(() => _index++);
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  void _openCard(CardModel card) => context.push('/cards/${card.id}');

  String _pageHint(JourneyModel? j, int cardCount) {
    final loc = j?.location;
    final where = (loc != null && loc.isNotEmpty) ? ' to $loc' : '';
    return 'Swipe through $cardCount AI-curated preparation cards$where. '
        'Tap any card for the full guide, or use the arrows to browse the deck.';
  }

  String _subtitle(JourneyModel? j) {
    if (j?.location != null && j!.location!.isNotEmpty) {
      return 'Essential preparation steps tailored for your journey to ${j.location}.';
    }
    return 'Essential preparation steps tailored for your journey.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            AppTopHeader(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => popOrGo(context, '/journeys'),
              ),
            ),
            const Expanded(child: Center(child: Text('No cards yet. Generate from Discover.'))),
          ],
        ),
      );
    }

    final journey = _journey;
    final card = _cards[_index];
    final peekCount = (_cards.length - _index - 1).clamp(0, _maxPeekLayers);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppTopHeader(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => popOrGo(context, '/journeys'),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -280) _next();
                if (v > 280) _prev();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI RECOMMENDATION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade500,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your preparation for:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      journey?.title ?? 'Your Journey',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitle(journey),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final frontTop = peekCount * _layerStep;
                          final cardHeight = constraints.maxHeight * 0.75;
                          return Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              for (var layer = peekCount; layer >= 1; layer--)
                                _DeckPeekCard(
                                  card: _cards[_index + layer],
                                  cardIndex: _index + layer,
                                  layer: layer,
                                  top: (layer - 1) * _layerStep,
                                  widthFactor: 1 - (layer * 0.02),
                                ),
                              Positioned(
                                top: frontTop,
                                left: 0,
                                right: 0,
                                height: cardHeight,
                                child: _DeckFrontCard(
                                  card: card,
                                  cardIndex: _index,
                                  onOpen: () => _openCard(card),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PageDots(count: _cards.length, index: _index, onTap: (i) => setState(() => _index = i)),
                    const SizedBox(height: 12),
                    Text(
                      _pageHint(journey, _cards.length),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            height: 1.4,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _index > 0 ? _prev : null,
                          icon: Icon(Icons.chevron_left, color: _index > 0 ? AppColors.primary : Colors.grey.shade300),
                        ),
                        Text(
                          '${_index + 1} of ${_cards.length}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        IconButton(
                          onPressed: _index < _cards.length - 1 ? _next : null,
                          icon: Icon(Icons.chevron_right, color: _index < _cards.length - 1 ? AppColors.primary : Colors.grey.shade300),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          _DeckBottomNav(currentPath: '/journeys'),
        ],
      ),
    );
  }
}

/// Tilted strip behind the front card — category/title visible at the top edge.
class _DeckPeekCard extends StatelessWidget {
  const _DeckPeekCard({
    required this.card,
    required this.cardIndex,
    required this.layer,
    required this.top,
    required this.widthFactor,
  });

  final CardModel card;
  final int cardIndex;
  final int layer;
  final double top;
  final double widthFactor;

  static const _tiltDegrees = 5.0;

  @override
  Widget build(BuildContext context) {
    final style = DeckCardStyle.forCard(card, cardIndex);
    final horizontalInset = (1 - widthFactor) * 40;
    // All back cards tilt the same way; front card stays upright (0°).
    final angle = _tiltDegrees * math.pi / 180;

    return Positioned(
      top: top,
      left: horizontalInset,
      right: horizontalInset,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.topCenter,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          alignment: Alignment.topLeft,
          child: Text(
            card.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: style.accent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full front preparation card — icon, title, category badge, summary only.
class _DeckFrontCard extends StatelessWidget {
  const _DeckFrontCard({
    required this.card,
    required this.cardIndex,
    required this.onOpen,
  });

  final CardModel card;
  final int cardIndex;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final style = DeckCardStyle.forCard(card, cardIndex);

    return Container(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: style.iconBg,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Icon(categoryIcon(card.category), color: style.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                          ),
                          const SizedBox(height: 4),
                          _CategoryBadge(label: card.category, accent: style.accent),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  card.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withValues(alpha: 0.55),
                        height: 1.35,
                        fontSize: 12,
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

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: accent,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index, required this.onTap});
  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == index;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: selected ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

/// Bottom nav on deck (mockup shows full app chrome; Journeys tab highlighted).
class _DeckBottomNav extends StatelessWidget {
  const _DeckBottomNav({required this.currentPath});
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavTab(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Discover', selected: currentPath == '/discover', onTap: () => context.go('/discover')),
              _NavTab(icon: Icons.explore_outlined, selectedIcon: Icons.explore, label: 'Journeys', selected: currentPath == '/journeys', onTap: () => context.go('/journeys')),
              _NavTab(icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: 'Knowledge', selected: false, onTap: () => context.go('/knowledge')),
              _NavTab(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Community', selected: false, onTap: () => context.go('/community')),
              _NavTab(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Me', selected: false, onTap: () => context.go('/me')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: selected ? BoxDecoration(color: AppColors.primary, shape: BoxShape.circle) : null,
              child: Icon(selected ? selectedIcon : icon, size: 20, color: selected ? Colors.white : Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
