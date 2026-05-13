import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/providers/auth_provider.dart';

class OrderChatPage extends ConsumerStatefulWidget {
  final String orderId;
  const OrderChatPage({super.key, required this.orderId});
  @override
  ConsumerState<OrderChatPage> createState() => _OrderChatPageState();
}

class _OrderChatPageState extends ConsumerState<OrderChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/api/v1/kofood/orders/${widget.orderId}/chat');
      final data = (resp.data['data'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];
      setState(() => _messages = data);
      if (_scroll.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        });
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/kofood/orders/${widget.orderId}/chat', data: {'message': text});
      _controller.clear();
      await _poll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authStateProvider).role;
    return Scaffold(
      appBar: AppBar(title: const Text('Pesan')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final sender = '${m['sender_type'] ?? ''}';
                final senderName = '${m['sender_name'] ?? ''}'.trim();
                final mine = (role == UserRole.anggota && sender == 'anggota') || (role == UserRole.merchant && sender == 'merchant');
                final bubble = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: mine ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((m['image_url'] as String?)?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Image.network(m['image_url'] as String, height: 120, fit: BoxFit.cover),
                        ),
                      if ((m['message'] as String?)?.isNotEmpty ?? false)
                        Text('${m['message']}', style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        [
                          sender.toUpperCase() + (senderName.isNotEmpty ? ' ($senderName)' : ''),
                          '${m['created_at'] ?? ''}'
                        ].where((x) => x.trim().isNotEmpty).join(' • '),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [bubble],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
