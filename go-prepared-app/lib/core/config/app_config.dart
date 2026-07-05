import 'package:flutter/foundation.dart';

/// Resolves API base URL at runtime (Flutter web) or from `--dart-define`.
class AppConfig {
  static late final String apiBaseUrl;

  static const enableChecklist = true;
  static const enableKnowledge = true;
  static const enableCommunity = true;

  static const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
  static const microsoftClientId = String.fromEnvironment('MICROSOFT_CLIENT_ID', defaultValue: '');
  static const microsoftTenantId = String.fromEnvironment('MICROSOFT_TENANT_ID', defaultValue: 'common');
  static const microsoftRedirectUri = String.fromEnvironment('MICROSOFT_REDIRECT_URI', defaultValue: '');
  static const devAuthEnabled = bool.fromEnvironment('DEV_AUTH_ENABLED', defaultValue: true);
  static const gopreparedHost = String.fromEnvironment('GOPREPARED_HOST', defaultValue: '');
  /// When native mobile runs without `--dart-define`, use deployed API (Tailscale HTTP, not HTTPS).
  static const fallbackProductionHost = String.fromEnvironment(
    'FALLBACK_PRODUCTION_HOST',
    defaultValue: 'goprepared.tailce422e.ts.net',
  );
  static const androidEmulatorHost =
      bool.fromEnvironment('ANDROID_USE_EMULATOR_HOST', defaultValue: false);

  /// Hostname or full URL → API base (`…/api/v1`). Bare hostnames use HTTP (production has no TLS).
  static String apiBaseUrlFromHost(String hostOrUrl) {
    final trimmed = hostOrUrl.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final base = trimmed.replaceAll(RegExp(r'/+$'), '');
      return base.endsWith('/api/v1') ? base : '$base/api/v1';
    }
    return 'http://$trimmed/api/v1';
  }

  /// OAuth redirect URI for Microsoft (must match Entra app registration).
  /// Web uses `{origin}/auth` — register e.g. https://goprepared.example.com/auth
  static String get oauthRedirectUri {
    if (microsoftRedirectUri.isNotEmpty) {
      return microsoftRedirectUri;
    }
    if (kIsWeb) {
      final base = Uri.base;
      final port = base.hasPort && base.port != 80 && base.port != 443 ? ':${base.port}' : '';
      return '${base.scheme}://${base.host}$port/auth';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'msauth.com.goprepared.goPreparedApp://auth';
    }
    return 'msauth://com.goprepared.go_prepared_app/callback';
  }

  static void init() {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      apiBaseUrl = fromDefine;
      return;
    }

    if (kIsWeb) {
      final page = Uri.base;
      final host = page.host;
      // Local Flutter web dev → Spring Boot on :8080
      if (host == 'localhost' || host == '127.0.0.1') {
        apiBaseUrl = 'http://$host:8080/api/v1';
        return;
      }
      // Deployed PWA (nginx proxies /api/ to Spring Boot on same host)
      final port = page.hasPort && page.port != 80 && page.port != 443 ? ':${page.port}' : '';
      apiBaseUrl = '${page.scheme}://$host$port/api/v1';
      return;
    }

    // Native mobile: localhost is the device itself — use production host or LAN override.
    if (gopreparedHost.isNotEmpty) {
      apiBaseUrl = apiBaseUrlFromHost(gopreparedHost);
      return;
    }

    // Android emulator → host machine loopback (physical devices need MOBILE_API_BASE_URL or GOPREPARED_HOST).
    if (androidEmulatorHost && defaultTargetPlatform == TargetPlatform.android) {
      apiBaseUrl = 'http://10.0.2.2:8080/api/v1';
      return;
    }

    // Plain `flutter run` on a phone/emulator — default to deployed API, not device localhost.
    if (fallbackProductionHost.isNotEmpty) {
      apiBaseUrl = apiBaseUrlFromHost(fallbackProductionHost);
      return;
    }

    apiBaseUrl = 'http://localhost:8080/api/v1';
  }

  static String get displayApiHost {
    final uri = Uri.tryParse(apiBaseUrl);
    return uri != null ? '${uri.host}${uri.hasPort ? ':${uri.port}' : ''}' : apiBaseUrl;
  }
}
