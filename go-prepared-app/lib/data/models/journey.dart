class Journey {
  const Journey({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.destination,
    this.startDate,
    this.endDate,
    this.status,
    this.coverImageUrl,
    this.cardCount,
    this.checklistProgress,
    this.createdAt,
    this.updatedAt,
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      destination: json['destination'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      status: json['status'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      cardCount: json['cardCount'] as int?,
      checklistProgress: (json['checklistProgress'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? destination;
  final String? startDate;
  final String? endDate;
  final String? status;
  final String? coverImageUrl;
  final int? cardCount;
  final double? checklistProgress;
  final String? createdAt;
  final String? updatedAt;
}

class JourneyListResponse {
  const JourneyListResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
  });

  factory JourneyListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] ?? json['content'] ?? json['journeys'];
    final list = raw is List
        ? raw
            .map((e) => Journey.fromJson(e as Map<String, dynamic>))
            .toList()
        : <Journey>[];
    return JourneyListResponse(
      items: list,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      total: json['total'] as int? ?? list.length,
    );
  }

  final List<Journey> items;
  final int page;
  final int pageSize;
  final int total;
}
