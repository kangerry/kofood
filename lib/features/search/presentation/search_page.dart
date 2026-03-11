import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  final List<String> _history = [];
  List<Map<String, dynamic>> _results = const [];
  bool _loading = false;

  Future<void> _doSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _results = const []; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/api/v1/kofood/search', queryParameters: {'q': q});
      final List data = res.data?['data'] as List? ?? const [];
      setState(() {
        _results = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() { _results = const []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Cari merchant atau produk'),
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: (v) {
            _query = v;
            if (v.isNotEmpty) {
              setState(() {
                _history.remove(v);
                _history.insert(0, v);
              });
            }
            _doSearch(v);
          },
        ),
        actions: [
          IconButton(onPressed: () { _controller.clear(); setState(() { _query = ''; _results = const []; }); }, icon: const Icon(Icons.clear)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (_history.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      children: _history
                          .take(8)
                          .map((e) => ActionChip(
                                label: Text(e),
                                onPressed: () {
                                  setState(() => _query = e);
                                  _doSearch(e);
                                },
                              ))
                          .toList(),
                    ),
                  ),
                if (_results.isEmpty && _query.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Ketik untuk mencari merchant atau produk'),
                  ),
                ..._results.map((r) {
                  final type = r['type'] as String? ?? '';
                  final title = r['title']?.toString() ?? '';
                  final subtitle = r['subtitle']?.toString() ?? '';
                  final image = r['image']?.toString();
                  return ListTile(
                    leading: image != null
                        ? CircleAvatar(backgroundImage: NetworkImage(image))
                        : CircleAvatar(child: Icon(type == 'merchant' ? Icons.store : Icons.fastfood)),
                    title: Text(title),
                    subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                    onTap: () {
                      final id = r['id']?.toString() ?? '';
                      if (type == 'merchant') {
                        context.push('/kofood/merchant/$id');
                      } else if (type == 'product') {
                        context.push('/kofood/product/$id');
                      }
                    },
                  );
                }).toList(),
              ],
            ),
    );
  }
}
