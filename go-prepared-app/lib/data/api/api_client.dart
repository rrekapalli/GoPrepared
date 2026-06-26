import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_result.dart';

/// Low-level HTTP client for GoPrepared API (`/api/v1/...`).
class ApiClient {
  ApiClient({
    required String baseUrl,
    String? accessToken,
    Dio? dio,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 60),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    if (accessToken != null) {
      this.accessToken = accessToken;
    }
  }

  final Dio _dio;
  String? accessToken;

  void setAccessToken(String? token) => accessToken = token;

  ApiRequestOptions get(String path, {Map<String, String>? queryParameters}) =>
      ApiRequestOptions._(this, method: 'GET', path: path, queryParameters: queryParameters);

  ApiRequestOptions post(String path) =>
      ApiRequestOptions._(this, method: 'POST', path: path);

  ApiRequestOptions put(String path) =>
      ApiRequestOptions._(this, method: 'PUT', path: path);

  ApiRequestOptions patch(String path) =>
      ApiRequestOptions._(this, method: 'PATCH', path: path);

  ApiRequestOptions delete(String path) =>
      ApiRequestOptions._(this, method: 'DELETE', path: path);

  Future<ApiResult<T>> sendRequest<T>({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Object? data,
    Object? Function(Object? json)? decodeJson,
  }) async {
    try {
      final options = Options(method: method);
      if (accessToken != null && accessToken!.isNotEmpty) {
        options.headers = {'Authorization': 'Bearer $accessToken'};
      }

      final response = await _dio.request<Object?>(
        path.startsWith('/') ? path.substring(1) : path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        if (decodeJson == null) {
          return ApiSuccess(true as T);
        }
        return ApiSuccess(decodeJson(response.data) as T);
      }

      return ApiFailure<T>(
        message: _messageFromBody(response.data) ?? 'Request failed ($status)',
        statusCode: status,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      return ApiFailure<T>(
        message: _messageFromBody(body) ?? e.message ?? 'Network error',
        statusCode: status,
        cause: e,
      );
    } catch (e) {
      return ApiFailure<T>(message: e.toString(), cause: e);
    }
  }

  static String? _messageFromBody(Object? body) {
    if (body == null) return null;
    if (body is Map) {
      final msg = body['message'] ?? body['error'] ?? body['detail'];
      if (msg != null) return msg.toString();
    }
    if (body is String && body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          return _messageFromBody(decoded);
        }
      } catch (_) {
        return body.length > 200 ? '${body.substring(0, 200)}…' : body;
      }
    }
    return null;
  }
}

class ApiRequestOptions {
  ApiRequestOptions._(
    this._client, {
    this.method = 'GET',
    this.path = '',
    this.queryParameters,
  });

  final ApiClient _client;
  final String method;
  final String path;
  final Map<String, String>? queryParameters;

  Object? Function(Object? body)? _encodeJson;
  Object? Function(Object? json)? _decodeJson;

  ApiRequestOptions encodeJson(Object? Function(Object? body) fn) {
    _encodeJson = fn;
    return this;
  }

  ApiRequestOptions decodeJson<T>(T Function(Object? json) fn) {
    _decodeJson = (json) => fn(json);
    return this;
  }

  Future<ApiResult<T>> send<T>() {
    Object? data;
    if (_encodeJson != null) {
      data = _encodeJson!(null);
    }
    return _client.sendRequest<T>(
      method: method,
      path: path,
      queryParameters: queryParameters,
      data: data,
      decodeJson: _decodeJson,
    );
  }
}
