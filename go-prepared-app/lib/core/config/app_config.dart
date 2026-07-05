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
  /// Production Tailscale + Azure Entra OAuth require HTTPS redirect URIs.
  static const gopreparedUseHttps = bool.fromEnvironment('GOPREPARED_USE_HTTPS', defaultValue: true);
  /// When native mobile runs without `--dart-define`, use deployed API (HTTPS on Tailscale).
  static const fallbackProductionHost = String.fromEnvironment(
    'FALLBACK_PRODUCTION_HOST',
    defaultValue: 'goprepared.tailce422e.ts.net',
  );
  static const androidEmulatorHost =
      bool.fromEnvironment('ANDROID_USE_EMULATOR_HOST', defaultValue: false);

  /// Hostname or full URL → API base (`…/api/v1`).
  static String apiBaseUrlFromHost(String hostOrUrl) {
    final trimmed = hostOrUrl.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final base = trimmed.replaceAll(RegExp(r'/+$'), '');
      return base.endsWith('/api/v1') ? base : '$base/api/v1';
    }
    final useHttps = gopreparedUseHttps || trimmed.endsWith('.ts.net');
    final scheme = useHttps ? 'https' : 'http';
    return '$scheme://$trimmed/api/v1';
  }

  /// OAuth redirect URI for Microsoft (must match Entra app registration).
  /// Web uses `{origin}/auth` — register e.g. http://goprepared.example.com/auth
  static String get oauthRedirectUri {
    if (kIsWeb) {
      final base = Uri.base;
      final port = base.hasPort && base.port != 80 && base.port != 443 ? ':${base.port}' : '';
      final runtime = '${base.scheme}://${base.host}$port/auth';

      if (microsoftRedirectUri.isNotEmpty) {
        final configured = Uri.tryParse(microsoftRedirectUri);
        // Dev-only compile-time URI (localhost:51518) must not override production PWA origin.
        if (configured != null &&
            _isLocalDevHost(configured.host) == _isLocalDevHost(base.host)) {
          return microsoftRedirectUri;
        }
      }
      return runtime;
    }
    if (microsoftRedirectUri.isNotEmpty) {
      return microsoftRedirectUri;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'msauth.com.goprepared.goPreparedApp://auth';
    }
    return 'msauth://com.goprepared.go_prepared_app/callback';
  }

  static bool _isLocalDevHost(String host) =>
      host == 'localhost' || host == '127.0.0.1';

  static bool _isLocalDevApiUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return _isLocalDevHost(uri.host) || uri.host == '10.0.2.2';
  }

  static void init() {
    apiBaseUrl = _resolveApiBaseUrl();
    _normalizeApiBaseUrl();
  }

  static String _resolveApiBaseUrl() {
    const fromDefine = String.fromEnvironment('API_BASE_URL');

    if (kIsWeb) {
      final page = Uri.base;
      final host = page.host;
      if (_isLocalDevHost(host)) {
        if (fromDefine.isNotEmpty && !_isLocalDevApiUrl(fromDefine)) {
          return fromDefine;
        }
        if (gopreparedHost.isNotEmpty) {
          return apiBaseUrlFromHost(gopreparedHost);
        }
        if (fallbackProductionHost.isNotEmpty) {
          return apiBaseUrlFromHost(fallbackProductionHost);
        }
        return 'http://$host:8080/api/v1';
      }
      final port = page.hasPort && page.port != 80 && page.port != 443 ? ':${page.port}' : '';
      return '${page.scheme}://$host$port/api/v1';
    }

    if (fromDefine.isNotEmpty && !_isLocalDevApiUrl(fromDefine)) {
      return fromDefine;
    }
    if (gopreparedHost.isNotEmpty) {
      return apiBaseUrlFromHost(gopreparedHost);
    }
    if (androidEmulatorHost && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    if (fallbackProductionHost.isNotEmpty) {
      return apiBaseUrlFromHost(fallbackProductionHost);
    }
    return 'http://localhost:8080/api/v1';
  }

  /// Production Tailscale hosts use HTTPS; HTTP breaks CORS preflight (301 redirect).
  static void _normalizeApiBaseUrl() {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || uri.scheme != 'http') return;
    if (uri.host.contains('.ts.net') || gopreparedUseHttps) {
      apiBaseUrl = apiBaseUrl.replaceFirst('http://', 'https://');
    }
  }

  static String get displayApiHost {
    final uri = Uri.tryParse(apiBaseUrl);
    return uri != null ? '${uri.host}${uri.hasPort ? ':${uri.port}' : ''}' : apiBaseUrl;
  }

  /// User-facing hint when the API host cannot be reached from this device.
  static String get apiUnreachableHint {
    final host = displayApiHost;
    if (host.contains('.ts.net')) {
      return 'Cannot reach $host. Install Tailscale on this device, join the same tailnet, then retry.';
    }
    if (_isLocalDevHost(host)) {
      return 'API offline at $host. Start Spring Boot locally or point API_BASE_URL to production in .env.';
    }
    return 'Cannot reach API at $host. Check your network connection and retry.';
  }
}
