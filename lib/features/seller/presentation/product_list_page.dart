import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';

final sellerProductsProvider = FutureProvider<List<_SellerProduct>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/api/v1/seller/products');
  final List data = res.data?['data'] as List? ?? const [];
  return data.map((e) => _SellerProduct.fromJson(Map<String, dynamic>.from(e as Map))).toList();
});

class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sellerProductsProvider);
    return async.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('Belum ada produk'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            await ref.refresh(sellerProductsProvider.future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (ctx, i) {
              final p = items[i];
              return ListTile(
                leading: p.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(p.imageUrl!, width: 36, height: 36, fit: BoxFit.cover),
                      )
                    : const CircleAvatar(child: Icon(Icons.fastfood_outlined)),
                title: Text(p.name),
                subtitle: Text('Rp ${p.price.toStringAsFixed(0)}'),
                trailing: Switch(
                  value: p.available,
                  onChanged: (v) async {
                    final dio = ref.read(dioProvider);
                    await dio.put('/api/v1/seller/products/${p.id}', data: {'status_tersedia': v});
                    await ref.refresh(sellerProductsProvider.future);
                  },
                ),
                onTap: () => context.push('/seller/product/${p.id}/edit'),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: items.length,
          ),
        );
      },
      error: (e, st) => Center(child: Text('Gagal memuat produk')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _SellerProduct {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final bool available;
  final int? kategoriId;
  _SellerProduct({required this.id, required this.name, required this.price, this.imageUrl, required this.available, this.kategoriId});
  factory _SellerProduct.fromJson(Map<String, dynamic> j) {
    return _SellerProduct(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      price: j['price'] is num ? (j['price'] as num).toDouble() : 0.0,
      imageUrl: (j['imageUrl'] ?? '') == '' ? null : (j['imageUrl'] as String),
      available: j['available'] == true,
      kategoriId: j['kategori_id'] is int ? j['kategori_id'] as int : (j['kategori_id'] is num ? (j['kategori_id'] as num).toInt() : null),
    );
  }
}
