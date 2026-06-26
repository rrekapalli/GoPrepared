import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_models.dart';
import '../../core/network/api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

final sessionProvider = FutureProvider<void>((ref) async {
  await ref.read(authRepositoryProvider).ensureSession();
});

class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;

  Future<void> ensureSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('access_token') != null) return;
    await devLogin();
  }

  Future<String> devLogin({String email = 'dev@goprepared.app', String name = 'Dev User'}) async {
    final res = await _dio.post('/auth/dev', data: {'email': email, 'name': name});
    final token = res.data['accessToken'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    return token;
  }

  Future<UserModel> me() async {
    final res = await _dio.get('/users/me');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }
}

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return JourneyRepository(ref.watch(dioProvider));
});

class JourneyRepository {
  JourneyRepository(this._dio);
  final Dio _dio;

  Future<JourneyModel> createJourney(String query) async {
    final res = await _dio.post('/journeys', data: {'query': query});
    return JourneyModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<int> generateCards(int journeyId) async {
    final res = await _dio.post('/journeys/$journeyId/generate');
    return res.data['cardCount'] as int? ?? 0;
  }

  Future<List<JourneyModel>> listJourneys() async {
    final res = await _dio.get('/journeys');
    return (res.data as List).map((e) => JourneyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<JourneyModel> getJourney(int journeyId) async {
    final res = await _dio.get('/journeys/$journeyId');
    return JourneyModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<JourneyStatusModel> getJourneyStatus(int journeyId) async {
    final res = await _dio.get('/journeys/$journeyId/status');
    return JourneyStatusModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<CardModel>> getCards(int journeyId) async {
    final res = await _dio.get('/journeys/$journeyId/cards');
    return (res.data as List).map((e) => CardModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CardModel> getCard(int cardId) async {
    final res = await _dio.get('/cards/$cardId');
    return CardModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<String> askJourney(int journeyId, String question) async {
    final res = await _dio.post('/journeys/$journeyId/ask', data: {'question': question});
    return res.data['answer'] as String? ?? '';
  }

  Future<String> askCard(int cardId, String question) async {
    final res = await _dio.post('/cards/$cardId/ask', data: {'question': question});
    return res.data['answer'] as String? ?? '';
  }

  Future<ChecklistModel> getChecklist(int journeyId) async {
    final res = await _dio.get('/journeys/$journeyId/checklist');
    return ChecklistModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ChecklistItemModel> toggleChecklistItem(int itemId) async {
    final res = await _dio.post('/checklist/$itemId/complete');
    return ChecklistItemModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SimilarJourneyModel>> findSimilarJourneys(String query) async {
    final res = await _dio.get('/journeys/similar', queryParameters: {'query': query});
    return (res.data as List).map((e) => SimilarJourneyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProfileStatsModel> profileStats() async {
    final journeys = await listJourneys();
    var cardsCompleted = 0;
    var checklistDone = 0;
    for (final j in journeys) {
      try {
        final status = await getJourneyStatus(j.id);
        cardsCompleted += status.cardsCompleted;
        checklistDone += status.checklistCompleted;
      } catch (_) {}
    }
    return ProfileStatsModel(
      journeysCreated: journeys.length,
      cardsCompleted: cardsCompleted,
      checklistItemsCompleted: checklistDone,
      impactScore: cardsCompleted * 10 + checklistDone * 5 + journeys.length * 20,
    );
  }
}

final knowledgeRepositoryProvider = Provider<KnowledgeRepository>((ref) {
  return KnowledgeRepository(ref.watch(dioProvider));
});

class KnowledgeRepository {
  KnowledgeRepository(this._dio);
  final Dio _dio;

  Future<List<KnowledgeCategoryModel>> categories() async {
    final res = await _dio.get('/knowledge/categories');
    return (res.data as List).map((e) => KnowledgeCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<KnowledgeNodeModel>> nodes({String? category}) async {
    final res = await _dio.get('/knowledge/nodes', queryParameters: {
      if (category != null && category.isNotEmpty) 'category': category,
    });
    return (res.data as List).map((e) => KnowledgeNodeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<KnowledgeTemplateModel>> templates({String? journeyType}) async {
    final res = await _dio.get('/knowledge/templates', queryParameters: {
      if (journeyType != null && journeyType.isNotEmpty) 'journeyType': journeyType,
    });
    return (res.data as List).map((e) => KnowledgeTemplateModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<KnowledgeEdgeModel>> relationships() async {
    final res = await _dio.get('/knowledge/relationships');
    return (res.data as List).map((e) => KnowledgeEdgeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CommunityInsightModel>> community({int? journeyId}) async {
    final res = await _dio.get('/community', queryParameters: {
      if (journeyId != null) 'journeyId': journeyId,
    });
    return (res.data as List).map((e) => CommunityInsightModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CommunityInsightModel>> communityForJourney(int journeyId) => community(journeyId: journeyId);

  Future<CommunityInsightModel> contribute({
    required String insightType,
    required String title,
    required String content,
    String? journeyContext,
    String? severity,
    int? journeyId,
  }) async {
    final res = await _dio.post('/community/contribute', data: {
      'insightType': insightType,
      'title': title,
      'content': content,
      if (journeyContext != null) 'journeyContext': journeyContext,
      if (severity != null) 'severity': severity,
      if (journeyId != null) 'journeyId': journeyId,
    });
    return CommunityInsightModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<int> voteInsight(int insightId, {required bool helpful}) async {
    final res = await _dio.post('/community/vote', data: {'insightId': insightId, 'helpful': helpful});
    return res.data['votes'] as int? ?? 0;
  }
}
