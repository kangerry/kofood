import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/orders_provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(fmt.format(total)),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Chat',
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () { ctx.go('/kofood/chat/${it['id']}'); },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
