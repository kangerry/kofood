import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/cart_provider.dart';
import '../../domain/usecases/get_merchants.dart';
import '../../../../core/utils/format.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_selector_page.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});
  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  String _payment = 'cod';
  LatLng? _dest;
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
                    final picked = await Navigator.of(context).push<LatLng>(MaterialPageRoute(builder: (_) => MapSelectorPage(initial: _dest)));
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
            RadioListTile(value: 'pg_checkout', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: const Text('Gateway (DOKU Checkout)')),
            RadioListTile(value: 'pg_va', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: const Text('Gateway (Virtual Account)')),
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
                        final items = cart.items
                            .map((e) => {
                                  'product_id': int.tryParse(e.product.id) ?? e.product.id,
                                  'qty': e.quantity,
                                })
                            .toList();
                        final res = await repo.createOrder(
                          merchantId: merchantId,
                          items: items,
                          payment: _payment,
                          destAddress: _destText.isNotEmpty ? _destText : 'Koordinat: ${_dest!.latitude.toStringAsFixed(6)}, ${_dest!.longitude.toStringAsFixed(6)}',
                          destLat: _dest!.latitude,
                          destLng: _dest!.longitude,
                          destNote: _noteCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        final id = res['id']?.toString() ?? '0';
                        final payUrl = (res['pay_url'] as String?)?.trim();
                        if ((_payment == 'pg_checkout' || _payment == 'pg_va' || _payment == 'pg_qris') && payUrl != null && payUrl.isNotEmpty) {
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
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
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
