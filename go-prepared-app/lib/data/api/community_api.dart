import 'package:go_prepared_app/data/api/api_client.dart';
import 'package:go_prepared_app/data/api/api_result.dart';
import 'package:go_prepared_app/data/models/community.dart';

abstract class CommunityApi {
  Future<ApiResult<CommunityPostListResponse>> getPosts({
    int page = 1,
    int pageSize = 20,
    String? category,
  });

  Future<ApiResult<CommunityPost>> getPost(String postId);

  Future<ApiResult<CommunityPost>> createPost({
    required String title,
    required String body,
    String? category,
  });

  Future<ApiResult<CommunityComment>> createComment({
    required String postId,
    required String body,
  });
}

class CommunityApiImpl implements CommunityApi {
  CommunityApiImpl(this.client);

  final ApiClient client;

  @override
  Future<ApiResult<CommunityPostListResponse>> getPosts({
    int page = 1,
    int pageSize = 20,
    String? category,
  }) {
    return client
        .get(
          '/api/v1/community/posts',
          queryParameters: {
            'page': page.toString(),
            'pageSize': pageSize.toString(),
            if (category != null) 'category': category,
          },
        )
        .decodeJson(
          (json) => CommunityPostListResponse.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .send();
  }

  @override
  Future<ApiResult<CommunityPost>> getPost(String postId) {
    return client
        .get('/api/v1/community/posts/$postId')
        .decodeJson(
          (json) => CommunityPost.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<CommunityPost>> createPost({
    required String title,
    required String body,
    String? category,
  }) {
    return client
        .post('/api/v1/community/posts')
        .encodeJson((_) => {
              'title': title,
              'body': body,
              if (category != null) 'category': category,
            })
        .decodeJson(
          (json) => CommunityPost.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<CommunityComment>> createComment({
    required String postId,
    required String body,
  }) {
    return client
        .post('/api/v1/community/posts/$postId/comments')
        .encodeJson((_) => {'body': body})
        .decodeJson(
          (json) => CommunityComment.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }
}
