import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final currentPositionProvider = FutureProvider<({double lat, double lng})?>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return null;
  }
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return null;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return null;
  }
  final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  return (lat: pos.latitude, lng: pos.longitude);
});

