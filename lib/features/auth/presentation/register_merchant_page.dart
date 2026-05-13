import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../common/widgets/map_picker_page.dart';

class RegisterMerchantPage extends ConsumerStatefulWidget {
  final bool applyForAnggota;
  const RegisterMerchantPage({super.key, this.applyForAnggota = false});
  @override
  ConsumerState<RegisterMerchantPage> createState() => _RegisterMerchantPageState();
}

class _RegisterMerchantPageState extends ConsumerState<RegisterMerchantPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaToko = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _telepon = TextEditingController();
  final _alamat = TextEditingController();
  final _deskripsi = TextEditingController();
  final _nib = TextEditingController();
  final _pirt = TextEditingController();
  bool _loading = false;
  String? _error;
  ll.LatLng? _selectedLatLng;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLatLng == null) {
      setState(() => _error = 'Silakan pilih lokasi toko di peta');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.applyForAnggota) {
        await ref.read(authStateProvider.notifier).applySeller(
              namaToko: _namaToko.text.trim(),
              deskripsi: _deskripsi.text.trim(),
              alamat: _alamat.text.trim(),
              latitude: _selectedLatLng!.latitude,
              longitude: _selectedLatLng!.longitude,
              nib: _nib.text.trim().isEmpty ? null : _nib.text.trim(),
              pirt: _pirt.text.trim().isEmpty ? null : _pirt.text.trim(),
            );
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pengajuan Diterima'),
            content: const Text('Pengajuan Sedang Dalam Proses Aproval'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) context.go('/profile');
        return;
      } else {
        await ref.read(authStateProvider.notifier).registerMerchant(
              namaToko: _namaToko.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
              telepon: _telepon.text.trim(),
              alamat: _alamat.text.trim(),
              latitude: _selectedLatLng!.latitude,
              longitude: _selectedLatLng!.longitude,
            );
      }
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = widget.applyForAnggota ? 'Gagal mengajukan seller' : 'Gagal mendaftar merchant');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.applyForAnggota ? 'Ajukan Seller' : 'Daftar Merchant')),
      body: ListView(
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
                      Text(widget.applyForAnggota ? 'Pengajuan Seller' : 'Form Merchant', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _namaToko,
                        decoration: const InputDecoration(labelText: 'Nama Toko'),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      if (!widget.applyForAnggota) ...[
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'Email tidak valid' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password'),
                          validator: (v) => v == null || v.length < 6 ? 'Minimal 6 karakter' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _telepon,
                          decoration: const InputDecoration(labelText: 'Telepon'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _alamat,
                        decoration: const InputDecoration(labelText: 'Alamat'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _deskripsi,
                        decoration: const InputDecoration(labelText: 'Deskripsi Toko'),
                        maxLines: 3,
                        validator: (v) => widget.applyForAnggota && (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _nib, decoration: const InputDecoration(labelText: 'No. NIB (Opsional)'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _pirt, decoration: const InputDecoration(labelText: 'No. PIRT (Opsional)'))),
                        ],
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
                      const SizedBox(height: 16),
                      if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                      FilledButton(
                        onPressed: _loading ? null : _register,
                        child: _loading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(widget.applyForAnggota ? 'Ajukan Seller' : 'Daftar Merchant'),
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
