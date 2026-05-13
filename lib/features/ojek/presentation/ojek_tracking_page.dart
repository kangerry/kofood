import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import '../../../core/network/dio_client.dart';
import 'dart:async';
import 'dart:math' as math;

class OjekTrackingPage extends ConsumerStatefulWidget {
  final String orderId;
  const OjekTrackingPage({super.key, required this.orderId});
  @override
  ConsumerState<OjekTrackingPage> createState() => _OjekTrackingPageState();
}

class _OjekTrackingPageState extends ConsumerState<OjekTrackingPage> {
  ll.LatLng _origin = const ll.LatLng(-6.175392, 106.827153);
  ll.LatLng _driverPos = const ll.LatLng(-6.175392, 106.827153);
  ll.LatLng _destination = const ll.LatLng(-6.2, 106.83);
  String _driverName = 'Driver';
  String _driverPlate = '';
  String _status = 'baru';
  int _etaMinutes = 10;
  String _tileKey = '';
  final fmap.MapController _leaflet = fmap.MapController();
  Timer? _timer;
  bool _followDriver = true;
  final List<ll.LatLng> _driverTrail = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
    WidgetsBinding.instance.addPostFrameCallback((_) => _poll());
  }

  Future<void> _loadConfig() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/public-config');
      final data = res.data is Map ? (res.data as Map) : {};
      final key = (data['maps_tile_key']?.toString() ?? data['maps_api_key']?.toString() ?? '').trim();
      if (mounted) setState(() { _tileKey = key; });
    } catch (_) {}
  }

  double _haversineKm(ll.LatLng a, ll.LatLng b) {
    const R = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final h = (math.sin(dLat / 2) * math.sin(dLat / 2)) + (math.sin(dLon / 2) * math.sin(dLon / 2)) * math.cos(lat1) * math.cos(lat2);
    return 2 * R * math.asin(math.sqrt(h));
  }

  void _updateEta() {
    final distKm = _haversineKm(_driverPos, _destination);
    final speedKmh = 30.0;
    final minutes = (distKm / speedKmh) * 60.0;
    _etaMinutes = minutes.clamp(2.0, 120.0).round();
  }

  Future<void> _poll() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/api/v1/kojek/ride/orders/${widget.orderId}/tracking');
      final d = Map<String, dynamic>.from(resp.data['data'] ?? {});
      final status = '${d['status'] ?? 'baru'}';
      final origin = Map<String, dynamic>.from(d['origin'] ?? {});
      final dest = Map<String, dynamic>.from(d['destination'] ?? {});
      final drv = Map<String, dynamic>.from(d['driver'] ?? {});
      final nextDriver = ll.LatLng((drv['lat'] as num).toDouble(), (drv['lng'] as num).toDouble());
      setState(() {
        _status = status;
        _driverName = '${drv['name'] ?? 'Driver'}';
        _driverPlate = '${drv['plate'] ?? ''}';
        _driverPos = nextDriver;
        _origin = ll.LatLng((origin['lat'] as num).toDouble(), (origin['lng'] as num).toDouble());
        _destination = ll.LatLng((dest['lat'] as num).toDouble(), (dest['lng'] as num).toDouble());
        if (_driverTrail.isEmpty) {
          _driverTrail.add(nextDriver);
        } else {
          final last = _driverTrail.last;
          if (_haversineKm(last, nextDriver) >= 0.02) {
            _driverTrail.add(nextDriver);
            if (_driverTrail.length > 300) _driverTrail.removeAt(0);
          }
        }
        _updateEta();
      });
      if (_followDriver) {
        _leaflet.move(_driverPos, 14);
      }
      if (_status == 'selesai' || _status == 'batal' || _status == 'dibatalkan') {
        _timer?.cancel();
        _timer = null;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _labelFromStatus(String s) {
    switch (s) {
      case 'baru':
        return 'Order dibuat';
      case 'menjemput':
        return 'Driver menerima order';
      case 'tiba_jemput':
        return 'Driver tiba di titik jemput';
      case 'jalan':
        return 'Sedang perjalanan';
      case 'selesai':
        return 'Selesai';
      case 'batal':
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'gagal':
        return 'Gagal';
      default:
        return 'Status: ${s.trim().isEmpty ? '-' : s}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusLabel = _labelFromStatus(_status);
    return Scaffold(
      appBar: AppBar(title: const Text('Lacak OJEK')),
      body: Stack(
        children: [
          fmap.FlutterMap(
              mapController: _leaflet,
              options: fmap.MapOptions(
                initialCenter: _origin,
                initialZoom: 13,
              ),
              children: [
                fmap.TileLayer(
                  urlTemplate: _tileKey.isNotEmpty
                      ? 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=${_tileKey}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.komera_mobile',
                ),
                fmap.MarkerLayer(markers: [
                  fmap.Marker(point: _origin, width: 28, height: 28, child: const Icon(Icons.place, color: Colors.green)),
                  fmap.Marker(point: _destination, width: 28, height: 28, child: const Icon(Icons.flag, color: Colors.red)),
                  fmap.Marker(point: _driverPos, width: 32, height: 32, child: Icon(Icons.motorcycle, color: scheme.primary)),
                ]),
                fmap.PolylineLayer(polylines: <fmap.Polyline>[
                  fmap.Polyline(points: [_origin, _destination], color: scheme.primary, strokeWidth: 3.4),
                  if (_driverTrail.length >= 2) fmap.Polyline(points: _driverTrail, color: scheme.primary.withOpacity(0.35), strokeWidth: 7),
                ]),
              ],
            ),
          Positioned(
            right: 16,
            bottom: 168,
            child: FloatingActionButton.small(
              onPressed: () => setState(() => _followDriver = !_followDriver),
              child: Icon(_followDriver ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Material(
              elevation: 6,
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primary.withOpacity(0.12),
                      foregroundColor: scheme.primary,
                      child: const Icon(Icons.motorcycle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_driverName • $_driverPlate', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('ETA $_etaMinutes menit', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
