import 'package:flutter/material.dart';

import '../knowledge/knowledge_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const KnowledgeScreen(embedded: true);
  }
}
