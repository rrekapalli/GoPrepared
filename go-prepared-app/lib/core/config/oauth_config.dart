import 'package:dio/dio.dart';

import 'app_config.dart';

/// Public OAuth client IDs — safe to expose; loaded from compile-time defines or API.
class OAuthConfig {
  const OAuthConfig({
    this.googleClientId = '',
    this.microsoftClientId = '',
    this.microsoftTenantId = 'common',
  });

  final String googleClientId;
  final String microsoftClientId;
  final String microsoftTenantId;

  bool get hasGoogle => googleClientId.isNotEmpty;
  bool get hasMicrosoft => microsoftClientId.isNotEmpty;

  factory OAuthConfig.fromAppConfig() => OAuthConfig(
        googleClientId: _sanitize(AppConfig.googleClientId),
        microsoftClientId: _sanitize(AppConfig.microsoftClientId),
        microsoftTenantId: AppConfig.microsoftTenantId.isNotEmpty
            ? AppConfig.microsoftTenantId
            : 'common',
      );

  factory OAuthConfig.fromJson(Map<String, dynamic> json) => OAuthConfig(
        googleClientId: _sanitize(json['googleClientId'] as String? ?? ''),
        microsoftClientId: _sanitize(json['microsoftClientId'] as String? ?? ''),
        microsoftTenantId: (json['microsoftTenantId'] as String?)?.isNotEmpty == true
            ? json['microsoftTenantId'] as String
            : 'common',
      );

  OAuthConfig merge(OAuthConfig other) => OAuthConfig(
        googleClientId: hasGoogle ? googleClientId : other.googleClientId,
        microsoftClientId: hasMicrosoft ? microsoftClientId : other.microsoftClientId,
        microsoftTenantId: microsoftTenantId != 'common' || other.microsoftTenantId == 'common'
            ? microsoftTenantId
            : other.microsoftTenantId,
      );

  static String _sanitize(String value) {
    if (value.isEmpty || value.startsWith('your-')) return '';
    return value;
  }

  static Future<OAuthConfig> load(Dio dio) async {
    final base = OAuthConfig.fromAppConfig();
    if (base.hasMicrosoft) return base;
    try {
      final res = await dio.get('/auth/config');
      return base.merge(OAuthConfig.fromJson(res.data as Map<String, dynamic>));
    } catch (_) {
      return base;
    }
  }
}
