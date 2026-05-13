import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'dart:async';

class MapPickerPage extends StatefulWidget {
  final ll.LatLng? initial;
  const MapPickerPage({super.key, this.initial});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  ll.LatLng? _selected;
  final fmap.MapController _leaflet = fmap.MapController();
  String _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ll.LatLng initialCenter = widget.initial ?? const ll.LatLng(-6.175392, 106.827153);
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi di Peta')),
      body: Column(
        children: [
          Expanded(
            child: fmap.FlutterMap(
              mapController: _leaflet,
              options: fmap.MapOptions(
                initialCenter: initialCenter,
                initialZoom: 14,
                onTap: (tapPos, latLng) => setState(() => _selected = latLng),
              ),
              children: [
                fmap.TileLayer(urlTemplate: _tileUrl, userAgentPackageName: 'com.example.komera_mobile'),
                fmap.MarkerLayer(markers: [
                  if (_selected != null)
                    fmap.Marker(point: _selected!, width: 30, height: 30, child: const Icon(Icons.place, color: Colors.redAccent)),
                ]),
              ],
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
                            Navigator.of(context).pop<ll.LatLng>(_selected);
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
