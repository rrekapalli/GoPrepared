import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/demo/demo_data.dart';
import '../../data/models/ai_models.dart';
import '../../data/repositories/journey_repository.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/preparation_deck_stack.dart';
import '../../shared/widgets/ui_helpers.dart';

/// Full-screen stacked deck view (same card layout as hub, focused browsing).
class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({super.key, required this.journeyId, this.initialCardIndex});
  final int journeyId;
  final int? initialCardIndex;

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  JourneyModel? _journey;
  List<CardModel> _cards = [];
  late int _index;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _index = widget.initialCardIndex ?? 0;
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
          if (_index >= cards.length) _index = cards.isEmpty ? 0 : cards.length - 1;
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
      if (mounted) {
        setState(() {
          _journey = journey;
          _cards = cards;
          if (_index >= cards.length) _index = cards.isEmpty ? 0 : cards.length - 1;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openCard(CardModel card) => openJourneyCard(context, card, widget.journeyId);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: AppBottomNav(selectedIndex: 1),
      );
    }

    final journey = _journey;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppTopHeader(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1565C0)),
              onPressed: () => popOrGo(context, '/journeys/${widget.journeyId}'),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: PreparationDeckStack(
                journeyTitle: journey?.title ?? 'Your Journey',
                location: journey?.location,
                cards: _cards,
                index: _index,
                onIndexChanged: (i) => setState(() => _index = i),
                onOpenCard: _openCard,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
    );
  }
}
