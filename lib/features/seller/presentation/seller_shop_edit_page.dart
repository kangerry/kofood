import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/network/dio_client.dart';
import '../../common/widgets/map_picker_page.dart';

class SellerShopEditPage extends ConsumerStatefulWidget {
  const SellerShopEditPage({super.key});
  @override
  ConsumerState<SellerShopEditPage> createState() => _SellerShopEditPageState();
}

class _SellerShopEditPageState extends ConsumerState<SellerShopEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaToko = TextEditingController();
  final _deskripsi = TextEditingController();
  final _alamat = TextEditingController();
  final _telepon = TextEditingController();
  bool _loading = false;
  String? _error;
  LatLng? _selectedLatLng;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/auth/seller-profile');
      final data = Map<String, dynamic>.from(res.data?['data'] as Map? ?? {});
      if (!mounted) return;
      setState(() {
        _namaToko.text = (data['nama_toko'] ?? '').toString();
        _deskripsi.text = (data['deskripsi'] ?? '').toString();
        _alamat.text = (data['alamat'] ?? '').toString();
        _telepon.text = (data['telepon'] ?? '').toString();
        final lat = data['latitude'];
        final lng = data['longitude'];
        if (lat is num && lng is num) {
          _selectedLatLng = LatLng(lat.toDouble(), lng.toDouble());
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat data toko');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/api/v1/auth/seller-profile', data: {
        'nama_toko': _namaToko.text.trim(),
        'deskripsi': _deskripsi.text.trim(),
        'alamat': _alamat.text.trim(),
        'telepon': _telepon.text.trim(),
        if (_selectedLatLng != null) 'latitude': _selectedLatLng!.latitude,
        if (_selectedLatLng != null) 'longitude': _selectedLatLng!.longitude,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toko berhasil disimpan')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal menyimpan toko');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Toko')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Data Toko', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _namaToko,
                        decoration: const InputDecoration(labelText: 'Nama Toko'),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _deskripsi,
                        decoration: const InputDecoration(labelText: 'Deskripsi'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _alamat,
                        decoration: const InputDecoration(labelText: 'Alamat'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telepon,
                        decoration: const InputDecoration(labelText: 'Telepon'),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.place_outlined),
                        title: const Text('Lokasi Toko'),
                        subtitle: Text(_selectedLatLng != null
                            ? 'Lat: ${_selectedLatLng!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLatLng!.longitude.toStringAsFixed(6)}'
                            : 'Belum dipilih'),
                        trailing: OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  final res = await Navigator.of(context).push<LatLng>(
                                    MaterialPageRoute(
                                      builder: (_) => MapPickerPage(initial: _selectedLatLng),
                                    ),
                                  );
                                  if (res != null) {
                                    setState(() => _selectedLatLng = res);
                                  }
                                },
                          child: const Text('Pilih di Peta'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                      FilledButton(
                        onPressed: _loading ? null : _save,
                        child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

