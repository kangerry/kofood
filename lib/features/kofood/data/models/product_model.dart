import '../../domain/entities/product.dart';

class ProductModel extends Product {
  ProductModel({required super.id, required super.merchantId, required super.name, required super.description, required super.price, required super.images});
  factory ProductModel.fromJson(Map<String, dynamic> j) {
    final desc = (j['description'] ?? '').toString();
    final images = j['images'] is List ? List<String>.from(j['images']) : <String>[];
    final priceVal = j['price'] is int ? j['price'] as int : (j['price'] is num ? (j['price'] as num).toInt() : 0);
    return ProductModel(
      id: (j['id'] ?? '').toString(),
      merchantId: (j['merchantId'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      description: desc,
      price: priceVal,
      images: images,
    );
  }
  Map<String, dynamic> toJson() {
    return {'id': id, 'merchantId': merchantId, 'name': name, 'description': description, 'price': price, 'images': images};
  }
}
