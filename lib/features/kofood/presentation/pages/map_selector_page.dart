import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapSelectorPage extends StatefulWidget {
  final ll.LatLng? initial;
  const MapSelectorPage({super.key, this.initial});
  @override
  State<MapSelectorPage> createState() => _MapSelectorPageState();
}

class _MapSelectorPageState extends State<MapSelectorPage> {
  late ll.LatLng _center;
  double _zoom = 15;
  final TextEditingController _searchCtrl = TextEditingController();
  final Dio _dio = Dio(BaseOptions(headers: {'User-Agent': 'KomeraMobile/1.0'}));
  final fmap.MapController _leaflet = fmap.MapController();
  String _tileKey = '';
  String _styleMode = 'auto';

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? const ll.LatLng(-6.175392, 106.827153);
    _zoom = 15;
    _loadConfig();
    _loadStyleMode();
  }

  Future<void> _loadConfig() async {
    try {
      final res = await Dio().get('${Uri.base.origin}/api/v1/public-config');
      final data = res.data is Map ? (res.data as Map) : {};
      final key = (data['maps_tile_key']?.toString() ?? data['maps_api_key']?.toString() ?? '').trim();
      if (mounted) {
        setState(() {
          _tileKey = key;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStyleMode() async {
    final p = await SharedPreferences.getInstance();
    final m = p.getString('map_style_mode') ?? 'auto';
    setState(() => _styleMode = m);
  }
  Future<void> _saveStyleMode(String m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('map_style_mode', m);
    setState(() => _styleMode = m);
  }
  bool get _useDark {
    if (_styleMode == 'day') return false;
    if (_styleMode == 'night') return true;
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute;
    return (h > 18 || (h == 18 && m >= 30) || h < 6 || (h == 6 && m < 30));
  }
  String _tileUrl() {
    if (_tileKey.isEmpty) return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    final style = _styleMode == 'hc' ? 'outdoor' : (_useDark ? 'streets-v2-dark' : 'streets-v2');
    return 'https://api.maptiler.com/maps/$style/256/{z}/{x}/{y}.png?key=$_tileKey';
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
      setState(() {
        _center = ll.LatLng(lat, lon);
        _zoom = 16;
        _leaflet.move(_center, _zoom);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mencari lokasi')));
    }
  }

  Future<void> _gotoMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layanan lokasi nonaktif')));
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _center = ll.LatLng(pos.latitude, pos.longitude);
        _zoom = 16;
        _leaflet.move(_center, _zoom);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengambil lokasi saya')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _saveStyleMode(v),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'auto', child: Text('Otomatis')),
              const PopupMenuItem(value: 'day', child: Text('Siang')),
              const PopupMenuItem(value: 'night', child: Text('Malam')),
              const PopupMenuItem(value: 'hc', child: Text('Kontras Tinggi')),
            ],
            icon: const Icon(Icons.brightness_6),
          ),
        ],
      ),
      body: Stack(
        children: [
          fmap.FlutterMap(
            mapController: _leaflet,
            options: fmap.MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              interactionOptions: const fmap.InteractionOptions(flags: ~fmap.InteractiveFlag.doubleTapDragZoom),
              onPositionChanged: (pos, hasGesture) {
                final c = pos.center;
                if (c != null) {
                  _center = ll.LatLng(c.latitude, c.longitude);
                  _zoom = pos.zoom ?? _zoom;
                }
              },
            ),
            children: [
              fmap.TileLayer(
                urlTemplate: _tileUrl(),
                userAgentPackageName: 'com.example.komera_mobile',
                additionalOptions: const {},
              ),
              fmap.MarkerLayer(markers: [
                fmap.Marker(
                  point: _center,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.place, size: 36, color: Colors.redAccent),
                ),
              ]),
            ],
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
                Navigator.of(context).pop(_center);
              },
              icon: const Icon(Icons.check),
              label: const Text('Pilih Lokasi Ini'),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 82,
            child: FloatingActionButton(
              onPressed: _gotoMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
