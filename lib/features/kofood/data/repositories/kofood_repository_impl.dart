import '../../domain/entities/merchant.dart';
import '../../domain/entities/product.dart';
import '../datasource/kofood_remote_data_source.dart';

abstract class KoFoodRepository {
  Future<List<Merchant>> getMerchants();
  Future<List<Merchant>> getMerchantsNear({double? lat, double? lng, double? radiusKm});
  Future<Merchant> getMerchantDetail(String id);
  Future<List<Product>> getProductsByMerchant(String merchantId);
  Future<Product> getProductById(String productId);
  Future<Map<String, dynamic>> createOrder({
    required String merchantId,
    required List<Map<String, dynamic>> items,
    required String payment,
    required String destAddress,
    required double destLat,
    required double destLng,
    required String destNote,
    String? paymentSub,
  });
}

class KoFoodRepositoryImpl implements KoFoodRepository {
  final KoFoodRemoteDataSource remote;
  KoFoodRepositoryImpl(this.remote);

  @override
  Future<Merchant> getMerchantDetail(String id) {
    return remote.fetchMerchantDetail(id);
  }

  @override
  Future<List<Merchant>> getMerchants() {
    return remote.fetchMerchants();
  }

  @override
  Future<List<Merchant>> getMerchantsNear({double? lat, double? lng, double? radiusKm}) {
    return remote.fetchMerchants(lat: lat, lng: lng, radiusKm: radiusKm);
  }

  @override
  Future<List<Product>> getProductsByMerchant(String merchantId) {
    return remote.fetchProductsByMerchant(merchantId);
  }

  @override
  Future<Product> getProductById(String productId) {
    return remote.fetchProductById(productId);
  }

  @override
  Future<Map<String, dynamic>> createOrder({
    required String merchantId,
    required List<Map<String, dynamic>> items,
    required String payment,
    required String destAddress,
    required double destLat,
    required double destLng,
    required String destNote,
    String? paymentSub,
  }) {
    return remote.createOrder(
      merchantId: merchantId,
      items: items,
      payment: payment,
      destAddress: destAddress,
      destLat: destLat,
      destLng: destLng,
      destNote: destNote,
      paymentSub: paymentSub,
    );
  }
}
