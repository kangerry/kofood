import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../providers/wallet_provider.dart';

class BankAccountsPage extends ConsumerWidget {
  const BankAccountsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banks = ref.watch(bankAccountsProvider);
    final bankCodeCtl = TextEditingController();
    final bankNameCtl = TextEditingController();
    final accNumberCtl = TextEditingController();
    final accHolderCtl = TextEditingController();
    bool isDefault = false;
    return Scaffold(
      appBar: AppBar(title: const Text('Rekening Bank')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daftar Rekening', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Expanded(
              child: banks.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Gagal memuat: $e')),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('Belum ada rekening'));
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final it = items[i];
                      final title = '${it['bank_name'] ?? ''} • ${it['account_number'] ?? ''}';
                      final subtitle = (it['account_holder'] as String?) ?? '';
                      final isDef = (it['is_default'] as bool?) ?? false;
                      return ListTile(
                        leading: Icon(isDef ? Icons.star : Icons.account_balance_outlined),
                        title: Text(title),
                        subtitle: Text(subtitle),
                        trailing: IconButton(
                          tooltip: 'Hapus',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            try {
                              final dio = ref.read(dioProvider);
                              await dio.delete('/api/v1/wallet/bank-accounts/${it['id']}');
                              ref.invalidate(bankAccountsProvider);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text('Tambah Rekening', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(controller: bankCodeCtl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Kode Bank (mis. BRI)'),),
            const SizedBox(height: 8),
            TextField(controller: bankNameCtl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Nama Bank'),),
            const SizedBox(height: 8),
            TextField(controller: accNumberCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Nomor Rekening'),),
            const SizedBox(height: 8),
            TextField(controller: accHolderCtl, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Nama Pemilik Rekening'),),
            const SizedBox(height: 8),
            StatefulBuilder(builder: (ctx, setState) {
              return CheckboxListTile(
                value: isDefault,
                onChanged: (v) => setState(() => isDefault = v ?? false),
                title: const Text('Jadikan Default'),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                try {
                  final dio = ref.read(dioProvider);
                  await dio.post('/api/v1/wallet/bank-accounts', data: {
                    'bank_code': bankCodeCtl.text.trim(),
                    'bank_name': bankNameCtl.text.trim(),
                    'account_number': accNumberCtl.text.trim(),
                    'account_holder': accHolderCtl.text.trim(),
                    'is_default': isDefault,
                  });
                  ref.invalidate(bankAccountsProvider);
                  bankCodeCtl.clear();
                  bankNameCtl.clear();
                  accNumberCtl.clear();
                  accHolderCtl.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rekening ditambahkan')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal tambah: $e')));
                }
              },
              child: const Text('Simpan Rekening'),
            ),
          ],
        ),
      ),
    );
  }
}
