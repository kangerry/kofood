import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/runtime.dart';

final baseUrlProvider = Provider<String>((ref) => '${RuntimeConfig.baseUrl.trimRight()}/api/v1');

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ref.read(baseUrlProvider), connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 20)));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await ref.read(_tokenStorageProvider).getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (e, handler) {
      return handler.next(e);
    },
  ));
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
});

abstract class TokenStorage {
  Future<String?> getToken();
  Future<void> setToken(String token);
  Future<void> clear();
}

class InMemoryTokenStorage implements TokenStorage {
  String? _token;
  @override
  Future<void> clear() async {
    _token = null;
  }

  @override
  Future<String?> getToken() async {
    return _token;
  }

  @override
  Future<void> setToken(String token) async {
    _token = token;
  }
}

final _tokenStorageProvider = Provider<TokenStorage>((ref) => InMemoryTokenStorage());
