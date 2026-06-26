import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../core/theme/app_colors.dart';

import '../../data/demo/demo_data.dart';

import '../../data/models/ai_models.dart';

import '../../data/repositories/journey_repository.dart';

import '../community/community_screen.dart';

import '../../shared/widgets/app_shell.dart';

import '../../shared/widgets/preparation_deck_stack.dart';

import '../../shared/widgets/ui_helpers.dart';

class JourneyHubScreen extends ConsumerStatefulWidget {

  const JourneyHubScreen({super.key, required this.journeyId, this.initialTab = 0});



  final int journeyId;

  final int initialTab;



  @override

  ConsumerState<JourneyHubScreen> createState() => _JourneyHubScreenState();

}



class _JourneyHubScreenState extends ConsumerState<JourneyHubScreen> with SingleTickerProviderStateMixin {

  JourneyModel? _journey;

  List<CardModel> _cards = [];

  int _deckIndex = 0;

  bool _loading = true;

  late final TabController _tabController;



  @override

  void initState() {

    super.initState();

    _tabController = TabController(

      length: 2,

      vsync: this,

      initialIndex: widget.initialTab.clamp(0, 1),

    );

    _load();

  }



  @override

  void dispose() {

    _tabController.dispose();

    super.dispose();

  }



  Future<void> _load() async {

    if (DemoData.isDemoJourney(widget.journeyId)) {

      final journey = DemoData.journeyById(widget.journeyId);

      if (journey == null) {

        if (mounted) setState(() => _loading = false);

        return;

      }

      if (!mounted) return;

      setState(() {

        _journey = journey;

        _cards = DemoData.cardsForJourney(widget.journeyId);

        _loading = false;

      });

      return;

    }



    try {

      await ref.read(sessionProvider.future);

      final repo = ref.read(journeyRepositoryProvider);

      final results = await Future.wait([

        repo.getJourney(widget.journeyId),

        repo.getCards(widget.journeyId),

      ]);

      if (!mounted) return;

      setState(() {

        _journey = results[0] as JourneyModel;

        _cards = results[1] as List<CardModel>;

        _loading = false;

      });

    } catch (_) {

      if (mounted) setState(() => _loading = false);

    }

  }



  void _openCard(CardModel card) {
    openJourneyCard(context, card, widget.journeyId);
  }



  @override

  Widget build(BuildContext context) {

    if (_loading) {

      return const Scaffold(

        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),

        bottomNavigationBar: AppBottomNav(selectedIndex: 1),

      );

    }



    final journey = _journey;

    if (journey == null) {

      return Scaffold(

        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/journeys'))),

        body: const Center(child: Text('Journey not found')),

        bottomNavigationBar: const AppBottomNav(selectedIndex: 1),

      );

    }



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

          Material(

            color: Colors.white,

            child: TabBar(

              controller: _tabController,

              labelColor: AppColors.primary,

              unselectedLabelColor: Colors.grey.shade600,

              indicatorColor: AppColors.primary,

              tabs: const [

                Tab(text: 'Journey'),

                Tab(text: 'Community'),

              ],

            ),

          ),

          Expanded(

            child: TabBarView(

              controller: _tabController,

              children: [

                RefreshIndicator(

                  onRefresh: _load,

                  child: ListView(

                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),

                    children: [

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

                      const SizedBox(height: 8),

                      PreparationDeckStack(

                        journeyTitle: journey.title,

                        location: journey.location,

                        cards: _cards,

                        index: _deckIndex.clamp(0, _cards.isEmpty ? 0 : _cards.length - 1),

                        onIndexChanged: (i) => setState(() => _deckIndex = i),

                        onOpenCard: _openCard,

                      ),

                    ],

                  ),

                ),

                CommunityScreen(
                  embedded: true,
                  journeyId: widget.journeyId,
                  journey: journey,
                  journeyContext: journey.title,
                ),

              ],

            ),

          ),

        ],

      ),

      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),

    );

  }

}


