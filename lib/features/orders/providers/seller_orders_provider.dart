import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

final sellerOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final Response resp = await dio.get('/api/v1/seller/orders');
  final data = (resp.data['data'] as List?) ?? const [];
  return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
