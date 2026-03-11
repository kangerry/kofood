import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/presentation/settings_page.dart';
import '../providers/profile_provider.dart';
import 'profile_edit_page.dart';
import '../../auth/presentation/register_merchant_page.dart';
import '../../auth/presentation/register_page.dart';
import '../../seller/presentation/seller_shop_edit_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 24),
            const Center(child: Icon(Icons.error_outline, size: 48)),
            const SizedBox(height: 12),
            Center(child: Text('Gagal memuat profil')),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => ref.refresh(profileProvider), child: const Text('Coba lagi')),
          ],
        ),
        data: (data) {
          final roleText = '${data['role'] ?? (auth.role == UserRole.merchant ? 'merchant' : 'anggota')}'.toLowerCase() == 'merchant' ? 'Merchant' : 'Anggota';
          final user = Map<String, dynamic>.from(data['user'] ?? {});
          final nama = user['nama_anggota'] ?? user['nama_toko'] ?? user['name'] ?? '-';
          final email = user['email'] ?? '-';
          final telepon = user['telepon'] ?? '-';
          final userId = '${user['id'] ?? auth.userId ?? '-'}';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
              const SizedBox(height: 12),
              Center(child: Text(userId, style: const TextStyle(fontWeight: FontWeight.w700))),
              const SizedBox(height: 4),
              Center(child: Text(roleText)),
              if (roleText.toLowerCase() == 'anggota')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Center(child: Text('Status: ${user['status'] ?? '-'}')),
                ),
              if (roleText.toLowerCase() == 'anggota' && (data['seller'] != null))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Center(
                    child: Text(
                      'Seller: ${data['seller']?['status'] ?? '-'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (auth.role == UserRole.anggota)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Ingin mulai berjualan?', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Builder(builder: (ctx) {
                          final seller = data['seller'];
                          final disabled = seller != null;
                          return OutlinedButton(
                            onPressed: disabled
                                ? null
                                : () async {
                                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterMerchantPage(applyForAnggota: true)));
                                    ref.invalidate(profileProvider);
                                  },
                            child: Text(disabled ? 'Seller sudah terdaftar' : 'Ajukan Seller'),
                          );
                        }),
                        const SizedBox(height: 8),
                        Builder(builder: (ctx) {
                          final seller = data['seller'];
                          final aktif = seller != null && '${seller['status'] ?? ''}'.toLowerCase() == 'aktif';
                          return FilledButton.tonal(
                            onPressed: aktif
                                ? () {
                                    context.go('/seller');
                                  }
                                : null,
                            child: const Text('Masuk Seller Center'),
                          );
                        }),
                        const SizedBox(height: 8),
                        Builder(builder: (ctx) {
                          final seller = data['seller'];
                          final hasSeller = seller != null;
                          return OutlinedButton.icon(
                            onPressed: hasSeller
                                ? () async {
                                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SellerShopEditPage()));
                                  }
                                : null,
                            icon: const Icon(Icons.place_outlined),
                            label: const Text('Edit Toko (Lokasi/Alamat)'),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              if (auth.role != UserRole.anggota)
                Builder(builder: (ctx) {
                  final seller = data['seller'];
                  if (seller != null && '${seller['status'] ?? ''}'.isNotEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Kelola Toko', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: () async {
                                try {
                                  await ref.read(authStateProvider.notifier).switchToMerchant();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil masuk Seller Center')));
                                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileEditPage()));
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan seller belum disetujui')));
                                  }
                                }
                              },
                              child: const Text('Edit Toko'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              if (auth.role == UserRole.anggota)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Belum menjadi anggota koperasi?', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
                            ref.invalidate(profileProvider);
                          },
                          child: const Text('Daftar Jadi Anggota'),
                        ),
                      ],
                    ),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Profil'),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileEditPage()));
                  ref.invalidate(profileProvider);
                },
              ),
              const Divider(height: 24),
              ListTile(title: const Text('Nama'), subtitle: Text(nama), leading: const Icon(Icons.badge_outlined)),
              ListTile(title: const Text('Email'), subtitle: Text(email), leading: const Icon(Icons.email_outlined)),
              ListTile(title: const Text('Telepon'), subtitle: Text(telepon), leading: const Icon(Icons.phone_outlined)),
              const SizedBox(height: 8),
              if (kDebugMode || kIsWeb)
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Pengaturan'),
                  subtitle: const Text('Dev settings'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
                ),
              const SizedBox(height: 8),
              FilledButton(onPressed: () async { await ref.read(authStateProvider.notifier).logout(); if (context.mounted) context.go('/login'); }, child: const Text('Logout')),
              const SizedBox(height: 8),
              const Center(child: Text('Koperasi Digital KOMERA')),
            ],
          );
        },
      ),
    );
  }
}
