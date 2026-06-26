class PreparationCard {
  const PreparationCard({
    required this.id,
    required this.title,
    this.summary,
    this.content,
    this.cardType,
    this.position,
    this.journeyId,
    this.createdAt,
    this.updatedAt,
  });

  factory PreparationCard.fromJson(Map<String, dynamic> json) {
    return PreparationCard(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String?,
      content: json['content'] as String?,
      cardType: json['cardType'] as String?,
      position: json['position'] as int?,
      journeyId: json['journeyId']?.toString(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  final String id;
  final String title;
  final String? summary;
  final String? content;
  final String? cardType;
  final int? position;
  final String? journeyId;
  final String? createdAt;
  final String? updatedAt;
}

class CardListResponse {
  const CardListResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 50,
    this.total = 0,
  });

  factory CardListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] ?? json['content'] ?? json['cards'];
    final list = raw is List
        ? raw
            .map((e) => PreparationCard.fromJson(e as Map<String, dynamic>))
            .toList()
        : <PreparationCard>[];
    return CardListResponse(
      items: list,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 50,
      total: json['total'] as int? ?? list.length,
    );
  }

  final List<PreparationCard> items;
  final int page;
  final int pageSize;
  final int total;
}
