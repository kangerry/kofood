class Product {
  final String id;
  final String merchantId;
  final String name;
  final String description;
  final int price;
  final List<String> images;
  final List<ProductOptionGroup> optionGroups;
  Product({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    this.optionGroups = const [],
  });
}

class ProductOptionGroup {
  final String id;
  final String name;
  final String type;
  final bool required;
  final int? min;
  final int? max;
  final List<ProductOptionItem> items;
  const ProductOptionGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.required,
    required this.min,
    required this.max,
    required this.items,
  });
  bool get isSingle => type == 'single';
}

class ProductOptionItem {
  final String id;
  final String name;
  final int price;
  const ProductOptionItem({required this.id, required this.name, required this.price});
}
