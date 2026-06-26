class AiMessage {
  const AiMessage({
    required this.role,
    required this.content,
    this.createdAt,
  });

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
    );
  }

  final String role;
  final String content;
  final String? createdAt;
}

class AiChatResponse {
  const AiChatResponse({
    required this.reply,
    this.conversationId,
    this.messageId,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      reply: json['reply'] as String? ?? json['content'] as String? ?? '',
      conversationId: json['conversationId']?.toString(),
      messageId: json['messageId']?.toString(),
    );
  }

  final String reply;
  final String? conversationId;
  final String? messageId;
}

class AiConversation {
  const AiConversation({
    required this.id,
    this.title,
    this.messages = const [],
    this.updatedAt,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'];
    return AiConversation(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String?,
      updatedAt: json['updatedAt'] as String?,
      messages: raw is List
          ? raw.map((e) => AiMessage.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  final String id;
  final String? title;
  final List<AiMessage> messages;
  final String? updatedAt;
}

class AiConversationListResponse {
  const AiConversationListResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
  });

  factory AiConversationListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] ?? json['content'] ?? json['conversations'];
    final list = raw is List
        ? raw
            .map((e) => AiConversation.fromJson(e as Map<String, dynamic>))
            .toList()
        : <AiConversation>[];
    return AiConversationListResponse(
      items: list,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      total: json['total'] as int? ?? list.length,
    );
  }

  final List<AiConversation> items;
  final int page;
  final int pageSize;
  final int total;
}
