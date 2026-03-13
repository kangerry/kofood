import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final dio = ref.read(dioProvider);
  if (!auth.isLoggedIn) {
    return {'role': 'guest', 'user': {}};
  }
  final res = await dio.get(
    '/api/v1/auth/profile',
    options: Options(headers: {'Cache-Control': 'no-cache'}),
  );
  return Map<String, dynamic>.from(res.data as Map);
});
