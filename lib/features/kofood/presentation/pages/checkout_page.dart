import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/cart_provider.dart';
import '../../domain/usecases/get_merchants.dart';
import '../../../../core/utils/format.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'map_selector_page.dart';
import 'package:dio/dio.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});
  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  String _payment = 'cod';
  String _vaBank = 'DOKU';
  ll.LatLng? _dest;
  String _destText = '';
  final TextEditingController _noteCtrl = TextEditingController();
  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final repo = ref.read(koFoodRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text(formatRupiah(cart.subtotal))]),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Biaya Pengiriman'), Text(formatRupiah(cart.shipping))]),
                    const Divider(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)), Text(formatRupiah(cart.total), style: const TextStyle(fontWeight: FontWeight.w700))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Alamat Tujuan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(_destText.isNotEmpty ? _destText : 'Belum dipilih'),
                subtitle: _dest != null ? Text('Lat: ${_dest!.latitude.toStringAsFixed(6)}, Lng: ${_dest!.longitude.toStringAsFixed(6)}') : null,
                trailing: TextButton.icon(
                  onPressed: () async {
                    final picked = await Navigator.of(context).push<ll.LatLng>(MaterialPageRoute(builder: (_) => MapSelectorPage(initial: _dest)));
                    if (picked != null && mounted) {
                      setState(() {
                        _dest = picked;
                        _destText = 'Koordinat: ${picked.latitude.toStringAsFixed(6)}, ${picked.longitude.toStringAsFixed(6)}';
                      });
                    }
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Pilih di Peta'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan alamat (opsional)',
                hintText: 'Mis. Rumah pagar hijau, blok B2 no. 5',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            RadioListTile(value: 'cod', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: const Text('COD')),
            RadioListTile(value: 'dompet', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: const Text('Dompet')),
            // Non-SNAP only: hilangkan opsi Checkout (SNAP)
            RadioListTile(value: 'pg_va', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: const Text('Gateway (Virtual Account)')),
            if (_payment == 'pg_va') Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: DropdownButtonFormField<String>(
                value: _vaBank,
                decoration: const InputDecoration(
                  labelText: 'Bank Virtual Account',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'BCA', child: Text('BCA')),
                  DropdownMenuItem(value: 'BRI', child: Text('BRI')),
                  DropdownMenuItem(value: 'MANDIRI', child: Text('Mandiri')),
                  DropdownMenuItem(value: 'BSI', child: Text('BSI')),
                  DropdownMenuItem(value: 'PERMATA', child: Text('Permata')),
                  DropdownMenuItem(value: 'DANAMON', child: Text('Danamon')),
                  DropdownMenuItem(value: 'CIMB', child: Text('CIMB')),
                  DropdownMenuItem(value: 'DOKU', child: Text('DOKU VA (ALTO/ATM Bersama/Prima)')),
                  DropdownMenuItem(value: 'BNI', child: Text('BNI')),
                  DropdownMenuItem(value: 'BNC', child: Text('BNC')),
                  DropdownMenuItem(value: 'BTN', child: Text('BTN')),
                ],
                onChanged: (v) => setState(() => _vaBank = v ?? 'DOKU'),
              ),
            ),
            RadioListTile(value: 'pg_qris', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: const Text('Gateway (QRIS)')),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4))]),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cart.items.isEmpty
                  ? null
                  : () async {
                      if (_dest == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan pilih alamat tujuan di peta terlebih dahulu')));
                        return;
                      }
                      try {
                        final merchantId = cart.items.first.product.merchantId;
                        final sameMerchant = cart.items.every((e) => e.product.merchantId == merchantId);
                        if (!sameMerchant) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua produk harus dari merchant yang sama')));
                          return;
                        }
                        final items = cart.items.map((e) {
                          final byGroup = <String, List<String>>{};
                          for (final o in e.options) {
                            final key = o.groupId;
                            byGroup.putIfAbsent(key, () => <String>[]);
                            byGroup[key]!.add(o.itemId);
                          }
                          final groups = byGroup.entries
                              .map((en) => {
                                    'group_id': int.tryParse(en.key) ?? en.key,
                                    'item_ids': en.value.map((x) => int.tryParse(x) ?? x).toList(),
                                  })
                              .toList();
                          return {
                            'product_id': int.tryParse(e.product.id) ?? e.product.id,
                            'qty': e.quantity,
                            if (e.note.trim().isNotEmpty) 'note': e.note.trim(),
                            if (groups.isNotEmpty) 'options': groups,
                          };
                        }).toList();
                        final res = await repo.createOrder(
                          merchantId: merchantId,
                          items: items,
                          payment: _payment,
                          destAddress: _destText.isNotEmpty ? _destText : 'Koordinat: ${_dest!.latitude.toStringAsFixed(6)}, ${_dest!.longitude.toStringAsFixed(6)}',
                          destLat: _dest!.latitude,
                          destLng: _dest!.longitude,
                          destNote: _noteCtrl.text.trim(),
                          paymentSub: _payment == 'pg_va' ? _vaBank : null,
                        );
                        if (!mounted) return;
                        final id = res['id']?.toString() ?? '0';
                        final payUrl = (res['pay_url'] as String?)?.trim();
                        if ((_payment == 'pg_va' || _payment == 'pg_qris') && payUrl != null && payUrl.isNotEmpty) {
                          final uri = Uri.parse(payUrl);
                          try {
                            await launchUrl(uri, mode: LaunchMode.platformDefault);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengalihkan ke halaman pembayaran')));
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak dapat membuka pembayaran: $payUrl')));
                          }
                        }
                        ref.read(cartProvider.notifier).clear();
                        context.go('/kofood/tracking/$id');
                      } catch (e) {
                        if (!mounted) return;
                        String msg = 'Gagal membuat pesanan';
                        if (e is DioException) {
                          final data = e.response?.data;
                          if (data is Map) {
                            final m = '${data['message'] ?? ''}'.trim();
                            final d = '${data['detail'] ?? ''}'.trim();
                            msg = [m, d].where((s) => s.isNotEmpty).join(' — ');
                          } else {
                            msg = e.message ?? msg;
                          }
                        } else {
                          msg = e.toString();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    },
              child: const Text('Buat Pesanan'),
            ),
          ),
        ),
      ),
    );
  }
}
