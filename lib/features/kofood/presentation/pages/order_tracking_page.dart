import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/notification/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});
  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  GoogleMapController? controller;
  final LatLng _origin = const LatLng(-6.914744, 107.609810);
  LatLng _driverPos = const LatLng(-6.914744, 107.609810);
  LatLng _destination = const LatLng(-6.9, 107.62);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _timer;
  bool _followDriver = true;
  int _etaMinutes = 12;
  String _driverName = 'Driver';
  String _driverPlate = '';
  String _status = 'baru';
  String _lastNotifiedStatus = '';
  ProviderContainer? _provider;
  List<Map<String, dynamic>> _timeline = [];

  @override
  void initState() {
    super.initState();
    _markers.add(Marker(markerId: const MarkerId('origin'), position: _origin, infoWindow: const InfoWindow(title: 'Toko')));
    _markers.add(Marker(markerId: const MarkerId('dest'), position: _destination, infoWindow: const InfoWindow(title: 'Tujuan')));
    _markers.add(Marker(markerId: const MarkerId('driver'), position: _driverPos, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), infoWindow: const InfoWindow(title: 'Driver')));
    _rebuildRoute();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _pollTracking());
    WidgetsBinding.instance.addPostFrameCallback((_) => _pollTracking());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider ??= ProviderScope.containerOf(context);
  }

  void _rebuildRoute() {
    _polylines.clear();
    _polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blueAccent,
      width: 5,
      points: [_origin, _driverPos, _destination],
    ));
  }

  double _haversineKm(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = (b.latitude - a.latitude) * 3.1415926535 / 180.0;
    final dLon = (b.longitude - a.longitude) * 3.1415926535 / 180.0;
    final lat1 = a.latitude * 3.1415926535 / 180.0;
    final lat2 = b.latitude * 3.1415926535 / 180.0;
    final h = (math.sin(dLat / 2) * math.sin(dLat / 2)) + (math.sin(dLon / 2) * math.sin(dLon / 2)) * math.cos(lat1) * math.cos(lat2);
    return 2 * R * math.asin(math.sqrt(h));
  }

  void _updateEta() {
    final distKm = _haversineKm(_driverPos, _destination);
    final speedKmh = 30.0; // asumsi kecepatan rata-rata
    final minutes = (distKm / speedKmh) * 60.0;
    _etaMinutes = minutes.clamp(3.0, 60.0).round();
  }

  Future<void> _pollTracking() async {
    try {
      final container = _provider;
      if (container == null) return;
      final dio = container.read(dioProvider);
      final resp = await dio.get('/api/v1/kofood/orders/${widget.orderId}/tracking');
      final d = resp.data['data'] as Map<String, dynamic>;
      final status = (d['status'] as String?) ?? 'baru';
      final origin = d['origin'] as Map<String, dynamic>;
      final dest = d['destination'] as Map<String, dynamic>;
      final drv = d['driver'] as Map<String, dynamic>;
      final tl = (d['timeline'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];
      setState(() {
        _status = status;
        _timeline = tl;
        _driverName = (drv['name'] as String?) ?? 'Driver';
        _driverPlate = (drv['plate'] as String?) ?? '';
        _driverPos = LatLng((drv['lat'] as num).toDouble(), (drv['lng'] as num).toDouble());
        _destination = LatLng((dest['lat'] as num).toDouble(), (dest['lng'] as num).toDouble());
        _markers
          ..removeWhere((m) => true)
          ..add(Marker(markerId: const MarkerId('origin'), position: LatLng((origin['lat'] as num).toDouble(), (origin['lng'] as num).toDouble()), infoWindow: const InfoWindow(title: 'Toko')))
          ..add(Marker(markerId: const MarkerId('dest'), position: _destination, infoWindow: const InfoWindow(title: 'Tujuan')))
          ..add(Marker(markerId: const MarkerId('driver'), position: _driverPos, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), infoWindow: const InfoWindow(title: 'Driver')));
        _rebuildRoute();
        _updateEta();
      });
      if (_followDriver && controller != null) {
        controller!.animateCamera(CameraUpdate.newLatLng(_driverPos));
      }
      if (_status != _lastNotifiedStatus) {
        _lastNotifiedStatus = _status;
        final title = 'Status Pesanan';
        final body = _headlineFor(_status);
        NotificationService.show(title, body);
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
  int _stageIndexFor(String s) {
    switch (s) {
      case 'baru':
        return 0;
      case 'diproses':
        return 1;
      case 'dikirim':
        return 2;
      case 'selesai':
        return 3;
      default:
        return 0;
    }
  }

  String _headlineFor(String s) {
    switch (s) {
      case 'baru':
        return 'Pesanan dibuat';
      case 'diproses':
        return 'Pesanan diproses merchant';
      case 'dikirim':
        return 'Driver sedang menuju lokasi';
      case 'selesai':
        return 'Pesanan selesai';
      default:
        return 'Memproses pesanan';
    }
  }

  Widget _stageBar() {
    final idx = _stageIndexFor(_status);
    final stages = [
      {'label': 'Dibuat', 'icon': Icons.receipt_long_outlined},
      {'label': 'Diproses', 'icon': Icons.restaurant_menu},
      {'label': 'Diantar', 'icon': Icons.delivery_dining},
      {'label': 'Selesai', 'icon': Icons.check_circle_outline},
    ];
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (i) {
            final active = i <= idx;
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stages[i]['icon'] as IconData,
                    color: active ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stages[i]['label'] as String,
                    style: TextStyle(
                      color: active ? Colors.green : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  if (i < stages.length - 1)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      height: 2,
                      color: i < idx ? Colors.green : Colors.grey.shade300,
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lacak Pesanan'),
        actions: [
          IconButton(
            onPressed: () {
              // ignore: use_build_context_synchronously
              try { (context as dynamic).go('/kofood/chat/${widget.orderId}'); } catch (_) { Navigator.of(context).pushNamed('/kofood/chat/${widget.orderId}'); }
            },
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _origin, zoom: 12),
            onMapCreated: (c) => controller = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _stageBar(),
          ),
          Positioned(
            right: 16,
            bottom: 92,
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() => _followDriver = !_followDriver);
              },
              child: Icon(_followDriver ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 144,
            child: FloatingActionButton.small(
              onPressed: () {
                controller?.animateCamera(CameraUpdate.newLatLngZoom(_origin, 13));
              },
              child: const Icon(Icons.store_mall_directory),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.motorcycle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_headlineFor(_status), style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('$_driverName • $_driverPlate • ETA $_etaMinutes menit'),
                          const SizedBox(height: 6),
                          if (_timeline.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _timeline.map((e) {
                                final t = DateTime.tryParse('${e['time'] ?? ''}');
                                final timeText = t != null ? DateFormat('HH:mm').format(t) : '-';
                                return Chip(
                                  label: Text('${e['label']} • $timeText', style: const TextStyle(fontSize: 12)),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.route, color: Colors.blueAccent),
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
