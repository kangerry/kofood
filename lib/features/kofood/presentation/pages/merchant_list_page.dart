import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../domain/usecases/get_merchants.dart';

class MerchantListPage extends ConsumerWidget {
  const MerchantListPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchants = ref.watch(getMerchantsProvider);
    final radius = ref.watch(merchantsRadiusKmProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('KoFood'),
        actions: [
          IconButton(onPressed: () => context.go('/search'), icon: const Icon(Icons.search)),
          IconButton(onPressed: () => context.go('/kofood/history'), icon: const Icon(Icons.history)),
        ],
      ),
      body: merchants.when(
        data: (list) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter radius'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final opt in const [2.0, 5.0, 10.0, 20.0, 50.0])
                      ChoiceChip(
                        label: Text('${opt.toStringAsFixed(0)} km'),
                        selected: radius == opt,
                        onSelected: (_) => ref.read(merchantsRadiusKmProvider.notifier).state = opt,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .85, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final m = list[i];
                      return GestureDetector(
                        onTap: () => context.go('/kofood/merchant/${m.id}'),
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: m.bannerUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: m.bannerUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorWidget: (_, __, ___) => const _MerchantPlaceholder(),
                                      )
                                    : const _MerchantPlaceholder(),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                                        const SizedBox(width: 4),
                                        Text(m.rating.toStringAsFixed(1)),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                        const SizedBox(width: 2),
                                        Text('${m.distanceKm.toStringAsFixed(1)} km'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        error: (e, st) => Center(child: Text('Terjadi kesalahan')),
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

class _MerchantPlaceholder extends StatelessWidget {
  const _MerchantPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      width: double.infinity,
      child: const Center(child: Icon(Icons.storefront_outlined, size: 40, color: Colors.black45)),
    );
  }
}
