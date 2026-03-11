import 'dart:async';
import 'package:dio/dio.dart';
import '../models/merchant_model.dart';
import '../models/product_model.dart';

class KoFoodRemoteDataSource {
  final Dio dio;
  KoFoodRemoteDataSource(this.dio);

  Future<List<MerchantModel>> fetchMerchants({double? lat, double? lng, double? radiusKm}) async {
    final res = await dio.get(
      '/api/v1/kofood/merchants',
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (radiusKm != null) 'radius_km': radiusKm,
      },
    );
    final List list = res.data['data'] as List? ?? [];
    return list.map((e) => MerchantModel.fromJson(e)).toList();
  }

  Future<MerchantModel> fetchMerchantDetail(String merchantId) async {
    final res = await dio.get('/api/v1/kofood/merchants/$merchantId');
    return MerchantModel.fromJson(res.data['data']);
  }

  Future<List<ProductModel>> fetchProductsByMerchant(String merchantId) async {
    final res = await dio.get('/api/v1/kofood/merchants/$merchantId/products');
    final List list = res.data['data'] as List? ?? [];
    return list.map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<ProductModel> fetchProductById(String id) async {
    final res = await dio.get('/api/v1/kofood/products/$id');
    return ProductModel.fromJson(res.data['data']);
  }

  Future<Map<String, dynamic>> createOrder({
    required String merchantId,
    required List<Map<String, dynamic>> items,
    required String payment,
    required String destAddress,
    required double destLat,
    required double destLng,
    required String destNote,
  }) async {
    final res = await dio.post('/api/v1/kofood/orders', data: {
      'merchant_id': int.tryParse(merchantId) ?? merchantId,
      'items': items,
      'payment': payment,
      'alamat_tujuan': destAddress,
      'latitude_tujuan': destLat,
      'longitude_tujuan': destLng,
      'catatan_alamat': destNote,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }
}
