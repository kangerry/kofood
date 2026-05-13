import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
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
  ll.LatLng _origin = const ll.LatLng(-6.914744, 107.609810);
  ll.LatLng _driverPos = const ll.LatLng(-6.914744, 107.609810);
  ll.LatLng _destination = const ll.LatLng(-6.9, 107.62);
  final fmap.MapController _leaflet = fmap.MapController();
  List<ll.LatLng> _route = [];
  final List<ll.LatLng> _driverTrail = [];
  Timer? _timer;
  Timer? _t5;
  Timer? _t10;
  Timer? _tDecisionAutoCancel;
  bool _followDriver = true;
  int _etaMinutes = 12;
  String _driverName = 'Driver';
  String _driverPlate = '';
  String _status = 'baru';
  String _lastNotifiedStatus = '';
  ProviderContainer? _provider;
  List<Map<String, dynamic>> _timeline = [];
  bool _warned5 = false;
  bool _asked10 = false;
  bool _decisionDialogOpen = false;
  bool _userChoseWait = false;
  bool _canceling = false;

  @override
  void initState() {
    super.initState();
    _rebuildRoute();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _pollTracking());
    _t5 = Timer(const Duration(minutes: 5), _on5MinutesNoDriver);
    _t10 = Timer(const Duration(minutes: 10), _on10MinutesNoDriver);
    WidgetsBinding.instance.addPostFrameCallback((_) => _pollTracking());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider ??= ProviderScope.containerOf(context);
  }

  void _rebuildRoute() {
    _route = [_origin, _destination];
  }

  double _haversineKm(ll.LatLng a, ll.LatLng b) {
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

  DateTime _toJakartaTime(DateTime dt) {
    return dt.toUtc().add(const Duration(hours: 7));
  }

  bool _awaitingDriver() {
    final plateEmpty = _driverPlate.trim().isEmpty;
    final name = _driverName.trim();
    final nameDefault = name.isEmpty || name == 'Driver';
    return (_status == 'baru' || _status == 'diproses') && plateEmpty && nameDefault;
  }

  void _stopDriverWaitFlow() {
    _t5?.cancel();
    _t5 = null;
    _t10?.cancel();
    _t10 = null;
    _tDecisionAutoCancel?.cancel();
    _tDecisionAutoCancel = null;
    if (_decisionDialogOpen) {
      _decisionDialogOpen = false;
      try {
        Navigator.of(context, rootNavigator: true).maybePop();
      } catch (_) {}
    }
  }

  void _on5MinutesNoDriver() {
    if (!mounted) return;
    if (_userChoseWait) return;
    if (_warned5) return;
    if (!_awaitingDriver()) return;
    _warned5 = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Driver mungkin sibuk, saya coba driver lain. Tunggu sebentar...'),
        duration: Duration(seconds: 6),
      ),
    );
  }

  Future<void> _on10MinutesNoDriver() async {
    if (!mounted) return;
    if (_userChoseWait) return;
    if (_asked10) return;
    if (!_awaitingDriver()) return;
    _asked10 = true;
    _decisionDialogOpen = true;
    _tDecisionAutoCancel?.cancel();
    _tDecisionAutoCancel = Timer(const Duration(minutes: 5), () {
      if (!mounted) return;
      if (_userChoseWait) return;
      if (!_decisionDialogOpen) return;
      _cancelOrder(auto: true);
    });
    final res = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Mencari Driver'),
          content: const Text(
            'Sudah 10 menit belum ada driver yang menerima. Anda ingin tetap menunggu driver atau membatalkan pesanan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('wait'),
              child: const Text('Tetap menunggu'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text('Batalkan pesanan'),
            ),
          ],
        );
      },
    );
    _decisionDialogOpen = false;
    _tDecisionAutoCancel?.cancel();
    _tDecisionAutoCancel = null;
    if (!mounted) return;
    if (!_awaitingDriver()) return;
    if (res == 'wait') {
      _userChoseWait = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tetap menunggu driver...')),
      );
      return;
    }
    if (res == 'cancel') {
      await _cancelOrder(auto: false);
      return;
    }
  }

  Future<void> _cancelOrder({required bool auto}) async {
    if (_canceling) return;
    if (!mounted) return;
    _canceling = true;
    try {
      final dio = (_provider ?? ProviderScope.containerOf(context)).read(dioProvider);
      await dio.post('/api/v1/kofood/orders/${widget.orderId}/cancel');
    } catch (_) {
    } finally {
      _canceling = false;
    }
    if (!mounted) return;
    _stopDriverWaitFlow();
    _timer?.cancel();
    _timer = null;
    setState(() {
      _status = 'dibatalkan';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auto ? 'Pesanan dibatalkan otomatis (tidak ada respon).' : 'Pesanan dibatalkan.'),
        duration: const Duration(seconds: 5),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    try {
      context.pop();
    } catch (_) {
      try {
        Navigator.of(context).maybePop();
      } catch (_) {}
    }
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
      final nextDriverPos = ll.LatLng((drv['lat'] as num).toDouble(), (drv['lng'] as num).toDouble());
      setState(() {
        _status = status;
        _timeline = tl;
        _driverName = (drv['name'] as String?) ?? 'Driver';
        _driverPlate = (drv['plate'] as String?) ?? '';
        _driverPos = nextDriverPos;
        _origin = ll.LatLng((origin['lat'] as num).toDouble(), (origin['lng'] as num).toDouble());
        _destination = ll.LatLng((dest['lat'] as num).toDouble(), (dest['lng'] as num).toDouble());
        if (_driverTrail.isEmpty) {
          _driverTrail.add(nextDriverPos);
        } else {
          final last = _driverTrail.last;
          final km = _haversineKm(last, nextDriverPos);
          if (km >= 0.02) {
            _driverTrail.add(nextDriverPos);
            if (_driverTrail.length > 300) {
              _driverTrail.removeAt(0);
            }
          }
        }
        _rebuildRoute();
        _updateEta();
      });
      if (_followDriver) {
        _leaflet.move(_driverPos, 13);
      }
      if (_status != _lastNotifiedStatus) {
        _lastNotifiedStatus = _status;
        final title = 'Status Pesanan';
        final body = _labelFromServerTimelineOrFallback();
        NotificationService.show(title, body);
      }
      if (!_awaitingDriver()) {
        _stopDriverWaitFlow();
      }
      if (_status == 'selesai' || _status == 'batal' || _status == 'dibatalkan') {
        _stopDriverWaitFlow();
        _timer?.cancel();
        _timer = null;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _t5?.cancel();
    _t10?.cancel();
    _tDecisionAutoCancel?.cancel();
    super.dispose();
  }

  String _statusKeyText(String s) {
    final v = s.trim();
    return v.isEmpty ? '-' : v;
  }

  String _labelFromServerTimelineOrFallback() {
    return _labelFromStatus(_status);
  }

  String _labelFromStatus(String s) {
    switch (s) {
      case 'baru':
        return 'Pesanan dibuat';
      case 'diproses':
        return 'Merchant menerima pesanan';
      case 'dikirim':
        return 'Driver menerima pesanan';
      case 'tiba_merchant':
        return 'Driver di merchant';
      case 'dibeli':
        return 'Pesanan dibeli';
      case 'diantar':
        return 'Pesanan diantar';
      case 'selesai':
        return 'Pesanan selesai';
      case 'batal':
      case 'dibatalkan':
        return 'Pesanan dibatalkan';
      case 'gagal':
        return 'Pesanan gagal';
      default:
        return 'Status: ${_statusKeyText(s)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = _labelFromServerTimelineOrFallback();
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
          fmap.FlutterMap(
            mapController: _leaflet,
            options: fmap.MapOptions(initialCenter: _origin, initialZoom: 12),
            children: [
              fmap.TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.komera_mobile'),
              fmap.MarkerLayer(markers: [
                fmap.Marker(point: _origin, width: 24, height: 24, child: const Icon(Icons.store, color: Colors.green)),
                fmap.Marker(point: _destination, width: 24, height: 24, child: const Icon(Icons.flag, color: Colors.red)),
                fmap.Marker(point: _driverPos, width: 24, height: 24, child: const Icon(Icons.motorcycle, color: Colors.blue)),
              ]),
              fmap.PolylineLayer(polylines: [
                fmap.Polyline(points: _route, color: Colors.blueAccent, strokeWidth: 4),
                if (_driverTrail.length >= 2) fmap.Polyline(points: _driverTrail, color: Colors.blue.withOpacity(0.55), strokeWidth: 6),
              ]),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(statusLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text('Status key: ${_statusKeyText(_status)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
                _leaflet.move(_origin, 13);
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
                          Text(statusLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            _awaitingDriver()
                                ? 'Menunggu driver menerima…'
                                : '$_driverName${_driverPlate.trim().isNotEmpty ? ' • $_driverPlate' : ''} • ETA $_etaMinutes menit',
                          ),
                          const SizedBox(height: 6),
                          if (_timeline.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _timeline.map((e) {
                                final t = DateTime.tryParse('${e['time'] ?? ''}');
                                final timeText = t != null ? DateFormat('HH:mm').format(_toJakartaTime(t)) : '-';
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
