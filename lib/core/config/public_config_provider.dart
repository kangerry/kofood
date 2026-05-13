import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';

class PublicConfig {
  final String mapsProvider; // 'google' | 'flutter_map'
  final String mapsApiKey;
  final String mapsTileKey;
  const PublicConfig({required this.mapsProvider, required this.mapsApiKey, required this.mapsTileKey});
}

final publicConfigProvider = FutureProvider<PublicConfig>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final Response res = await dio.get('/api/v1/public-config');
    final data = res.data is Map ? (res.data as Map) : {};
    final prov = (data['maps_provider']?.toString() ?? '').trim().toLowerCase();
    final tileKey = (data['maps_tile_key']?.toString() ?? '').trim();
    final apiKey = (data['maps_api_key']?.toString() ?? '').trim();
    return PublicConfig(
      mapsProvider: prov == 'flutter_map' ? 'flutter_map' : 'google',
      mapsApiKey: apiKey,
      mapsTileKey: tileKey.isNotEmpty ? tileKey : apiKey,
    );
  } catch (_) {
    return const PublicConfig(mapsProvider: 'google', mapsApiKey: '', mapsTileKey: '');
  }
});
