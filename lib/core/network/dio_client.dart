import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/preferences.dart';
import '../config/runtime.dart';

final dioProvider = Provider<Dio>((ref) {
  final prefs = ref.read(preferencesProvider);
  final dio = Dio(BaseOptions(
    baseUrl: RuntimeConfig.baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'User-Agent': 'KOMERA-Web',
    },
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await prefs.getToken();
      final koperasiId = await prefs.getKoperasiId();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      options.headers['X-Koperasi-Id'] = koperasiId;
      options.headers['ngrok-skip-browser-warning'] = 'true';
      options.headers['User-Agent'] = options.headers['User-Agent'] ?? 'KOMERA-Web';
      handler.next(options);
    },
    onError: (e, handler) async {
      if (e.response?.statusCode == 401) {
        await prefs.clearAuth();
      }
      handler.next(e);
    },
  ));
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
});
