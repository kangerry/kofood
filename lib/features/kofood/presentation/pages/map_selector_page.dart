import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSelectorPage extends StatefulWidget {
  final LatLng? initial;
  const MapSelectorPage({super.key, this.initial});
  @override
  State<MapSelectorPage> createState() => _MapSelectorPageState();
}

class _MapSelectorPageState extends State<MapSelectorPage> {
  late CameraPosition _camera;
  final TextEditingController _searchCtrl = TextEditingController();
  final Dio _dio = Dio(BaseOptions(headers: {'User-Agent': 'KomeraMobile/1.0'}));
  GoogleMapController? _mapCtrl;

  @override
  void initState() {
    super.initState();
    _camera = CameraPosition(target: widget.initial ?? const LatLng(-6.175392, 106.827153), zoom: 15);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchAndCenter(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'q': q, 'format': 'json', 'limit': 1},
      );
      final list = res.data is List ? res.data as List : [];
      if (list.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lokasi tidak ditemukan')));
        }
        return;
      }
      final m = list.first as Map;
      final lat = double.tryParse('${m['lat']}');
      final lon = double.tryParse('${m['lon']}');
      if (lat == null || lon == null) return;
      final target = LatLng(lat, lon);
      _camera = CameraPosition(target: target, zoom: 16);
      await _mapCtrl?.animateCamera(CameraUpdate.newCameraPosition(_camera));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mencari lokasi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _camera,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            onCameraMove: (pos) => _camera = pos,
            onMapCreated: (c) => _mapCtrl = c,
          ),
          const IgnorePointer(
            ignoring: true,
            child: Center(
              child: Icon(Icons.place, size: 36, color: Colors.redAccent),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 16,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: _searchAndCenter,
                decoration: InputDecoration(
                  hintText: 'Cari lokasi untuk memusatkan peta',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _searchAndCenter(_searchCtrl.text),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: ElevatedButton.icon(
              onPressed: () {
                final lat = _camera.target.latitude;
                final lng = _camera.target.longitude;
                Navigator.of(context).pop(LatLng(lat, lng));
              },
              icon: const Icon(Icons.check),
              label: const Text('Pilih Lokasi Ini'),
            ),
          ),
        ],
      ),
    );
  }
}
