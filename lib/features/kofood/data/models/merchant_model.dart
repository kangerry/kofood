import '../../domain/entities/merchant.dart';

class MerchantModel extends Merchant {
  MerchantModel({required super.id, required super.name, required super.bannerUrl, required super.distanceKm, required super.rating, required super.address});
  factory MerchantModel.fromJson(Map<String, dynamic> j) {
    final banner = (j['bannerUrl'] ?? '').toString();
    final dist = (j['distanceKm'] is num) ? (j['distanceKm'] as num).toDouble() : 0.0;
    final rate = (j['rating'] is num) ? (j['rating'] as num).toDouble() : 0.0;
    return MerchantModel(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      bannerUrl: banner,
      distanceKm: dist,
      rating: rate,
      address: (j['address'] ?? '').toString(),
    );
  }
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'bannerUrl': bannerUrl, 'distanceKm': distanceKm, 'rating': rating, 'address': address};
  }
}
