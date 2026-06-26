import 'package:go_prepared_app/data/api/api_client.dart';
import 'package:go_prepared_app/data/api/api_result.dart';
import 'package:go_prepared_app/data/models/user.dart';

abstract class UsersApi {
  Future<ApiResult<UserProfile>> getMe();

  Future<ApiResult<UserProfile>> updateMe({
    String? displayName,
    String? avatarUrl,
    String? locale,
  });
}

class UsersApiImpl implements UsersApi {
  UsersApiImpl(this.client);

  final ApiClient client;

  @override
  Future<ApiResult<UserProfile>> getMe() {
    return client
        .get('/api/v1/users/me')
        .decodeJson(
          (json) => UserProfile.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<UserProfile>> updateMe({
    String? displayName,
    String? avatarUrl,
    String? locale,
  }) {
    return client
        .put('/api/v1/users/me')
        .encodeJson((_) => {
              if (displayName != null) 'displayName': displayName,
              if (avatarUrl != null) 'avatarUrl': avatarUrl,
              if (locale != null) 'locale': locale,
            })
        .decodeJson(
          (json) => UserProfile.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }
}
