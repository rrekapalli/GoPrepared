class KnowledgeCategory {
  const KnowledgeCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.nodeCount,
  });

  factory KnowledgeCategory.fromJson(Map<String, dynamic> json) {
    return KnowledgeCategory(
      id: json['id']?.toString() ?? json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      nodeCount: json['nodeCount'] as int?,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? icon;
  final int? nodeCount;
}

class KnowledgeCategoriesResponse {
  const KnowledgeCategoriesResponse({required this.categories});

  factory KnowledgeCategoriesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['categories'] ?? json['items'] ?? json;
    if (raw is List) {
      return KnowledgeCategoriesResponse(
        categories: raw
            .map((e) => KnowledgeCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    return const KnowledgeCategoriesResponse(categories: []);
  }

  final List<KnowledgeCategory> categories;
}

class KnowledgeNode {
  const KnowledgeNode({
    required this.id,
    required this.name,
    this.type,
    this.description,
    this.category,
    this.metadata,
  });

  factory KnowledgeNode.fromJson(Map<String, dynamic> json) {
    return KnowledgeNode(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  final String id;
  final String name;
  final String? type;
  final String? description;
  final String? category;
  final Map<String, dynamic>? metadata;
}

class KnowledgeEdge {
  const KnowledgeEdge({
    required this.sourceId,
    required this.targetId,
    this.relationshipType,
  });

  factory KnowledgeEdge.fromJson(Map<String, dynamic> json) {
    return KnowledgeEdge(
      sourceId: json['sourceId']?.toString() ?? json['source']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? json['target']?.toString() ?? '',
      relationshipType: json['relationshipType'] as String? ?? json['type'] as String?,
    );
  }

  final String sourceId;
  final String targetId;
  final String? relationshipType;
}

class KnowledgeGraphResponse {
  const KnowledgeGraphResponse({
    this.nodes = const [],
    this.edges = const [],
  });

  factory KnowledgeGraphResponse.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'];
    final rawEdges = json['edges'];
    return KnowledgeGraphResponse(
      nodes: rawNodes is List
          ? rawNodes
              .map((e) => KnowledgeNode.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      edges: rawEdges is List
          ? rawEdges
              .map((e) => KnowledgeEdge.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  final List<KnowledgeNode> nodes;
  final List<KnowledgeEdge> edges;
}

class KnowledgeSearchHit {
  const KnowledgeSearchHit({
    required this.node,
    this.score,
  });

  factory KnowledgeSearchHit.fromJson(Map<String, dynamic> json) {
    final nodeJson = json['node'] ?? json;
    return KnowledgeSearchHit(
      node: KnowledgeNode.fromJson(nodeJson as Map<String, dynamic>),
      score: (json['score'] as num?)?.toDouble(),
    );
  }

  final KnowledgeNode node;
  final double? score;
}

class KnowledgeSearchResponse {
  const KnowledgeSearchResponse({
    required this.results,
    this.query,
  });

  factory KnowledgeSearchResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['results'] ?? json['items'] ?? json['hits'];
    return KnowledgeSearchResponse(
      query: json['query'] as String?,
      results: raw is List
          ? raw
              .map((e) => KnowledgeSearchHit.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  final List<KnowledgeSearchHit> results;
  final String? query;
}
