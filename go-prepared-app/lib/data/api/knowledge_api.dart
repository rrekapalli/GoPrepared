import 'package:go_prepared_app/data/api/api_client.dart';
import 'package:go_prepared_app/data/api/api_result.dart';
import 'package:go_prepared_app/data/models/knowledge.dart';

abstract class KnowledgeApi {
  Future<ApiResult<KnowledgeCategoriesResponse>> getCategories();

  Future<ApiResult<KnowledgeGraphResponse>> getGraph({
    String? category,
    String? type,
  });

  Future<ApiResult<KnowledgeNode>> getNode(String nodeId);

  Future<ApiResult<KnowledgeSearchResponse>> search({
    required String query,
    int limit = 20,
  });
}

class KnowledgeApiImpl implements KnowledgeApi {
  KnowledgeApiImpl(this.client);

  final ApiClient client;

  @override
  Future<ApiResult<KnowledgeCategoriesResponse>> getCategories() {
    return client
        .get('/api/v1/knowledge/categories')
        .decodeJson(
          (json) => KnowledgeCategoriesResponse.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .send();
  }

  @override
  Future<ApiResult<KnowledgeGraphResponse>> getGraph({
    String? category,
    String? type,
  }) {
    return client
        .get(
          '/api/v1/knowledge/graph',
          queryParameters: {
            if (category != null) 'category': category,
            if (type != null) 'type': type,
          },
        )
        .decodeJson(
          (json) => KnowledgeGraphResponse.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<KnowledgeNode>> getNode(String nodeId) {
    return client
        .get('/api/v1/knowledge/nodes/$nodeId')
        .decodeJson(
          (json) => KnowledgeNode.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<KnowledgeSearchResponse>> search({
    required String query,
    int limit = 20,
  }) {
    return client
        .get(
          '/api/v1/knowledge/search',
          queryParameters: {
            'q': query,
            'limit': limit.toString(),
          },
        )
        .decodeJson(
          (json) => KnowledgeSearchResponse.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }
}
