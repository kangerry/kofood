import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/kofood_repository_impl.dart';
import '../entities/merchant.dart';
import './get_merchants.dart';

final getMerchantDetailProvider = FutureProvider.family<Merchant, String>((ref, id) async {
  final repo = ref.read(koFoodRepositoryProvider);
  return repo.getMerchantDetail(id);
});
