import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/cart_provider.dart';
import '../../../../core/utils/format.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cart.items.length,
        itemBuilder: (ctx, i) {
          final it = cart.items[i];
          final optsText = it.options.isEmpty
              ? null
              : it.options
                  .map((e) => e.groupName.isNotEmpty ? '${e.groupName}: ${e.itemName}' : e.itemName)
                  .where((s) => s.trim().isNotEmpty)
                  .join(', ');
          return Card(
            child: ListTile(
              title: Text(it.product.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${formatRupiah(it.unitPrice)} x ${it.quantity}'),
                  if (optsText != null && optsText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(optsText, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                  ],
                  if (it.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Catatan: ${it.note}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: () => ref.read(cartProvider.notifier).decrease(it.lineId), icon: const Icon(Icons.remove)),
                  IconButton(onPressed: () => ref.read(cartProvider.notifier).increase(it.lineId), icon: const Icon(Icons.add)),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal'),
                  Text(formatRupiah(cart.subtotal)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Biaya Pengiriman'),
                  Text(formatRupiah(cart.shipping)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(formatRupiah(cart.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cart.items.isEmpty ? null : () => context.go('/kofood/checkout'),
                  child: const Text('Checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
