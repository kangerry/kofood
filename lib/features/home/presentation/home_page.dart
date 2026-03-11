import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../kofood/domain/usecases/get_merchants.dart';

final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final resp = await dio.get('/api/v1/kofood/categories');
  final list = (resp.data['data'] as List).cast<Map<String, dynamic>>();
  return list;
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    final nearby = ref.watch(getMerchantsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Komera')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 160,
            child: PageView(
              children: const [
                _BannerCard(url: 'https://picsum.photos/seed/1/800/320'),
                _BannerCard(url: 'https://picsum.photos/seed/2/800/320'),
                _BannerCard(url: 'https://picsum.photos/seed/3/800/320'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          cats.when(
            loading: () => const SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SizedBox(height: 90, child: Center(child: Text('Gagal memuat kategori: $e'))),
            data: (list) => SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final c = list[i];
                  return CircleAvatar(
                    radius: 36,
                    child: Text(
                      (c['name'] as String).isNotEmpty ? (c['name'] as String)[0] : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: list.length,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nearby Merchant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              TextButton(onPressed: () => context.go('/kofood'), child: const Text('Lihat semua')),
            ],
          ),
          nearby.when(
            loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SizedBox(height: 120, child: Center(child: Text('Gagal memuat merchant: $e'))),
            data: (list) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .85, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: list.length > 4 ? 4 : list.length,
              itemBuilder: (ctx, i) {
                final m = list[i];
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: m.bannerUrl.isNotEmpty
                            ? CachedNetworkImage(imageUrl: m.bannerUrl, fit: BoxFit.cover, width: double.infinity)
                            : Container(color: Colors.grey.shade300),
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
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: () => context.go('/kofood'), icon: const Icon(Icons.fastfood_outlined), label: const Text('KoFood')),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String url;
  const _BannerCard({required this.url});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, width: double.infinity),
    );
  }
}
