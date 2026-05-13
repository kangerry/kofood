import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/format.dart';
import '../providers/wallet_provider.dart';
import 'topup_va_sheet.dart';
import 'withdraw_page.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(walletSummaryProvider);
    final txs = ref.watch(walletTransactionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dompet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    summary.when(
                      loading: () => const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, st) => Text('Gagal memuat saldo: $e'),
                      data: (data) {
                        final saldo = (data['saldo'] as num?)?.toInt() ?? 0;
                        return Text(formatRupiah(saldo), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const TopupVaSheet(),
                      );
                    },
                    child: const Text('Topup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton(onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (_) => WithdrawPage())); }, child: const Text('Tarik Dana'))),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Riwayat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(child: txs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Gagal memuat riwayat: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Belum ada transaksi'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final it = items[i];
                    final jenis = (it['jenis'] as String?) ?? '';
                    final jumlah = ((it['jumlah'] as num?) ?? 0).toInt();
                    final t = (jenis.toUpperCase() == 'TOPUP') ? '+${formatRupiah(jumlah)}' : '-${formatRupiah(jumlah)}';
                    return ListTile(
                      leading: const Icon(Icons.account_balance_wallet_outlined),
                      title: Text(jenis.isEmpty ? 'Transaksi' : jenis),
                      subtitle: Text((it['created_at'] as String?) ?? ''),
                      trailing: Text(t),
                    );
                  },
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}
