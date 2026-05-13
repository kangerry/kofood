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
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.go('/search'),
                    child: IgnorePointer(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari merchant atau menu…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: const Icon(Icons.tune),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Radius', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: const [2.0, 5.0, 10.0, 20.0, 50.0].length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (ctx, i) {
                            final opt = const [2.0, 5.0, 10.0, 20.0, 50.0][i];
                            return ChoiceChip(
                              label: Text('${opt.toStringAsFixed(0)} km'),
                              selected: radius == opt,
                              onSelected: (_) => ref.read(merchantsRadiusKmProvider.notifier).state = opt,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final m = list[i];
                      return Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                        child: Card(
                          child: InkWell(
                            onTap: () => context.go('/kofood/merchant/${m.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: SizedBox(
                                      width: 78,
                                      height: 78,
                                      child: m.bannerUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: m.bannerUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorWidget: (_, __, ___) => const _MerchantPlaceholder(),
                                            )
                                          : const _MerchantPlaceholder(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                                            const SizedBox(width: 4),
                                            Text(m.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                            const SizedBox(width: 10),
                                            Icon(Icons.location_on, size: 14, color: Colors.redAccent.shade100),
                                            const SizedBox(width: 2),
                                            Text('${m.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.chevron_right, color: Colors.grey.shade500),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: list.length,
                  ),
                ),
              ),
            ],
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
