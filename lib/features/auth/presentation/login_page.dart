import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'register_page.dart';
import 'package:dio/dio.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).loginEmail(
            email: _email.text.trim(),
            password: _password.text,
            type: 'anggota',
          );
    } catch (e) {
      String msg = 'Gagal login';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
          msg = data['message'] as String;
        }
      }
      setState(() => _error = msg);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).loginGoogle();
    } catch (e) {
      String msg = 'Gagal login Google';
      final s = e.toString().toLowerCase();
      if (s.contains('unauthorized') || s.contains('auth/unauthorized-domain')) {
        msg = 'Domain belum diizinkan di Firebase (auth/unauthorized-domain). Tambahkan mobile.komera.id pada Authentication > Settings > Authorized domains.';
      } else if (s.contains('operation-not-allowed') || s.contains('auth/operation-not-allowed')) {
        msg = 'Provider Google belum diaktifkan di Firebase (auth/operation-not-allowed). Aktifkan Sign-in method: Google.';
      } else if (s.contains('disabled_client')) {
        msg = 'Google OAuth client dinonaktifkan';
      } else if (s.contains('popup_closed') || s.contains('popup-closed-by-user')) {
        msg = 'Jendela Google ditutup sebelum login';
      } else if (s.contains('popup_blocked') || s.contains('blocked')) {
        msg = 'Popup diblokir browser. Izinkan pop-up untuk domain ini.';
      }
      setState(() => _error = msg);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Komera', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Masuk', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Email'),
                              validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'Email tidak valid' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Password'),
                              validator: (v) => v == null || v.length < 6 ? 'Minimal 6 karakter' : null,
                            ),
                            const SizedBox(height: 16),
                            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
                            FilledButton(
                              onPressed: _loading ? null : _doLogin,
                              child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Masuk'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _loading ? null : _loginGoogle,
                              child: const Text('Masuk dengan Google'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loading ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
                              child: const Text('Daftar akun baru'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
