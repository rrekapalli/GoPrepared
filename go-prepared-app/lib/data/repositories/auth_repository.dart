import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/auth/token_storage.dart';
import '../../core/config/app_config.dart';
import '../models/ai_models.dart';

class AuthRepository {
  AuthRepository(this._dio, {GlobalKey<NavigatorState>? navigatorKey}) : _navigatorKey = navigatorKey;

  final Dio _dio;
  final GlobalKey<NavigatorState>? _navigatorKey;

  GoogleSignIn? _googleSignIn;
  AadOAuth? _aadOAuth;

  GoogleSignIn get googleSignIn => _googleSignIn ??= GoogleSignIn(
        clientId: kIsWeb && AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
        serverClientId: !kIsWeb && AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
        scopes: const ['email', 'profile', 'openid'],
      );

  AadOAuth get aadOAuth {
    if (_aadOAuth != null) return _aadOAuth!;
    final key = _navigatorKey;
    if (key == null) {
      throw StateError('Navigator key required for Microsoft sign-in');
    }
    _aadOAuth = AadOAuth(Config(
      tenant: AppConfig.microsoftTenantId,
      clientId: AppConfig.microsoftClientId,
      scope: 'openid profile offline_access email',
      redirectUri: AppConfig.oauthRedirectUri,
      navigatorKey: key,
      webUseRedirect: true,
    ));
    return _aadOAuth!;
  }

  Future<bool> isAuthenticated() async {
    final token = await tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<UserModel?> currentUser() async {
    if (!await isAuthenticated()) return null;
    try {
      return await me();
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> me() async {
    final res = await _dio.get('/users/me');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> loginWithGoogle() async {
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw AuthCancelledException();
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google did not return an ID token');
    }
    return _exchangeIdToken('/auth/google', idToken);
  }

  Future<UserModel> loginWithMicrosoft() async {
    if (AppConfig.microsoftClientId.isEmpty) {
      throw Exception('Microsoft OAuth is not configured');
    }
    await aadOAuth.login();
    final idToken = await aadOAuth.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Microsoft did not return an ID token');
    }
    return _exchangeIdToken('/auth/microsoft', idToken);
  }

  Future<UserModel> devLogin({String email = 'dev@goprepared.app', String name = 'Dev User'}) async {
    if (!kDebugMode || !AppConfig.devAuthEnabled) {
      throw Exception('Dev login is not available');
    }
    final res = await _dio.post('/auth/dev', data: {'email': email, 'name': name});
    return _persistAuthResponse(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await tokenStorage.clearToken();
    try {
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}
    try {
      if (_aadOAuth != null) {
        await _aadOAuth!.logout();
      }
    } catch (_) {}
  }

  Future<UserModel> _exchangeIdToken(String path, String idToken) async {
    final res = await _dio.post(path, data: {'idToken': idToken});
    return _persistAuthResponse(res.data as Map<String, dynamic>);
  }

  Future<UserModel> _persistAuthResponse(Map<String, dynamic> data) async {
    final token = data['accessToken'] as String;
    await tokenStorage.writeToken(token);
    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson != null) {
      return UserModel.fromJson(userJson);
    }
    return me();
  }
}

class AuthCancelledException implements Exception {
  @override
  String toString() => 'Sign-in cancelled';
}
