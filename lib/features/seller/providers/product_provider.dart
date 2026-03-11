import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductFormState {
  final bool saving;
  const ProductFormState({this.saving = false});
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier() : super(const ProductFormState());
  Future<void> save() async {
    state = const ProductFormState(saving: true);
    await Future.delayed(const Duration(milliseconds: 500));
    state = const ProductFormState(saving: false);
  }
}

final productFormProvider = StateNotifierProvider<ProductFormNotifier, ProductFormState>((ref) => ProductFormNotifier());
