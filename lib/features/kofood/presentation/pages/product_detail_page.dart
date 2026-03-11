import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_product_by_id.dart';
import '../controllers/cart_provider.dart';
import '../../../../core/utils/format.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});
  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _current = 0;
  @override
  Widget build(BuildContext context) {
    final product = ref.watch(getProductByIdProvider(widget.productId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: product.when(
        data: (p) {
          return Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: PageView.builder(
                  itemCount: p.images.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (ctx, i) => CachedNetworkImage(
                    imageUrl: p.images[i],
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.fastfood_outlined)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  p.images.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _current ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(p.description),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        error: (e, st) => Center(child: Text('Gagal memuat produk')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: product.when(
        data: (p) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4))]),
              child: Row(
                children: [
                  Expanded(child: Text(formatRupiah(p.price), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(cartProvider.notifier).add(p);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ditambahkan ke keranjang')),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
            ),
          );
        },
        error: (e, st) => const SizedBox.shrink(),
        loading: () => const SizedBox.shrink(),
      ),
    );
  }
}
