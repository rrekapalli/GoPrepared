import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/auth/oauth_browser.dart';
import '../../core/auth/token_storage.dart';
import '../../core/config/app_config.dart';
import '../../core/config/oauth_config.dart';
import '../models/ai_models.dart';

class AuthRepository {
  AuthRepository(this._dio, {GlobalKey<NavigatorState>? navigatorKey}) : _navigatorKey = navigatorKey;

  final Dio _dio;
  final GlobalKey<NavigatorState>? _navigatorKey;

  OAuthConfig _oauthConfig = OAuthConfig.fromAppConfig();
  GoogleSignIn? _googleSignIn;
  AadOAuth? _aadOAuth;
  bool _microsoftRedirectHandled = false;

  void applyOAuthConfig(OAuthConfig config) {
    final sameMicrosoft = _oauthConfig.microsoftClientId == config.microsoftClientId &&
        _oauthConfig.microsoftTenantId == config.microsoftTenantId;
    _oauthConfig = config;
    _googleSignIn = null;
    if (!sameMicrosoft) {
      _aadOAuth = null;
    }
  }

  GoogleSignIn _googleSignInFor(OAuthConfig config) {
    return GoogleSignIn(
      clientId: kIsWeb && config.hasGoogle ? config.googleClientId : null,
      serverClientId: !kIsWeb && config.hasGoogle ? config.googleClientId : null,
      scopes: const ['email', 'profile', 'openid'],
    );
  }

  GoogleSignIn get googleSignIn => _googleSignIn ??= _googleSignInFor(_oauthConfig);

  AadOAuth _buildAadOAuth(OAuthConfig config) {
    final key = _navigatorKey;
    if (key == null) {
      throw StateError('Navigator key required for Microsoft sign-in');
    }
    return AadOAuth(Config(
      tenant: config.microsoftTenantId,
      clientId: config.microsoftClientId,
      scope: 'openid profile offline_access email',
      redirectUri: AppConfig.oauthRedirectUri,
      navigatorKey: key,
      webUseRedirect: true,
    ));
  }

  Future<UserModel> loginWithGoogle() async {
    final signIn = _googleSignIn ??= _googleSignInFor(_oauthConfig);
    final account = await signIn.signIn();
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
    if (!_oauthConfig.hasMicrosoft) {
      throw Exception('Microsoft OAuth is not configured');
    }
    _ensureMicrosoftRedirectUri();
    if (kIsWeb) {
      prepareMicrosoftOAuthRedirect(
        clientId: _oauthConfig.microsoftClientId,
        tenantId: _oauthConfig.microsoftTenantId,
        redirectUri: AppConfig.oauthRedirectUri,
      );
    }
    _aadOAuth ??= _buildAadOAuth(_oauthConfig);
    final result = await _aadOAuth!.login();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (_) => _finishMicrosoftLogin(),
    );
  }

  /// Called on `/auth` after Microsoft redirect — completes MSAL redirect promise only.
  /// Must NOT call [AadOAuth.login] here; that re-triggers acquireTokenRedirect (infinite loop).
  Future<UserModel> completeMicrosoftRedirect() async {
    if (_microsoftRedirectHandled) {
      throw Exception('Microsoft sign-in was already completed for this redirect');
    }
    if (!_oauthConfig.hasMicrosoft) {
      throw Exception('Microsoft OAuth is not configured');
    }
    _ensureMicrosoftRedirectUri();
    if (kIsWeb && !hasOAuthCallbackInBrowserUrl && !hasMicrosoftOAuthReturn) {
      throw Exception('No Microsoft sign-in response found. Start from the login page.');
    }
    _aadOAuth ??= _buildAadOAuth(_oauthConfig);
    final result = await _aadOAuth!.refreshToken().timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw Exception(
        'Microsoft sign-in timed out. Check that the API is running and the Azure redirect URI matches this URL.',
      ),
    );
    final user = await result.fold(
      (failure) => throw Exception(failure.message),
      (_) => _finishMicrosoftLogin(),
    );
    _microsoftRedirectHandled = true;
    clearMicrosoftOAuthSessionFlag();
    clearMicrosoftOAuthRedirectState();
    clearOAuthBrowserUrl('/home');
    return user;
  }

  void _ensureMicrosoftRedirectUri() {
    if (!kIsWeb || AppConfig.microsoftRedirectUri.isEmpty) return;
    final expected = Uri.parse(AppConfig.microsoftRedirectUri);
    final actualPort = Uri.base.hasPort ? Uri.base.port : (Uri.base.scheme == 'https' ? 443 : 80);
    if (expected.hasPort && actualPort != expected.port) {
      throw Exception(
        'Flutter web is on port $actualPort but Microsoft redirect URI expects port ${expected.port}. '
        'Restart with: .\\scripts\\flutter-run-web.ps1 (sets FLUTTER_WEB_PORT in .env)',
      );
    }
  }

  Future<UserModel> _finishMicrosoftLogin() async {
    final idToken = await _aadOAuth!.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Microsoft did not return an ID token');
    }
    return _exchangeIdToken('/auth/microsoft', idToken);
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

  Future<UserModel> devLogin({String email = 'dev@goprepared.app', String name = 'Dev User'}) async {
    if (!kDebugMode || !AppConfig.devAuthEnabled) {
      throw Exception('Dev login is not available');
    }
    final res = await _dio.post('/auth/dev', data: {'email': email, 'name': name});
    return _persistAuthResponse(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await tokenStorage.clearToken();
    _microsoftRedirectHandled = false;
    clearMicrosoftOAuthSessionFlag();
    clearMicrosoftOAuthRedirectState();
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
