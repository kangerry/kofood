import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'image_picker_stub.dart'
    if (dart.library.html) 'image_picker_web.dart'
    if (dart.library.io) 'image_picker_io.dart';

class ProductEditPage extends ConsumerStatefulWidget {
  final String productId;
  const ProductEditPage({super.key, required this.productId});
  @override
  ConsumerState<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends ConsumerState<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();
  bool _saving = false;
  List<_Category> _categories = const [];
  int? _selectedCategoryId;
  List<_Photo> _photos = const [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await Future.wait([_loadCategories(), _loadProduct(), _loadPhotos()]);
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
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = const [];
      });
    }
  }

  Future<void> _loadProduct() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/kofood/products/${widget.productId}');
      final data = Map<String, dynamic>.from(res.data?['data'] as Map? ?? {});
      if (!mounted) return;
      setState(() {
        _name.text = (data['name'] ?? '').toString();
        _desc.text = (data['description'] ?? '').toString();
        final price = data['price'] is num ? (data['price'] as num).toDouble() : 0.0;
        _price.text = price.toStringAsFixed(0);
      });
    } catch (_) {}
  }

  Future<void> _loadPhotos() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/seller/products/${widget.productId}/photos');
      final List items = res.data?['data'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _photos = items.map((e) => _Photo.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photos = const [];
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final remain = 5 - _photos.length;
    if (remain <= 0) return;
    final picked = await pickImages(remain);
    if (picked.isEmpty) return;
    final dio = ref.read(dioProvider);
    for (final p in picked) {
      try {
        final form = FormData.fromMap({'file': MultipartFile.fromBytes(p.bytes, filename: p.name)});
        await dio.post('/api/v1/seller/products/${widget.productId}/photos', data: form);
      } catch (_) {}
    }
    if (!mounted) return;
    await _loadPhotos();
  }

  Future<void> _deletePhoto(int id) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.delete('/api/v1/seller/products/${widget.productId}/photos/$id');
      if (!mounted) return;
      await _loadPhotos();
    } catch (_) {}
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final Map<String, dynamic> payload = {
        'nama_produk': _name.text.trim(),
        'deskripsi': _desc.text.trim(),
        'harga': _price.text.trim(),
      };
      if (_selectedCategoryId != null) {
        payload['kategori_id'] = _selectedCategoryId;
      }
      await dio.put('/api/v1/seller/products/${widget.productId}', data: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk diperbarui')));
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['message']?.toString() ?? 'Gagal menyimpan';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Produk')),
      body: Padding(
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
                decoration: const InputDecoration(labelText: 'Kategori (opsional)'),
                items: _categories
                    .map((c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: _saving ? null : (v) => setState(() => _selectedCategoryId = v),
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
              Text('Foto Produk', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._photos.map((ph) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(ph.url, width: 96, height: 96, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _saving ? null : () => _deletePhoto(ph.id),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
                  if (_photos.length < 5)
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickAndUpload,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Foto'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : () => _save(context),
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Category {
  final int id;
  final String name;
  const _Category({required this.id, required this.name});
}

class _Photo {
  final int id;
  final String url;
  final int order;
  const _Photo({required this.id, required this.url, required this.order});
  factory _Photo.fromJson(Map<String, dynamic> j) {
    return _Photo(
      id: (j['id'] as num).toInt(),
      url: (j['url'] ?? '').toString(),
      order: j['urutan'] is int ? j['urutan'] as int : (j['urutan'] is num ? (j['urutan'] as num).toInt() : 0),
    );
  }
}
