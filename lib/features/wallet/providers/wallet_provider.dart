import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

final walletSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/api/v1/wallet/summary');
  return Map<String, dynamic>.from(res.data as Map);
});

final walletTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/api/v1/wallet/transactions');
  final data = res.data;
  if (data is List) {
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  if (data is Map && data['items'] is List) {
    return (data['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return <Map<String, dynamic>>[];
});

final bankAccountsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/api/v1/wallet/bank-accounts');
  final items = (res.data is Map && (res.data['items'] is List)) ? (res.data['items'] as List) : const [];
  return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
