import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'dart:async';
import 'image_picker_stub.dart'
    if (dart.library.html) 'image_picker_web.dart'
    if (dart.library.io) 'image_picker_io.dart';
import '../../../core/network/dio_client.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key});
  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();
  final List<_LocalImage> _images = [];
  bool _saving = false;
  List<_Category> _categories = const [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCategories());
  }

  Future<void> _loadCategories() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/kofood/categories');
      final List list = res.data?['data'] as List? ?? const [];
      final cats = list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return _Category(id: (m['id'] as num).toInt(), name: (m['name'] ?? '').toString());
      }).where((c) => c.name.isNotEmpty).toList();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = const [];
        _selectedCategoryId = null;
      });
    }
  }

  Future<void> _pickImage() async {
    if (_images.length >= 5) return;
    final remain = 5 - _images.length;
    final picked = await pickImages(remain);
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked.map((e) => _LocalImage(name: e.name, bytes: e.bytes)));
    });
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/api/v1/seller/products', data: {
        'nama_produk': _name.text.trim(),
        'deskripsi': _desc.text.trim(),
        'harga': _price.text.trim(),
        'kategori_id': _selectedCategoryId,
      });
      final id = (res.data?['id'] ?? '').toString();
      int failed = 0;
      for (final img in _images) {
        try {
          final form = FormData.fromMap({
            'file': MultipartFile.fromBytes(img.bytes, filename: img.name),
          });
          await dio.post('/api/v1/seller/products/$id/photos', data: form);
        } catch (_) {
          failed++;
        }
      }
      if (!mounted) return;
      if (failed > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk disimpan, $failed foto gagal diunggah')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk disimpan')));
      }
      setState(() {
        _name.clear();
        _price.clear();
        _desc.clear();
        _images.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan produk')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nama produk'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: _categories
                    .map((c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: _saving ? null : (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.map((e) => SizedBox(
                        width: 72,
                        height: 72,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(e.bytes, fit: BoxFit.cover),
                        ),
                      )),
                  if (_images.length < 5)
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickImage,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : () => _save(context, ref),
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _LocalImage {
  final String name;
  final Uint8List bytes;
  _LocalImage({required this.name, required this.bytes});
}

class _Category {
  final int id;
  final String name;
  const _Category({required this.id, required this.name});
}
