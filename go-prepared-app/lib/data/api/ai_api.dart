import 'package:go_prepared_app/data/api/api_client.dart';
import 'package:go_prepared_app/data/api/api_result.dart';
import 'package:go_prepared_app/data/models/ai.dart';

abstract class AiApi {
  Future<ApiResult<AiChatResponse>> chat({
    required String message,
    String? journeyId,
    String? cardId,
    String? conversationId,
  });

  Future<ApiResult<AiConversationListResponse>> getConversations({
    int page = 1,
    int pageSize = 20,
  });

  Future<ApiResult<AiConversation>> getConversation(String conversationId);
}

class AiApiImpl implements AiApi {
  AiApiImpl(this.client);

  final ApiClient client;

  @override
  Future<ApiResult<AiChatResponse>> chat({
    required String message,
    String? journeyId,
    String? cardId,
    String? conversationId,
  }) {
    return client
        .post('/api/v1/ai/chat')
        .encodeJson((_) => {
              'message': message,
              if (journeyId != null) 'journeyId': journeyId,
              if (cardId != null) 'cardId': cardId,
              if (conversationId != null) 'conversationId': conversationId,
            })
        .decodeJson(
          (json) => AiChatResponse.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<AiConversationListResponse>> getConversations({
    int page = 1,
    int pageSize = 20,
  }) {
    return client
        .get(
          '/api/v1/ai/conversations',
          queryParameters: {
            'page': page.toString(),
            'pageSize': pageSize.toString(),
          },
        )
        .decodeJson(
          (json) => AiConversationListResponse.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .send();
  }

  @override
  Future<ApiResult<AiConversation>> getConversation(String conversationId) {
    return client
        .get('/api/v1/ai/conversations/$conversationId')
        .decodeJson(
          (json) => AiConversation.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }
}
