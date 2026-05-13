import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../wallet/providers/wallet_provider.dart';

final settlementConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/api/v1/seller/settlement/config');
  return Map<String, dynamic>.from(res.data['data'] as Map);
});

class SettlementSettingsPage extends ConsumerWidget {
  const SettlementSettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(settlementConfigProvider);
    final banks = ref.watch(bankAccountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Pencairan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: cfg.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Gagal memuat: $e')),
          data: (data) {
            var method = (data['method'] as String?) ?? 'manual';
            int? bankId = (data['bank_account_id'] as int?);
            int delay = (data['auto_delay_days'] as int?) ?? 1;
            return StatefulBuilder(builder: (ctx, setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Metode', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  RadioListTile<String>(
                    value: 'automatic',
                    groupValue: method,
                    onChanged: (v) => setState(() => method = v!),
                    title: const Text('Otomatis (H+1)'),
                    subtitle: const Text('Dana ditransfer otomatis sesuai jadwal'),
                  ),
                  RadioListTile<String>(
                    value: 'manual',
                    groupValue: method,
                    onChanged: (v) => setState(() => method = v!),
                    title: const Text('Manual (Tarik Dana Sendiri)'),
                    subtitle: const Text('Tarik dana kapan saja dari menu Dompet'),
                  ),
                  const SizedBox(height: 16),
                  if (method == 'automatic') ...[
                    const Text('Rekening Tujuan', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    banks.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, st) => Text('Gagal memuat rekening: $e'),
                      data: (items) {
                        if (items.isEmpty) {
                          return Row(
                            children: [
                              const Expanded(child: Text('Belum ada rekening. Tambahkan dulu.')),
                              TextButton(onPressed: () { Navigator.of(context).pushNamed('/wallet/banks'); }, child: const Text('Kelola')),
                            ],
                          );
                        }
                        return DropdownButtonFormField<int>(
                          value: bankId,
                          onChanged: (v) => setState(() => bankId = v),
                          items: items.map((it) {
                            final label = '${it['bank_name'] ?? ''} • ${it['account_number'] ?? ''}';
                            return DropdownMenuItem<int>(value: it['id'] as int?, child: Text(label));
                          }).toList(),
                          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Pilih rekening'),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Jeda Otomatis (hari)', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: delay,
                      onChanged: (v) => setState(() => delay = v ?? 1),
                      items: const [1,2,3,4,5,6,7].map((d) => DropdownMenuItem<int>(value: d, child: Text('H+$d'))).toList(),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      try {
                        final dio = ref.read(dioProvider);
                        await dio.put('/api/v1/seller/settlement/config', data: {
                          'method': method,
                          'bank_account_id': bankId,
                          'auto_delay_days': delay,
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan disimpan')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
                        }
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ],
              );
            });
          },
        ),
      ),
    );
  }
}
