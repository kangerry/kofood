import 'package:flutter_riverpod/flutter_riverpod.dart';

class MerchantState {
  final String name;
  final bool open;
  const MerchantState({required this.name, required this.open});
}

final merchantProvider = StateProvider<MerchantState>((ref) {
  return const MerchantState(name: 'Toko Komera', open: true);
});
