import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'web_js_stub.dart'
    if (dart.library.html) 'web_js_web.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initial;
  const MapPickerPage({super.key, this.initial});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? _selected;
  GoogleMapController? _controller;
  bool _gmapsReady = !kIsWeb;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    if (kIsWeb) {
      _startPollingForGoogle();
    }
  }

  void _startPollingForGoogle() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (hasGoogleMaps()) {
        t.cancel();
        if (mounted) {
          setState(() {
            _gmapsReady = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCamera = widget.initial ?? const LatLng(-6.175392, 106.827153); // Monas, Jakarta
    final markers = <Marker>{
      if (_selected != null)
        Marker(markerId: const MarkerId('selected'), position: _selected!, draggable: false),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi di Peta')),
      body: Column(
        children: [
          Expanded(
            child: !_gmapsReady
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(target: initialCamera, zoom: 14),
                    onTap: (pos) => setState(() => _selected = pos),
                    markers: markers,
                    onMapCreated: (c) => _controller = c,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: false,
                    zoomControlsEnabled: true,
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selected != null
                          ? 'Lat: ${_selected!.latitude.toStringAsFixed(6)}, Lng: ${_selected!.longitude.toStringAsFixed(6)}'
                          : 'Tap peta untuk memilih lokasi',
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selected == null
                        ? null
                        : () {
                            Navigator.of(context).pop<LatLng>(_selected);
                          },
                    child: const Text('Gunakan Lokasi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
