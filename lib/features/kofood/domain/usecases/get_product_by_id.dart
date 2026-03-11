import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/kofood_repository_impl.dart';
import '../entities/product.dart';
import './get_merchants.dart';

final getProductByIdProvider = FutureProvider.family<Product, String>((ref, id) async {
  final repo = ref.read(koFoodRepositoryProvider);
  return repo.getProductById(id);
});
