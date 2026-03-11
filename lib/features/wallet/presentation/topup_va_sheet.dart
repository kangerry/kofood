import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'package:url_launcher/url_launcher.dart';

class TopupVaSheet extends ConsumerStatefulWidget {
  const TopupVaSheet({super.key});
  @override
  ConsumerState<TopupVaSheet> createState() => _TopupVaSheetState();
}

class _TopupVaSheetState extends ConsumerState<TopupVaSheet> {
  final _amount = TextEditingController();
  String? _error;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _status;

  Future<void> _createVa() async {
    final v = int.tryParse(_amount.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    if (v < 1000) {
      setState(() => _error = 'Minimal topup Rp1.000');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _status = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/api/v1/wallet/topup/va', data: {'amount': v, 'channel': 'VIRTUAL_ACCOUNT_BRI'});
      setState(() => _result = Map<String, dynamic>.from(res.data as Map));
    } catch (e) {
      String err = 'Gagal membuat VA';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) {
          err = data['message'] as String;
        }
      }
      setState(() => _error = err);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkStatus() async {
    if (_result == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/api/v1/wallet/topup/va/status', data: {'invoice': _result!['invoice']});
      final data = Map<String, dynamic>.from(res.data as Map);
      setState(() => _status = data['status'] ?? 'UNKNOWN');
    } catch (e) {
      String err = 'Gagal cek status';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) {
          err = data['message'] as String;
        }
      }
      setState(() => _error = err);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.7,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Topup Dompet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                if (_result == null) ...[
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jumlah Topup (Rp)', hintText: 'Contoh: 50000'),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                  FilledButton(
                    onPressed: _loading ? null : _createVa,
                    child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Buat VA Topup'),
                  ),
                ] else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Virtual Account', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          SelectableText('${_result!['va_number'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text('Jumlah: Rp ${_result!['amount']}'),
                          const SizedBox(height: 4),
                          Text('Bank/Channel: ${_result!['channel'] ?? '-'}'),
                          const SizedBox(height: 4),
                          Text('Berlaku sampai: ${_result!['expired_date'] ?? '-'}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final va = '${_result!['va_number'] ?? ''}';
                            Clipboard.setData(ClipboardData(text: va));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor VA disalin')));
                          },
                          child: const Text('Salin VA'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final url = '${_result!['how_to_pay'] ?? _result!['how_to_pay_page'] ?? ''}';
                            if (url.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link cara bayar tidak tersedia')));
                              return;
                            }
                            try {
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.platformDefault);
                              } else {
                                Clipboard.setData(ClipboardData(text: url));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka, link disalin ke clipboard')));
                              }
                            } catch (_) {
                              Clipboard.setData(ClipboardData(text: url));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka, link disalin ke clipboard')));
                            }
                          },
                          child: const Text('Buka Cara Bayar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_status != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Status: $_status')),
                  FilledButton(
                    onPressed: _loading ? null : _checkStatus,
                    child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Cek Status Pembayaran'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Tutup'),
                  ),
                ],
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
