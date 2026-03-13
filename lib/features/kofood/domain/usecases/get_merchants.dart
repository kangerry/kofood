import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komera_mobile/core/network/dio_client.dart';
import '../../data/repositories/kofood_repository_impl.dart';
import '../entities/merchant.dart';
import '../../data/datasource/kofood_remote_data_source.dart';
import 'package:komera_mobile/core/location/location_provider.dart';

final merchantsRadiusKmProvider = StateProvider<double>((ref) => 10);

final koFoodRepositoryProvider = Provider<KoFoodRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return KoFoodRepositoryImpl(KoFoodRemoteDataSource(dio));
});

final getMerchantsProvider = FutureProvider<List<Merchant>>((ref) async {
  final repo = ref.read(koFoodRepositoryProvider);
  final pos = await ref.read(currentPositionProvider.future).catchError((_) => null);
  final radius = ref.watch(merchantsRadiusKmProvider);
  if (pos != null) {
    return repo.getMerchantsNear(lat: pos.lat, lng: pos.lng, radiusKm: radius);
  } else {
    return repo.getMerchants();
  }
});
