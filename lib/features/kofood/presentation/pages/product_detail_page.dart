import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/get_product_by_id.dart';
import '../../domain/entities/product.dart';
import '../controllers/cart_provider.dart';
import '../../../../core/utils/format.dart';
import '../../domain/entities/cart_item.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});
  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _current = 0;
  final Map<String, Set<String>> _selectedByGroup = {};
  final TextEditingController _noteCtrl = TextEditingController();
  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  int _selectedOptionsPrice(Product p) {
    int sum = 0;
    for (final g in p.optionGroups) {
      final sel = _selectedByGroup[g.id] ?? <String>{};
      for (final itemId in sel) {
        final it = g.items.firstWhere(
          (x) => x.id == itemId,
          orElse: () => const ProductOptionItem(id: '', name: '', price: 0),
        );
        sum += it.price;
      }
    }
    return sum;
  }

  List<CartSelectedOption> _buildSelectedOptions(Product p) {
    final out = <CartSelectedOption>[];
    for (final g in p.optionGroups) {
      final sel = _selectedByGroup[g.id] ?? <String>{};
      for (final itemId in sel) {
        final it = g.items.firstWhere(
          (x) => x.id == itemId,
          orElse: () => const ProductOptionItem(id: '', name: '', price: 0),
        );
        if (it.id.isEmpty) continue;
        out.add(
          CartSelectedOption(
            groupId: g.id,
            groupName: g.name,
            itemId: it.id,
            itemName: it.name,
            price: it.price,
          ),
        );
      }
    }
    out.sort((a, b) {
      final g = a.groupId.compareTo(b.groupId);
      if (g != 0) return g;
      return a.itemId.compareTo(b.itemId);
    });
    return out;
  }

  String? _validateSelections(Product p) {
    for (final g in p.optionGroups) {
      final sel = _selectedByGroup[g.id] ?? <String>{};
      final count = sel.length;
      if (g.isSingle) {
        if (g.required && count != 1) {
          return 'Pilih ${g.name}';
        }
        if (!g.required && count > 1) {
          return 'Pilihan ${g.name} tidak valid';
        }
      } else {
        final min = g.min ?? (g.required ? 1 : 0);
        final max = g.max;
        if (count < min) {
          return 'Minimal pilih $min untuk ${g.name}';
        }
        if (max != null && count > max) {
          return 'Maksimal pilih $max untuk ${g.name}';
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(getProductByIdProvider(widget.productId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: product.when(
        data: (p) {
          return ListView(
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
              if (p.images.length > 1) ...[
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
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (p.description.trim().isNotEmpty) Text(p.description),
                    if (p.optionGroups.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Opsi Tambahan', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      for (final g in p.optionGroups) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                                    if (g.required) const Text('Wajib', style: TextStyle(fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (g.isSingle) ...[
                                  if (!g.required)
                                    RadioListTile<String>(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      value: '',
                                      groupValue: (_selectedByGroup[g.id]?.isNotEmpty ?? false) ? _selectedByGroup[g.id]!.first : '',
                                      onChanged: (_) => setState(() => _selectedByGroup[g.id] = <String>{}),
                                      title: const Text('Tanpa opsi'),
                                    ),
                                  for (final it in g.items)
                                    RadioListTile<String>(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      value: it.id,
                                      groupValue: (_selectedByGroup[g.id]?.isNotEmpty ?? false) ? _selectedByGroup[g.id]!.first : '',
                                      onChanged: (v) => setState(() => _selectedByGroup[g.id] = {v ?? ''}..remove('')),
                                      title: Text(it.price > 0 ? '${it.name} (+${formatRupiah(it.price)})' : it.name),
                                    ),
                                ] else ...[
                                  for (final it in g.items)
                                    CheckboxListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      value: _selectedByGroup[g.id]?.contains(it.id) ?? false,
                                      onChanged: (v) {
                                        final current = _selectedByGroup[g.id] ?? <String>{};
                                        final next = {...current};
                                        if (v == true) {
                                          final max = g.max;
                                          if (max != null && next.length >= max) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Maksimal pilih $max untuk ${g.name}')));
                                            return;
                                          }
                                          next.add(it.id);
                                        } else {
                                          next.remove(it.id);
                                        }
                                        setState(() => _selectedByGroup[g.id] = next);
                                      },
                                      title: Text(it.price > 0 ? '${it.name} (+${formatRupiah(it.price)})' : it.name),
                                    ),
                                  if (g.min != null || g.max != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        [
                                          if (g.min != null) 'Min ${g.min}',
                                          if (g.max != null) 'Max ${g.max}',
                                        ].join(' • '),
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextField(
                        controller: _noteCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Catatan untuk item (opsional)',
                          hintText: 'Mis. jangan pakai bawang, extra es…',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 70),
                  ],
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
          final optionsPrice = _selectedOptionsPrice(p);
          final totalPrice = p.price + optionsPrice;
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4))]),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatRupiah(totalPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        if (optionsPrice > 0) Text('Termasuk opsi +${formatRupiah(optionsPrice)}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final err = _validateSelections(p);
                      if (err != null && err.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                        return;
                      }
                      final opts = _buildSelectedOptions(p);
                      ref.read(cartProvider.notifier).add(p, options: opts, note: _noteCtrl.text.trim());
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
