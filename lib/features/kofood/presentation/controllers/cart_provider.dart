import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';

class CartState {
  final List<CartItem> items;
  final int shipping;
  CartState({required this.items, required this.shipping});
  int get subtotal => items.fold(0, (p, e) => p + e.subtotal);
  int get total => subtotal + shipping;
  CartState copyWith({List<CartItem>? items, int? shipping}) {
    return CartState(items: items ?? this.items, shipping: shipping ?? this.shipping);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState(items: [], shipping: 5000));
  String _lineId(String productId, List<CartSelectedOption> options, String note) {
    final sorted = [...options]
      ..sort((a, b) {
        final g = a.groupId.compareTo(b.groupId);
        if (g != 0) return g;
        return a.itemId.compareTo(b.itemId);
      });
    final optKey = sorted.map((e) => '${e.groupId}:${e.itemId}').join('|');
    return '$productId#$optKey#${note.trim()}';
  }

  void add(Product p, {List<CartSelectedOption> options = const [], String note = ''}) {
    final id = _lineId(p.id, options, note);
    final idx = state.items.indexWhere((e) => e.lineId == id);
    if (idx >= 0) {
      final it = state.items[idx];
      final updated = it.copyWith(quantity: it.quantity + 1);
      final list = [...state.items]..[idx] = updated;
      state = state.copyWith(items: list);
      return;
    }
    state = state.copyWith(items: [...state.items, CartItem(lineId: id, product: p, quantity: 1, note: note, options: options)]);
  }

  void remove(String lineId) {
    state = state.copyWith(items: state.items.where((e) => e.lineId != lineId).toList());
  }
  void decrease(String lineId) {
    final idx = state.items.indexWhere((e) => e.lineId == lineId);
    if (idx >= 0) {
      final it = state.items[idx];
      if (it.quantity <= 1) {
        remove(lineId);
      } else {
        final list = [...state.items]..[idx] = it.copyWith(quantity: it.quantity - 1);
        state = state.copyWith(items: list);
      }
    }
  }

  void increase(String lineId) {
    final idx = state.items.indexWhere((e) => e.lineId == lineId);
    if (idx >= 0) {
      final it = state.items[idx];
      final list = [...state.items]..[idx] = it.copyWith(quantity: it.quantity + 1);
      state = state.copyWith(items: list);
    }
  }

  void clear() {
    state = state.copyWith(items: []);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
