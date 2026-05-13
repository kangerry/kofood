import 'product.dart';

class CartItem {
  final String lineId;
  final Product product;
  final int quantity;
  final String note;
  final List<CartSelectedOption> options;
  CartItem({
    required this.lineId,
    required this.product,
    required this.quantity,
    this.note = '',
    this.options = const [],
  });
  int get optionsUnitPrice => options.fold(0, (p, e) => p + e.price);
  int get unitPrice => product.price + optionsUnitPrice;
  int get subtotal => unitPrice * quantity;
  CartItem copyWith({
    String? lineId,
    Product? product,
    int? quantity,
    String? note,
    List<CartSelectedOption>? options,
  }) {
    return CartItem(
      lineId: lineId ?? this.lineId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      options: options ?? this.options,
    );
  }
}

class CartSelectedOption {
  final String groupId;
  final String groupName;
  final String itemId;
  final String itemName;
  final int price;
  const CartSelectedOption({
    required this.groupId,
    required this.groupName,
    required this.itemId,
    required this.itemName,
    required this.price,
  });
}
