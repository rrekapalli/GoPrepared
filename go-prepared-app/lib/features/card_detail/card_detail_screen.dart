import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

import '../../data/demo/demo_data.dart';
import '../../data/models/ai_models.dart';

import '../../data/repositories/journey_repository.dart';

import '../../shared/widgets/app_shell.dart';

import '../../shared/widgets/ui_helpers.dart';



class CardDetailScreen extends ConsumerStatefulWidget {

  const CardDetailScreen({super.key, required this.cardId});

  final int cardId;



  @override

  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();

}



class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {

  CardModel? _card;

  bool _loading = true;

  bool _asking = false;



  @override

  void initState() {

    super.initState();

    _load();

  }



  Future<void> _load() async {

    if (DemoData.isDemoCard(widget.cardId)) {

      final card = DemoData.cardById(widget.cardId);

      if (mounted) setState(() { _card = card; _loading = false; });

      return;

    }

    try {

      await ref.read(sessionProvider.future);

      final card = await ref.read(journeyRepositoryProvider).getCard(widget.cardId);

      if (mounted) setState(() { _card = card; _loading = false; });

    } catch (_) {

      if (mounted) setState(() => _loading = false);

    }

  }



  Future<void> _ask(String question) async {

    if (question.isEmpty) return;

    if (DemoData.isDemoCard(widget.cardId)) {

      showModalBottomSheet(

        context: context,

        isScrollControlled: true,

        builder: (ctx) => Padding(

          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text('Demo mode', style: Theme.of(ctx).textTheme.titleMedium),

              const SizedBox(height: 8),

              Text(

                'AI answers require a running API. Start the backend to ask questions about this card.',

                style: TextStyle(color: Colors.grey.shade700),

              ),

            ],

          ),

        ),

      );

      return;

    }

    setState(() => _asking = true);

    try {

      final answer = await ref.read(journeyRepositoryProvider).askCard(widget.cardId, question);

      if (!mounted) return;

      showModalBottomSheet(

        context: context,

        isScrollControlled: true,

        builder: (ctx) => Padding(

          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text('Answer', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppColors.primary)),

              const SizedBox(height: 12),

              Text(answer),

            ],

          ),

        ),

      );

    } catch (_) {

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not get an answer')));

    } finally {

      if (mounted) setState(() => _asking = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final card = _card;

    if (card == null) {

      return Scaffold(

        appBar: AppBar(leading: BackButton(onPressed: () => popOrGo(context, '/journeys'))),

        body: const Center(child: Text('Card not found')),

      );

    }



    final detail = card.detail ?? {};

    final destination = detail['destinationLabel'] as String? ?? card.title;

    final emergency = (detail['emergencyContacts'] as List?)?.cast<Map<String, dynamic>>() ?? [];



    return Scaffold(

      appBar: AppBar(

        leading: BackButton(onPressed: () => popOrGo(context, '/journeys')),

        title: Text(card.category.contains('Travel') || destination.contains(',') ? 'Travel Info' : card.title),

      ),

      body: ListView(

        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),

        children: [

          _hero(destination),

          const SizedBox(height: 16),

          _section('DO\'S', (detail['dos'] as List?)?.cast<String>() ?? [], Colors.blue.shade50, Icons.check_circle, Colors.green.shade700),

          _section('DON\'TS', (detail['donts'] as List?)?.cast<String>() ?? [], Colors.red.shade50, Icons.cancel, Colors.red.shade700),

          if (detail['currency'] != null) _infoCard('CURRENCY', _currencyText(detail['currency'] as Map)),

          if (detail['weather'] != null) _infoCard('WEATHER', detail['weather'] as String),

          if (emergency.isNotEmpty) _emergencyCard(emergency),

          ...((detail['sections'] as List?) ?? []).map((s) {

            final m = s as Map<String, dynamic>;

            return _infoCard((m['title'] as String? ?? '').toUpperCase(), m['body'] as String? ?? '');

          }),

          if (detail.isEmpty) ...[

            Text(card.summary, style: Theme.of(context).textTheme.bodyLarge),

            const SizedBox(height: 8),

            Text('Tap below to ask more about this topic.', style: TextStyle(color: Colors.grey.shade600)),

          ],

          const SizedBox(height: 12),

          OutlinedButton.icon(

            onPressed: () {},

            icon: const Icon(Icons.map_outlined),

            label: const Text('Explore Map'),

          ),

        ],

      ),

      bottomSheet: Material(

        color: Colors.transparent,

        child: QueryBar(

          hint: 'Ask about ${card.title}...',

          onSubmit: _ask,

          loading: _asking,

          leadingIcon: Icons.add,

          showAiButton: false,

        ),

      ),

    );

  }



  String _currencyText(Map currency) {

    final name = currency['name'] as String? ?? '';

    final note = currency['exchangeRateNote'] as String? ?? '';

    return note.isNotEmpty ? '$name — $note' : name;

  }



  Widget _hero(String destination) {

    return Container(

      height: 200,

      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(AppColors.cardRadius),

        gradient: const LinearGradient(

          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],

          begin: Alignment.topCenter,

          end: Alignment.bottomCenter,

        ),

      ),

      alignment: Alignment.bottomLeft,

      padding: const EdgeInsets.all(20),

      child: Column(

        mainAxisAlignment: MainAxisAlignment.end,

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text('DESTINATION', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1, fontSize: 11)),

          Text(destination, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),

        ],

      ),

    );

  }



  Widget _section(String title, List<String> items, Color bg, IconData icon, Color iconColor) {

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(title, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 0.5)),

          const SizedBox(height: 8),

          ...items.map((i) => Padding(

                padding: const EdgeInsets.symmetric(vertical: 4),

                child: Row(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Icon(icon, size: 18, color: iconColor),

                    const SizedBox(width: 8),

                    Expanded(child: Text(i)),

                  ],

                ),

              )),

        ],

      ),

    );

  }



  Widget _infoCard(String title, String body) => Container(

        margin: const EdgeInsets.only(bottom: 12),

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 0.5)),

            const SizedBox(height: 6),

            Text(body, style: const TextStyle(fontSize: 15)),

          ],

        ),

      );



  Widget _emergencyCard(List<Map<String, dynamic>> contacts) {

    return Container(

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text('EMERGENCY CONTACTS', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, letterSpacing: 0.5)),

          const SizedBox(height: 12),

          Wrap(

            spacing: 24,

            runSpacing: 8,

            children: contacts.map((c) {

              return Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(c['label'] as String? ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),

                  Text(c['number'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

                ],

              );

            }).toList(),

          ),

        ],

      ),

    );

  }

}


