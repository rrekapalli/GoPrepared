import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../community/community_screen.dart';
import '../knowledge/knowledge_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Guides'),
              Tab(text: 'Community'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              KnowledgeScreen(embedded: true),
              CommunityScreen(embedded: true),
            ],
          ),
        ),
      ],
    );
  }
}
