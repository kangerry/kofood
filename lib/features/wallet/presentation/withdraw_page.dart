import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../providers/wallet_provider.dart';
import '../../../core/utils/format.dart';

class WithdrawPage extends ConsumerWidget {
  const WithdrawPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banks = ref.watch(bankAccountsProvider);
    final summary = ref.watch(walletSummaryProvider);
    final amountCtl = TextEditingController();
    int? selectedBankId;
    return Scaffold(
      appBar: AppBar(title: const Text('Tarik Dana')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(builder: (ctx, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo', style: TextStyle(fontWeight: FontWeight.w700)),
                      summary.when(
                        loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (e, st) => Text('Err: $e'),
                        data: (data) => Text(formatRupiah(((data['saldo'] as num?) ?? 0).toInt()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Pilih Rekening', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              banks.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Gagal memuat rekening: $e'),
                data: (items) {
                  if (items.isEmpty) {
                    return Row(
                      children: [
                        const Expanded(child: Text('Belum ada rekening. Tambahkan dari menu Rekening Bank.')),
                        TextButton(onPressed: () { Navigator.of(context).pushNamed('/wallet/banks'); }, child: const Text('Kelola')),
                      ],
                    );
                  }
                  selectedBankId ??= items.first['id'] as int?;
                  return DropdownButtonFormField<int>(
                    value: selectedBankId,
                    onChanged: (v) => setState(() => selectedBankId = v),
                    items: items.map((it) {
                      final label = '${it['bank_name'] ?? ''} • ${it['account_number'] ?? ''}';
                      return DropdownMenuItem<int>(value: it['id'] as int?, child: Text(label));
                    }).toList(),
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Pilih rekening'),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text('Nominal', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Masukkan nominal (min 1.000)'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  try {
                    final amt = int.tryParse(amountCtl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                    if (selectedBankId == null || amt < 1000) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih rekening dan nominal minimal Rp1.000')));
                      return;
                    }
                    final dio = ref.read(dioProvider);
                    await dio.post('/api/v1/wallet/withdraw', data: {
                      'bank_account_id': selectedBankId,
                      'amount': amt,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan tarik dana dikirim')));
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                    }
                  }
                },
                child: const Text('Tarik Dana'),
              ),
            ],
          );
        }),
      ),
    );
  }
}
