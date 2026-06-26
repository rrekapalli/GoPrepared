import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_prepared_app/core/config/app_config.dart';
import 'package:go_prepared_app/data/api/goprepared_api.dart';

/// Shared API client for the app (base URL from [AppConfig]).
final goPreparedApiProvider = Provider<GoPreparedApi>((ref) {
  return GoPreparedApi(baseUrl: AppConfig.apiBaseUrl);
});
