import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../domain/usecases/get_merchant_detail.dart';
import '../../domain/usecases/get_products_by_merchant.dart';
import '../../domain/entities/product.dart';
import '../controllers/cart_provider.dart';
import '../../../../core/utils/format.dart';

class MerchantDetailPage extends ConsumerWidget {
  final String merchantId;
  const MerchantDetailPage({super.key, required this.merchantId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(getMerchantDetailProvider(merchantId));
    final products = ref.watch(getProductsByMerchantProvider(merchantId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Toko')),
      body: detail.when(
        data: (m) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: (m.bannerUrl.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: m.bannerUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorWidget: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Center(child: Icon(Icons.storefront_outlined))),
                            )
                          : Container(color: Colors.grey.shade300, child: const Center(child: Icon(Icons.storefront_outlined))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(m.address, style: TextStyle(color: Colors.grey.shade700)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ChoiceChip(label: const Text('Delivery'), selected: true),
                              const SizedBox(width: 8),
                              ChoiceChip(label: const Text('Pickup'), selected: false),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Menu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              products.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Belum ada menu untuk toko ini')),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      final p = list[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          child: InkWell(
                            onTap: () => context.go('/kofood/product/${p.id}'),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 110,
                                  height: 90,
                                  child: CachedNetworkImage(
                                    imageUrl: p.images.isNotEmpty ? p.images.first : '',
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: Colors.grey.shade300,
                                      child: const Center(child: Icon(Icons.fastfood_outlined)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        Text(formatRupiah(p.price)),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_shopping_cart_outlined),
                                  onPressed: () {
                                    ref.read(cartProvider.notifier).add(p);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Ditambahkan ke keranjang')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: list.length),
                  );
                },
                error: (e, st) => SliverToBoxAdapter(child: Center(child: Text('Gagal memuat menu'))),
                loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))),
              ),
            ],
          );
        },
        error: (e, st) => Center(child: Text('Gagal memuat detail')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/kofood/cart'),
        label: const Text('Keranjang'),
        icon: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
