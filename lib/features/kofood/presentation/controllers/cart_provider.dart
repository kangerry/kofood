import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';

class CartState {
  final List<CartItem> items;
  final int shipping;
  CartState({required this.items, required this.shipping});
  int get subtotal => items.fold(0, (p, e) => p + e.product.price * e.quantity);
  int get total => subtotal + shipping;
  CartState copyWith({List<CartItem>? items, int? shipping}) {
    return CartState(items: items ?? this.items, shipping: shipping ?? this.shipping);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState(items: [], shipping: 5000));
  void add(Product p) {
    final idx = state.items.indexWhere((e) => e.product.id == p.id);
    if (idx >= 0) {
      final it = state.items[idx];
      final updated = it.copyWith(quantity: it.quantity + 1);
      final list = [...state.items]..[idx] = updated;
      state = state.copyWith(items: list);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: p, quantity: 1)]);
    }
  }
  void remove(String productId) {
    state = state.copyWith(items: state.items.where((e) => e.product.id != productId).toList());
  }
  void decrease(String productId) {
    final idx = state.items.indexWhere((e) => e.product.id == productId);
    if (idx >= 0) {
      final it = state.items[idx];
      if (it.quantity <= 1) {
        remove(productId);
      } else {
        final list = [...state.items]..[idx] = it.copyWith(quantity: it.quantity - 1);
        state = state.copyWith(items: list);
      }
    }
  }
  void clear() {
    state = state.copyWith(items: []);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
