import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/ai_models.dart';
import 'ui_helpers.dart';

/// Stacked preparation cards — matches preparation_deck mockup.
class PreparationDeckStack extends StatelessWidget {
  const PreparationDeckStack({
    super.key,
    required this.journeyTitle,
    required this.cards,
    required this.index,
    required this.onIndexChanged,
    required this.onOpenCard,
    this.location,
    this.compact = false,
  });

  final String journeyTitle;
  final List<CardModel> cards;
  final int index;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<CardModel> onOpenCard;
  final String? location;
  final bool compact;

  static const _layerStep = 28.0;
  static const _maxPeekLayers = 3;

  String get _subtitle {
    if (location != null && location!.isNotEmpty) {
      return 'Essential preparation steps tailored for your journey to $location.';
    }
    return 'Essential preparation steps tailored for your journey.';
  }

  void _next() {
    if (index < cards.length - 1) onIndexChanged(index + 1);
  }

  void _prev() {
    if (index > 0) onIndexChanged(index - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('No preparation cards yet.', style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
      );
    }

    final card = cards[index.clamp(0, cards.length - 1)];
    final peekCount = (cards.length - index - 1).clamp(0, _maxPeekLayers);
    final stackHeight = compact ? 320.0 : 360.0;

    return Column(
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
          journeyTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          _subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                height: 1.35,
              ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -280) _next();
            if (v > 280) _prev();
          },
          child: SizedBox(
            height: stackHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final frontTop = peekCount * _layerStep;
                final cardHeight = constraints.maxHeight * 0.78;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    for (var layer = peekCount; layer >= 1; layer--)
                      _DeckPeekCard(
                        card: cards[index + layer],
                        cardIndex: index + layer,
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
                        cardIndex: index,
                        onOpen: () => onOpenCard(card),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PageDots(count: cards.length, index: index, onTap: onIndexChanged),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: index > 0 ? _prev : null,
              icon: Icon(Icons.chevron_left, color: index > 0 ? AppColors.primary : Colors.grey.shade300),
            ),
            Text('${index + 1} of ${cards.length}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            IconButton(
              onPressed: index < cards.length - 1 ? _next : null,
              icon: Icon(Icons.chevron_right, color: index < cards.length - 1 ? AppColors.primary : Colors.grey.shade300),
            ),
          ],
        ),
      ],
    );
  }
}

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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          alignment: Alignment.topLeft,
          child: Text(
            card.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: style.accent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.2),
          ),
        ),
      ),
    );
  }
}

class _DeckFrontCard extends StatelessWidget {
  const _DeckFrontCard({required this.card, required this.cardIndex, required this.onOpen});

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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Padding(
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
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
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
                      maxLines: 3,
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
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: style.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ),
              ),
            ],
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
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
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
