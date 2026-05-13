import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/dio_client.dart';
import '../../kofood/presentation/pages/map_selector_page.dart';
import '../../../core/utils/format.dart';

class OjekRequestPage extends ConsumerStatefulWidget {
  final String service;
  const OjekRequestPage({super.key, this.service = 'ride'});
  @override
  ConsumerState<OjekRequestPage> createState() => _OjekRequestPageState();
}

class _OjekRequestPageState extends ConsumerState<OjekRequestPage> {
  ll.LatLng? _pickup;
  ll.LatLng? _dest;
  String _alamatPickup = '';
  String _alamatDest = '';
  String _payment = 'cod';
  double? _estimate;
  bool _loading = false;

  Future<void> _pickLocation(bool isPickup) async {
    final pos = await Navigator.of(context).push<ll.LatLng>(MaterialPageRoute(builder: (_) => MapSelectorPage(initial: isPickup ? _pickup : _dest)));
    if (pos != null) {
      setState(() {
        if (isPickup) {
          _pickup = pos;
        } else {
          _dest = pos;
        }
      });
      await _refreshEstimate();
    }
  }

  Future<void> _refreshEstimate() async {
    if (_pickup == null || _dest == null) return;
    final dio = ref.read(dioProvider);
    try {
      final res = await dio.get('/api/v1/kojek/ride/fare', queryParameters: {
        'origin_lat': _pickup!.latitude,
        'origin_lng': _pickup!.longitude,
        'dest_lat': _dest!.latitude,
        'dest_lng': _dest!.longitude,
      });
      setState(() => _estimate = (res.data['fare'] as num?)?.toDouble());
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = e.response?.data is Map ? (e.response?.data['message']?.toString() ?? '') : '';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal ambil estimasi${code != null ? ' ($code)' : ''}${msg.isNotEmpty ? ': $msg' : ''}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal ambil estimasi: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (_pickup == null || _dest == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih lokasi jemput dan tujuan')));
      return;
    }
    setState(() => _loading = true);
    final dio = ref.read(dioProvider);
    try {
      final res = await dio.post('/api/v1/kojek/ride/orders', data: {
        'alamat_jemput': _alamatPickup,
        'origin_lat': _pickup!.latitude,
        'origin_lng': _pickup!.longitude,
        'alamat_tujuan': _alamatDest,
        'dest_lat': _dest!.latitude,
        'dest_lng': _dest!.longitude,
        'payment': _payment,
        'service': widget.service,
      });
      final id = res.data['id']?.toString() ?? '';
      final payUrl = (res.data is Map ? (res.data['pay_url']?.toString() ?? '') : '').trim();
      if ((_payment == 'pg_va' || _payment == 'pg_qris') && payUrl.isNotEmpty) {
        try {
          await launchUrl(Uri.parse(payUrl), mode: LaunchMode.platformDefault);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengalihkan ke halaman pembayaran')));
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak dapat membuka pembayaran: $payUrl')));
          }
        }
      }
      if (id.isNotEmpty) {
        context.go('/ojek/tracking/$id');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order gagal dibuat')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canSubmit = !_loading && _pickup != null && _dest != null;
    final title = widget.service == 'delivery' ? 'Kirim Barang' : 'Ojek Penumpang';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.motorcycle, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service == 'delivery' ? 'Mau kirim dari mana?' : 'Mau dijemput dari mana?',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.service == 'delivery'
                              ? 'Pilih lokasi pickup dan tujuan, lalu konfirmasi.'
                              : 'Pilih jemput dan tujuan, lalu konfirmasi.',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(_alamatPickup.trim().isNotEmpty ? _alamatPickup : 'Lokasi jemput'),
                  subtitle: Text(_pickup != null ? 'Titik dipilih' : 'Pilih titik jemput di peta'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickLocation(true),
                ),
                Divider(height: 1, color: Colors.black.withOpacity(0.06)),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: Text(_alamatDest.trim().isNotEmpty ? _alamatDest : 'Lokasi tujuan'),
                  subtitle: Text(_dest != null ? 'Titik dipilih' : 'Pilih titik tujuan di peta'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickLocation(false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alamat (opsional)', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Detail alamat jemput (patokan)',
                      prefixIcon: Icon(Icons.edit_location_alt_outlined),
                    ),
                    onChanged: (v) => _alamatPickup = v,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Detail alamat tujuan',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    onChanged: (v) => _alamatDest = v,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('COD'),
                        selected: _payment == 'cod',
                        onSelected: (_) => setState(() => _payment = 'cod'),
                      ),
                      ChoiceChip(
                        label: const Text('Dompet'),
                        selected: _payment == 'dompet',
                        onSelected: (_) => setState(() => _payment = 'dompet'),
                      ),
                      ChoiceChip(
                        label: const Text('VA'),
                        selected: _payment == 'pg_va',
                        onSelected: (_) => setState(() => _payment = 'pg_va'),
                      ),
                      ChoiceChip(
                        label: const Text('QRIS'),
                        selected: _payment == 'pg_qris',
                        onSelected: (_) => setState(() => _payment = 'pg_qris'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimasi biaya', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          _estimate != null ? formatRupiah(_estimate!.toInt()) : '-',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _refreshEstimate,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canSubmit ? _submit : null,
              child: Text(_loading ? 'Memproses…' : 'Pesan Ojek'),
            ),
          ),
        ),
      ),
    );
  }
}
