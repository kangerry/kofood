import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/presentation/settings_page.dart';
import '../providers/profile_provider.dart';
import 'profile_edit_page.dart';
import '../../auth/presentation/register_page.dart';

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
          const roleText = 'Anggota';
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
              const SizedBox(height: 16),
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
