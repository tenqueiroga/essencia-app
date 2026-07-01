import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry original request
            final opts = error.requestOptions;
            final token = await _storage.read(key: 'access_token');
            opts.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          }
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)).post(
        ApiConstants.authRefresh,
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      if (response.statusCode == 200) {
        await _storage.write(key: 'access_token', value: response.data['access_token']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}
