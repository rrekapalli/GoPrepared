class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.title,
    required this.body,
    this.category,
    this.authorName,
    this.createdAt,
    this.commentCount,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['content'] as String? ?? '',
      category: json['category'] as String?,
      authorName: json['authorName'] as String? ?? json['author'] as String?,
      createdAt: json['createdAt'] as String?,
      commentCount: json['commentCount'] as int?,
    );
  }

  final String id;
  final String title;
  final String body;
  final String? category;
  final String? authorName;
  final String? createdAt;
  final int? commentCount;
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.body,
    this.authorName,
    this.createdAt,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
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

class CommunityPostListResponse {
  const CommunityPostListResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 20,
    this.total = 0,
  });

  factory CommunityPostListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] ?? json['content'] ?? json['posts'];
    final list = raw is List
        ? raw
            .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
            .toList()
        : <CommunityPost>[];
    return CommunityPostListResponse(
      items: list,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      total: json['total'] as int? ?? list.length,
    );
  }

  final List<CommunityPost> items;
  final int page;
  final int pageSize;
  final int total;
}
