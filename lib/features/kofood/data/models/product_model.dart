import '../../domain/entities/product.dart';

class ProductModel extends Product {
  ProductModel({
    required super.id,
    required super.merchantId,
    required super.name,
    required super.description,
    required super.price,
    required super.images,
    required super.optionGroups,
  });
  factory ProductModel.fromJson(Map<String, dynamic> j) {
    final desc = (j['description'] ?? '').toString();
    final images = j['images'] is List ? List<String>.from(j['images']) : <String>[];
    final priceVal = j['price'] is int ? j['price'] as int : (j['price'] is num ? (j['price'] as num).toInt() : 0);
    final groupsRaw = j['optionGroups'] is List ? (j['optionGroups'] as List) : const [];
    final groups = groupsRaw.map((e) {
      final g = Map<String, dynamic>.from(e as Map);
      final itemsRaw = g['items'] is List ? (g['items'] as List) : const [];
      final items = itemsRaw.map((it) {
        final m = Map<String, dynamic>.from(it as Map);
        final price = m['price'] is int ? (m['price'] as int) : (m['price'] is num ? (m['price'] as num).toInt() : 0);
        return ProductOptionItem(id: (m['id'] ?? '').toString(), name: (m['name'] ?? '').toString(), price: price);
      }).toList();
      return ProductOptionGroup(
        id: (g['id'] ?? '').toString(),
        name: (g['name'] ?? '').toString(),
        type: (g['type'] ?? 'single').toString(),
        required: g['required'] == true,
        min: g['min'] is int ? g['min'] as int : (g['min'] is num ? (g['min'] as num).toInt() : null),
        max: g['max'] is int ? g['max'] as int : (g['max'] is num ? (g['max'] as num).toInt() : null),
        items: items,
      );
    }).toList();
    return ProductModel(
      id: (j['id'] ?? '').toString(),
      merchantId: (j['merchantId'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      description: desc,
      price: priceVal,
      images: images,
      optionGroups: groups,
    );
  }
  Map<String, dynamic> toJson() {
    return {'id': id, 'merchantId': merchantId, 'name': name, 'description': description, 'price': price, 'images': images};
  }
}
