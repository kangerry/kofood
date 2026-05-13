import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../../../core/network/dio_client.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../common/widgets/map_picker_page.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});
  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _telepon = TextEditingController();
  final _namaToko = TextEditingController();
  final _alamat = TextEditingController();
  final _deskripsi = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  ll.LatLng? _selectedLatLng;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prof = ref.read(profileProvider).maybeWhen(data: (d) => d, orElse: () => null);
    if (prof != null) {
      final role = '${prof['role']}'.toLowerCase();
      final u = Map<String, dynamic>.from(prof['user'] ?? {});
      if (role == 'anggota') {
        _nama.text = '${u['nama_anggota'] ?? ''}';
      } else {
        _namaToko.text = '${u['nama_toko'] ?? ''}';
      }
      _email.text = '${u['email'] ?? ''}';
      _telepon.text = '${u['telepon'] ?? ''}';
      _alamat.text = '${u['alamat'] ?? ''}';
      _deskripsi.text = '${u['deskripsi'] ?? ''}';
      final lat = u['latitude'];
      final lng = u['longitude'];
        if (lat is num && lng is num) {
          _selectedLatLng = ll.LatLng(lat.toDouble(), lng.toDouble());
        }
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
      final prof = ref.read(profileProvider).maybeWhen(data: (d) => d, orElse: () => null);
      final role = prof != null ? '${prof['role']}'.toLowerCase() : 'anggota';
      final payload = <String, dynamic>{};
      if (_password.text.isNotEmpty) payload['password'] = _password.text;
      payload['email'] = _email.text.trim();
      payload['telepon'] = _telepon.text.trim();
      if (role == 'anggota') {
        payload['nama_anggota'] = _nama.text.trim();
      } else {
        payload['nama_toko'] = _namaToko.text.trim();
        payload['alamat'] = _alamat.text.trim();
        payload['deskripsi'] = _deskripsi.text.trim();
        if (_selectedLatLng != null) {
          payload['latitude'] = _selectedLatLng!.latitude;
          payload['longitude'] = _selectedLatLng!.longitude;
        }
      }
      await dio.put('/api/v1/auth/profile', data: payload);
      if (mounted) Navigator.of(context).pop(true);
      ref.invalidate(profileProvider);
    } catch (e) {
      setState(() => _error = 'Gagal menyimpan profil');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prof = ref.watch(profileProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: prof.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Gagal memuat profil')),
        data: (data) {
          final role = '${data['role']}'.toLowerCase();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Data', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          if (role == 'anggota') ...[
                            TextFormField(
                              controller: _nama,
                              decoration: const InputDecoration(labelText: 'Nama'),
                              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ] else ...[
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
                                        final res = await Navigator.of(context).push<ll.LatLng>(
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
                          ],
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email'),
                            validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'Email tidak valid' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _telepon,
                            decoration: const InputDecoration(labelText: 'Telepon'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Password (opsional)'),
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
          );
        },
      ),
    );
  }
}
