class Ticket {
  const Ticket({
    required this.id,
    required this.subject,
    required this.description,
    this.status,
    this.category,
    this.priority,
    this.createdAt,
    this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id']?.toString() ?? '',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String?,
      category: json['category'] as String?,
      priority: json['priority'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  final String id;
  final String subject;
  final String description;
  final String? status;
  final String? category;
  final String? priority;
  final String? createdAt;
  final String? updatedAt;
}

class TicketComment {
  const TicketComment({
    required this.id,
    required this.body,
    this.authorName,
    this.createdAt,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: json['id']?.toString() ?? '',
      body: json['body'] as String? ?? '',
      authorName: json['authorName'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  final String id;
  final String body;
  final String? authorName;
  final String? createdAt;
}

class TicketListResponse {
  const TicketListResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
  });

  factory TicketListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] ?? json['content'] ?? json['tickets'];
    final list = raw is List
        ? raw.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList()
        : <Ticket>[];
    return TicketListResponse(
      items: list,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      total: json['total'] as int? ?? list.length,
    );
  }

  final List<Ticket> items;
  final int page;
  final int pageSize;
  final int total;
}

class TicketCommentListResponse {
  const TicketCommentListResponse({required this.items});

  factory TicketCommentListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] ?? json['content'] ?? json['comments'];
    return TicketCommentListResponse(
      items: raw is List
          ? raw
              .map((e) => TicketComment.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  final List<TicketComment> items;
}
