class JourneyClassification {
  JourneyClassification({
    required this.journeyType,
    required this.journeySubtype,
    required this.activity,
    required this.location,
    required this.title,
    this.confidence,
  });

  final String journeyType;
  final String journeySubtype;
  final String activity;
  final String location;
  final String title;
  final double? confidence;

  factory JourneyClassification.fromJson(Map<String, dynamic> json) =>
      JourneyClassification(
        journeyType: json['journeyType'] as String? ?? '',
        journeySubtype: json['journeySubtype'] as String? ?? '',
        activity: json['activity'] as String? ?? '',
        location: json['location'] as String? ?? '',
        title: json['title'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble(),
      );
}

class PreparationCard {
  PreparationCard({
    required this.title,
    required this.summary,
    required this.category,
    required this.icon,
    required this.displayOrder,
    this.detail,
  });

  final String title;
  final String summary;
  final String category;
  final String icon;
  final int displayOrder;
  final Map<String, dynamic>? detail;

  factory PreparationCard.fromJson(Map<String, dynamic> json) => PreparationCard(
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        category: json['category'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
        displayOrder: json['displayOrder'] as int? ?? 0,
        detail: json['detail'] as Map<String, dynamic>?,
      );
}

class JourneyModel {
  JourneyModel({
    required this.id,
    required this.title,
    required this.originalQuery,
    required this.status,
    required this.progressPercent,
    this.createdAt,
    this.journeyType,
    this.journeySubtype,
    this.activity,
    this.location,
  });

  final int id;
  final String title;
  final String originalQuery;
  final String status;
  final int progressPercent;
  final DateTime? createdAt;
  final String? journeyType;
  final String? journeySubtype;
  final String? activity;
  final String? location;

  factory JourneyModel.fromJson(Map<String, dynamic> json) => JourneyModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        originalQuery: json['originalQuery'] as String? ?? '',
        status: json['status'] as String? ?? 'DRAFT',
        progressPercent: json['progressPercent'] as int? ?? 0,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
        journeyType: json['journeyType'] as String?,
        journeySubtype: json['journeySubtype'] as String?,
        activity: json['activity'] as String?,
        location: json['location'] as String?,
      );

  bool get isActive => status == 'ACTIVE' || progressPercent > 0 && progressPercent < 100;
  bool get isComplete => progressPercent >= 100;
  bool get isDemo => id < 0;
}

class JourneyStatusModel {
  JourneyStatusModel({
    required this.journeyId,
    required this.status,
    required this.progressPercent,
    required this.cardsCompleted,
    required this.cardsTotal,
    required this.checklistCompleted,
    required this.checklistTotal,
  });

  final int journeyId;
  final String status;
  final int progressPercent;
  final int cardsCompleted;
  final int cardsTotal;
  final int checklistCompleted;
  final int checklistTotal;

  factory JourneyStatusModel.fromJson(Map<String, dynamic> json) => JourneyStatusModel(
        journeyId: json['journeyId'] as int,
        status: json['status'] as String? ?? 'DRAFT',
        progressPercent: json['progressPercent'] as int? ?? 0,
        cardsCompleted: json['cardsCompleted'] as int? ?? 0,
        cardsTotal: json['cardsTotal'] as int? ?? 0,
        checklistCompleted: json['checklistCompleted'] as int? ?? 0,
        checklistTotal: json['checklistTotal'] as int? ?? 0,
      );
}

class CardModel {
  CardModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.icon,
    required this.displayOrder,
    required this.viewed,
    this.detail,
  });

  final int id;
  final String title;
  final String summary;
  final String category;
  final String icon;
  final int displayOrder;
  final bool viewed;
  final Map<String, dynamic>? detail;

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        category: json['category'] as String? ?? '',
        icon: json['icon'] as String? ?? '',
        displayOrder: json['displayOrder'] as int? ?? 0,
        viewed: json['viewed'] as bool? ?? false,
        detail: json['detail'] as Map<String, dynamic>?,
      );
}

class ChecklistItemModel {
  ChecklistItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.displayOrder,
    required this.completed,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final int displayOrder;
  final bool completed;

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) => ChecklistItemModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        displayOrder: json['displayOrder'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
      );
}

class ChecklistModel {
  ChecklistModel({
    required this.journeyId,
    required this.title,
    required this.completionPercent,
    required this.items,
  });

  final int journeyId;
  final String title;
  final int completionPercent;
  final List<ChecklistItemModel> items;

  factory ChecklistModel.fromJson(Map<String, dynamic> json) => ChecklistModel(
        journeyId: json['journeyId'] as int,
        title: json['title'] as String? ?? 'Essentials',
        completionPercent: json['completionPercent'] as int? ?? 0,
        items: (json['items'] as List? ?? [])
            .map((e) => ChecklistItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class KnowledgeCategoryModel {
  KnowledgeCategoryModel({required this.name, required this.icon, required this.journeyCount});

  final String name;
  final String icon;
  final int journeyCount;

  factory KnowledgeCategoryModel.fromJson(Map<String, dynamic> json) => KnowledgeCategoryModel(
        name: json['name'] as String? ?? '',
        icon: json['icon'] as String? ?? 'category',
        journeyCount: json['journeyCount'] as int? ?? 0,
      );
}

class KnowledgeNodeModel {
  KnowledgeNodeModel({required this.nodeType, required this.name, required this.description});

  final String nodeType;
  final String name;
  final String description;

  factory KnowledgeNodeModel.fromJson(Map<String, dynamic> json) => KnowledgeNodeModel(
        nodeType: json['nodeType'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}

class KnowledgeEdgeModel {
  KnowledgeEdgeModel({required this.sourceName, required this.targetName, required this.relationshipType});

  final String sourceName;
  final String targetName;
  final String relationshipType;

  factory KnowledgeEdgeModel.fromJson(Map<String, dynamic> json) => KnowledgeEdgeModel(
        sourceName: json['sourceName'] as String? ?? '',
        targetName: json['targetName'] as String? ?? '',
        relationshipType: json['relationshipType'] as String? ?? '',
      );
}

class CommunityInsightModel {
  CommunityInsightModel({
    required this.id,
    required this.insightType,
    required this.title,
    required this.content,
    this.journeyContext,
    this.severity,
    required this.votes,
  });

  final int id;
  final String insightType;
  final String title;
  final String content;
  final String? journeyContext;
  final String? severity;
  final int votes;

  factory CommunityInsightModel.fromJson(Map<String, dynamic> json) => CommunityInsightModel(
        id: json['id'] as int,
        insightType: json['insightType'] as String? ?? 'TIP',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        journeyContext: json['journeyContext'] as String?,
        severity: json['severity'] as String?,
        votes: json['votes'] as int? ?? 0,
      );
}

class UserModel {
  UserModel({required this.id, required this.name, required this.email, this.profilePicture});

  final int id;
  final String name;
  final String email;
  final String? profilePicture;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        profilePicture: json['profilePicture'] as String?,
      );
}

class ProfileStatsModel {
  ProfileStatsModel({
    required this.journeysCreated,
    required this.cardsCompleted,
    required this.checklistItemsCompleted,
    required this.impactScore,
  });

  final int journeysCreated;
  final int cardsCompleted;
  final int checklistItemsCompleted;
  final int impactScore;
}
