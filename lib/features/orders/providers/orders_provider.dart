import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

final myOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final Response resp = await dio.get('/api/v1/kofood/orders/my');
  final data = (resp.data['data'] as List).cast<Map<String, dynamic>>();
  return data;
});
