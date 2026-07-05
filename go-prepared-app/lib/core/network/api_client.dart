import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/token_storage.dart';
import '../config/app_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));
  return dio;
});

/// Checks whether the API is reachable (public endpoint, no auth).
final apiHealthProvider = FutureProvider<bool>((ref) async {
  try {
    final dio = ref.read(dioProvider);
    await dio.get('/knowledge/categories');
    return true;
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return false;
    }
    // 401/500 still means server is up
    return e.response != null;
  } catch (_) {
    return false;
  }
});

final authTokenProvider = StateProvider<String?>((ref) => null);

String friendlyApiError(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout) {
      return AppConfig.apiUnreachableHint;
    }
    final status = error.response?.statusCode;
    if (status != null) return 'API error ($status). ${error.response?.data ?? ''}';
  }
  return 'Something went wrong. Please try again.';
}
