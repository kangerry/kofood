import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final sellerOptionGroupsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/api/v1/seller/option-groups');
  final List list = res.data?['data'] as List? ?? const [];
  return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

class OptionGroupsPage extends ConsumerWidget {
  const OptionGroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sellerOptionGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Opsi Produk')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Gagal memuat: $e')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text('Belum ada opsi'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(sellerOptionGroupsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (ctx, i) {
                final g = groups[i];
                final items = (g['items'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? const <Map<String, dynamic>>[];
                final name = (g['name'] ?? '').toString();
                final type = (g['type'] ?? 'single').toString();
                final required = g['required'] == true;
                final min = g['min'] is int ? g['min'] as int : (g['min'] is num ? (g['min'] as num).toInt() : null);
                final max = g['max'] is int ? g['max'] as int : (g['max'] is num ? (g['max'] as num).toInt() : null);
                final gid = (g['id'] as num?)?.toInt() ?? int.tryParse((g['id'] ?? '').toString()) ?? 0;
                return Card(
                  child: ExpansionTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(_subtitle(type: type, required: required, min: min, max: max)),
                    children: [
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text('Belum ada item opsi'),
                        )
                      else
                        for (final it in items)
                          ListTile(
                            title: Text((it['name'] ?? '').toString()),
                            subtitle: Text(_money((it['price'] ?? 0).toString())),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  await _showItemDialog(context, ref, groupId: gid, item: it);
                                }
                                if (v == 'delete') {
                                  await _deleteItem(context, ref, (it['id'] as num?)?.toInt() ?? int.tryParse((it['id'] ?? '').toString()) ?? 0);
                                }
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Hapus')),
                              ],
                            ),
                          ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                        child: Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showGroupDialog(context, ref, group: g),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit Group'),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () => _showItemDialog(context, ref, groupId: gid),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Item'),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Hapus group',
                              onPressed: () => _deleteGroup(context, ref, gid),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGroupDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Group'),
      ),
    );
  }

  static String _subtitle({required String type, required bool required, int? min, int? max}) {
    final t = type == 'multi' ? 'Multi' : 'Single';
    final req = required ? 'Wajib' : 'Opsional';
    final mm = [
      if (type == 'multi' && min != null) 'Min $min',
      if (type == 'multi' && max != null) 'Max $max',
    ].join(' • ');
    return [t, req, mm].where((s) => s.isNotEmpty).join(' • ');
  }

  static String _money(String raw) {
    final v = double.tryParse(raw) ?? 0;
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  static Future<void> _deleteGroup(BuildContext context, WidgetRef ref, int groupId) async {
    if (groupId <= 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus group?'),
        content: const Text('Item dan relasi produk akan ikut dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/api/v1/seller/option-groups/$groupId');
      ref.invalidate(sellerOptionGroupsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group dihapus')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  static Future<void> _deleteItem(BuildContext context, WidgetRef ref, int itemId) async {
    if (itemId <= 0) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/api/v1/seller/option-items/$itemId');
      ref.invalidate(sellerOptionGroupsProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item dihapus')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  static Future<void> _showGroupDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? group}) async {
    final nameCtrl = TextEditingController(text: (group?['name'] ?? '').toString());
    String type = (group?['type'] ?? 'single').toString();
    bool required = group?['required'] == true;
    final minCtrl = TextEditingController(text: group?['min']?.toString() ?? '');
    final maxCtrl = TextEditingController(text: group?['max']?.toString() ?? '');
    bool active = group == null ? true : (group['active'] == true);
    final sortCtrl = TextEditingController(text: group?['sort_order']?.toString() ?? '0');
    final gid = (group?['id'] as num?)?.toInt() ?? int.tryParse((group?['id'] ?? '').toString());
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: Text(group == null ? 'Tambah Group' : 'Edit Group'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Tipe', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'single', child: Text('Single (pilih 1)')),
                      DropdownMenuItem(value: 'multi', child: Text('Multi (pilih banyak)')),
                    ],
                    onChanged: (v) => setState(() => type = v ?? 'single'),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: required,
                    onChanged: (v) => setState(() => required = v),
                    title: const Text('Wajib dipilih'),
                  ),
                  if (type == 'multi') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Min', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Max', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: sortCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Urutan', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    onChanged: (v) => setState(() => active = v),
                    title: const Text('Aktif'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final min = int.tryParse(minCtrl.text.trim());
                  final max = int.tryParse(maxCtrl.text.trim());
                  final sort = int.tryParse(sortCtrl.text.trim()) ?? 0;
                  try {
                    final dio = ref.read(dioProvider);
                    if (gid == null) {
                      await dio.post('/api/v1/seller/option-groups', data: {
                        'name': name,
                        'type': type,
                        'required': required,
                        if (type == 'multi') 'min': min,
                        if (type == 'multi') 'max': max,
                        'active': active,
                        'sort_order': sort,
                      });
                    } else {
                      await dio.put('/api/v1/seller/option-groups/$gid', data: {
                        'name': name,
                        'type': type,
                        'required': required,
                        if (type == 'multi') 'min': min,
                        if (type == 'multi') 'max': max,
                        'active': active,
                        'sort_order': sort,
                      });
                    }
                    ref.invalidate(sellerOptionGroupsProvider);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        });
      },
    );
    nameCtrl.dispose();
    minCtrl.dispose();
    maxCtrl.dispose();
    sortCtrl.dispose();
  }

  static Future<void> _showItemDialog(BuildContext context, WidgetRef ref, {required int groupId, Map<String, dynamic>? item}) async {
    if (groupId <= 0) return;
    final nameCtrl = TextEditingController(text: (item?['name'] ?? '').toString());
    final priceCtrl = TextEditingController(text: (item?['price'] ?? '0').toString());
    bool active = item == null ? true : (item['active'] == true);
    final sortCtrl = TextEditingController(text: item?['sort_order']?.toString() ?? '0');
    final itemId = (item?['id'] as num?)?.toInt() ?? int.tryParse((item?['id'] ?? '').toString());
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            title: Text(item == null ? 'Tambah Item' : 'Edit Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga tambah (Rp)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sortCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Urutan', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                  title: const Text('Aktif'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                  final sort = int.tryParse(sortCtrl.text.trim()) ?? 0;
                  try {
                    final dio = ref.read(dioProvider);
                    if (itemId == null) {
                      await dio.post('/api/v1/seller/option-groups/$groupId/items', data: {
                        'name': name,
                        'price': price,
                        'active': active,
                        'sort_order': sort,
                      });
                    } else {
                      await dio.put('/api/v1/seller/option-items/$itemId', data: {
                        'name': name,
                        'price': price,
                        'active': active,
                        'sort_order': sort,
                      });
                    }
                    ref.invalidate(sellerOptionGroupsProvider);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        });
      },
    );
    nameCtrl.dispose();
    priceCtrl.dispose();
    sortCtrl.dispose();
  }
}

