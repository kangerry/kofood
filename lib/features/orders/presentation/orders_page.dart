import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../../../core/network/dio_client.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authStateProvider);
    final isMerchant = state.role == UserRole.merchant;
    if (isMerchant) {
      final sellerOrders = ref.watch(sellerOrdersProvider);
      final fmt = NumberFormat.simpleCurrency(locale: 'id_ID', name: 'Rp', decimalDigits: 0);
      return Scaffold(
        appBar: AppBar(title: const Text('Pesanan Masuk')),
        body: sellerOrders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Gagal memuat pesanan: $e')),
          data: (orders) {
            if (orders.isEmpty) {
              return const Center(child: Text('Belum ada pesanan'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final it = orders[i];
                final total = (it['total'] as num?)?.toDouble() ?? 0;
                final status = (it['status'] as String?) ?? '';
                final isBaru = status == 'baru';
                final dest = Map<String, dynamic>.from(it['dest'] ?? {});
                final alamat = (dest['address'] as String?) ?? '-';
                return ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(it['number']?.toString() ?? 'Pesanan'),
                  subtitle: Text('$status • $alamat', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmt.format(total)),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () { context.go('/kofood/chat/${it['id']}'); },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Chat'),
                      ),
                      if (isBaru) Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              try {
                                final dio = ref.read(dioProvider);
                                await dio.post('/api/v1/seller/orders/${it['id']}/reject');
                                ref.invalidate(sellerOrdersProvider);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan ditolak')));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menolak: $e')));
                              }
                            },
                            child: const Text('Tolak'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () async {
                              try {
                                final dio = ref.read(dioProvider);
                                await dio.post('/api/v1/seller/orders/${it['id']}/process');
                                ref.invalidate(sellerOrdersProvider);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan diterima')));
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memproses: $e')));
                              }
                            },
                            child: const Text('Terima'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    }
    final asyncOrders = ref.watch(myOrdersProvider);
    final fmt = NumberFormat.simpleCurrency(locale: 'id_ID', name: 'Rp', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: asyncOrders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Gagal memuat pesanan: $e')),
        data: (orders) => ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final it = orders[i];
            final total = (it['total'] as num?)?.toDouble() ?? 0;
            return ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(it['number']?.toString() ?? 'Pesanan'),
              subtitle: Text((it['status'] as String?) ?? ''),
              trailing: Text(fmt.format(total)),
            );
          },
        ),
      ),
    );
  }
}
