import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../orders/providers/orders_provider.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders = ref.watch(myOrdersProvider);
    final fmt = NumberFormat.simpleCurrency(locale: 'id_ID', name: 'Rp', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: asyncOrders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Gagal memuat riwayat: $e')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final it = items[i];
            final total = (it['total'] as num?)?.toDouble() ?? 0;
            return Card(
              child: ListTile(
                title: Text(it['number']?.toString() ?? ''),
                subtitle: Text((it['status'] as String?) ?? ''),
                trailing: Text(fmt.format(total)),
              ),
            );
          },
        ),
      ),
    );
  }
}
