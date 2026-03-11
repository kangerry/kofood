import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/kofood_repository_impl.dart';
import '../entities/product.dart';
import './get_merchants.dart';

final getProductsByMerchantProvider = FutureProvider.family<List<Product>, String>((ref, merchantId) async {
  final repo = ref.read(koFoodRepositoryProvider);
  return repo.getProductsByMerchant(merchantId);
});
