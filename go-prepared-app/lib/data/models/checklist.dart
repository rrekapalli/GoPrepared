class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.title,
    this.completed = false,
    this.position,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      position: json['position'] as int?,
    );
  }

  final String id;
  final String title;
  final bool completed;
  final int? position;
}

class Checklist {
  const Checklist({
    required this.id,
    required this.title,
    this.description,
    this.items = const [],
    this.journeyId,
  });

  factory Checklist.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return Checklist(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      journeyId: json['journeyId']?.toString(),
      items: rawItems is List
          ? rawItems
              .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  final String id;
  final String title;
  final String? description;
  final List<ChecklistItem> items;
  final String? journeyId;
}

class ChecklistListResponse {
  const ChecklistListResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
  });

  factory ChecklistListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] ?? json['content'] ?? json['checklists'];
    final list = raw is List
        ? raw
            .map((e) => Checklist.fromJson(e as Map<String, dynamic>))
            .toList()
        : <Checklist>[];
    return ChecklistListResponse(
      items: list,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      total: json['total'] as int? ?? list.length,
    );
  }

  final List<Checklist> items;
  final int page;
  final int pageSize;
  final int total;
}
