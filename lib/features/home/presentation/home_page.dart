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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [scheme.primary, scheme.secondary.withOpacity(0.9)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Colors.black87),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Selamat datang', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                              SizedBox(height: 2),
                              Text('Komera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.go('/orders'),
                          icon: const Icon(Icons.notifications_none, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.go('/search'),
                      child: IgnorePointer(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari makanan, merchant, atau pesanan…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: const Icon(Icons.tune),
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionTile(
                                title: 'KoFood',
                                subtitle: 'Pesan makanan',
                                icon: Icons.fastfood_outlined,
                                onTap: () => context.go('/kofood'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionTile(
                                title: 'Ojek',
                                subtitle: 'Antar penumpang',
                                icon: Icons.motorcycle,
                                onTap: () => context.go('/ojek'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _QuickActionTile(
                          title: 'Kirim Barang',
                          subtitle: 'Pickup & antar',
                          icon: Icons.local_shipping_outlined,
                          onTap: () => context.go('/kirim'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 150,
                child: PageView(
                  children: const [
                    _PromoCard(
                      title: 'Best Deal',
                      badge: '35%',
                      subtitle: 'Diskon pilihan hari ini',
                      imageUrl: 'https://picsum.photos/seed/komera_promo_1/800/400',
                    ),
                    _PromoCard(
                      title: 'Gratis Ongkir',
                      badge: '2 km',
                      subtitle: 'Untuk merchant terdekat',
                      imageUrl: 'https://picsum.photos/seed/komera_promo_2/800/400',
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionTitle('Kategori'),
                  TextButton(onPressed: () => context.go('/kofood'), child: const Text('Lihat semua')),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: cats.when(
              loading: () => const SizedBox(height: 86, child: Center(child: CircularProgressIndicator())),
              error: (e, st) => SizedBox(height: 86, child: Center(child: Text('Gagal memuat kategori'))),
              data: (list) => SizedBox(
                height: 96,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final c = list[i];
                    final name = (c['name'] ?? '').toString();
                    return _CategoryCard(
                      title: name.isNotEmpty ? name : 'Kategori',
                      onTap: () => context.go('/kofood'),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionTitle('Merchant Terdekat'),
                  TextButton(onPressed: () => context.go('/kofood'), child: const Text('Lihat semua')),
                ],
              ),
            ),
          ),
          nearby.when(
            loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))),
            error: (e, st) => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Gagal memuat merchant')))),
            data: (list) {
              final limited = list.length > 6 ? list.sublist(0, 6) : list;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final m = limited[i];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(16, i == 0 ? 0 : 10, 16, i == limited.length - 1 ? 18 : 0),
                      child: _MerchantRowCard(
                        name: m.name,
                        bannerUrl: m.bannerUrl,
                        rating: m.rating,
                        distanceKm: m.distanceKm,
                        onTap: () => context.go('/kofood/merchant/${m.id}'),
                      ),
                    );
                  },
                  childCount: limited.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16));
  }
}

class _QuickActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickActionTile({required this.title, required this.subtitle, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final String title;
  final String badge;
  final String subtitle;
  final String imageUrl;
  const _PromoCard({required this.title, required this.badge, required this.subtitle, required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.black.withOpacity(0.55), Colors.transparent],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _CategoryCard({required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 86,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.fastfood_outlined, color: scheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MerchantRowCard extends StatelessWidget {
  final String name;
  final String bannerUrl;
  final double rating;
  final double distanceKm;
  final VoidCallback onTap;
  const _MerchantRowCard({required this.name, required this.bannerUrl, required this.rating, required this.distanceKm, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: bannerUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: bannerUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
                        )
                      : Container(color: Colors.grey.shade200),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(width: 10),
                        Icon(Icons.location_on, size: 14, color: Colors.redAccent.shade100),
                        const SizedBox(width: 2),
                        Text('${distanceKm.toStringAsFixed(1)} km', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w700, fontSize: 12)),
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
    );
  }
}
