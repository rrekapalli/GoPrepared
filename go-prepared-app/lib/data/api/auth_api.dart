import 'package:go_prepared_app/data/api/api_client.dart';
import 'package:go_prepared_app/data/api/api_result.dart';
import 'package:go_prepared_app/data/models/auth.dart';

abstract class AuthApi {
  Future<ApiResult<AuthResponse>> loginWithGoogle(String idToken);

  Future<ApiResult<AuthResponse>> refresh(String refreshToken);

  Future<ApiResult<AuthResponse>> devLogin({
    String email = 'dev@goprepared.local',
    String displayName = 'Dev User',
  });
}

class AuthApiImpl implements AuthApi {
  AuthApiImpl(this.client);

  final ApiClient client;

  @override
  Future<ApiResult<AuthResponse>> loginWithGoogle(String idToken) async {
    return client
        .post('/api/v1/auth/google')
        .encodeJson((_) => GoogleAuthRequest(idToken: idToken).toJson())
        .decodeJson((json) => AuthResponse.fromJson(json as Map<String, dynamic>))
        .send();
  }

  @override
  Future<ApiResult<AuthResponse>> refresh(String refreshToken) async {
    return client
        .post('/api/v1/auth/refresh')
        .encodeJson((_) => RefreshTokenRequest(refreshToken: refreshToken).toJson())
        .decodeJson((json) => AuthResponse.fromJson(json as Map<String, dynamic>))
        .send();
  }

  @override
  Future<ApiResult<AuthResponse>> devLogin({
    String email = 'dev@goprepared.local',
    String displayName = 'Dev User',
  }) async {
    return client
        .post('/api/v1/auth/dev')
        .encodeJson((_) => DevLoginRequest(email: email, displayName: displayName).toJson())
        .decodeJson((json) => AuthResponse.fromJson(json as Map<String, dynamic>))
        .send();
  }
}
