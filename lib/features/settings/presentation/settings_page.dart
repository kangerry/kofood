import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/config/runtime.dart';
import '../../../core/network/dio_client.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _koperasiId = TextEditingController();
  final _baseUrl = TextEditingController();
  final _googleWebClientId = TextEditingController();
  final _fbApiKey = TextEditingController();
  final _fbAuthDomain = TextEditingController();
  final _fbProjectId = TextEditingController();
  final _fbStorageBucket = TextEditingController();
  final _fbMessagingSenderId = TextEditingController();
  final _fbAppId = TextEditingController();
  final _fbMeasurementId = TextEditingController();
  bool _loading = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = ref.read(preferencesProvider);
    final id = await prefs.getKoperasiId();
    if (mounted) _koperasiId.text = id;
    final bu = await prefs.getBaseUrl();
    if (mounted && bu != null) _baseUrl.text = bu;
    final gid = await prefs.getGoogleWebClientId();
    if (mounted && gid != null) _googleWebClientId.text = gid;
    final fb = await prefs.getFirebaseWebConfig();
    if (mounted) {
      _fbApiKey.text = fb['apiKey'] ?? '';
      _fbAuthDomain.text = fb['authDomain'] ?? '';
      _fbProjectId.text = fb['projectId'] ?? '';
      _fbStorageBucket.text = fb['storageBucket'] ?? '';
      _fbMessagingSenderId.text = fb['messagingSenderId'] ?? '';
      _fbAppId.text = fb['appId'] ?? '';
      _fbMeasurementId.text = fb['measurementId'] ?? '';
    }
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _msg = null;
    });
    try {
      final prefs = ref.read(preferencesProvider);
      if (kDebugMode || kIsWeb) {
        await prefs.setKoperasiId(_koperasiId.text.trim().isEmpty ? '1' : _koperasiId.text.trim());
        final url = _baseUrl.text.trim();
        if (url.isNotEmpty) {
          await prefs.setBaseUrl(url);
          RuntimeConfig.baseUrl = url;
          ref.invalidate(dioProvider);
        }
        if (_googleWebClientId.text.trim().isNotEmpty) {
          await prefs.setGoogleWebClientId(_googleWebClientId.text.trim());
        }
        await prefs.setFirebaseWebConfig(
          apiKey: _fbApiKey.text.trim().isEmpty ? null : _fbApiKey.text.trim(),
          authDomain: _fbAuthDomain.text.trim().isEmpty ? null : _fbAuthDomain.text.trim(),
          projectId: _fbProjectId.text.trim().isEmpty ? null : _fbProjectId.text.trim(),
          storageBucket: _fbStorageBucket.text.trim().isEmpty ? null : _fbStorageBucket.text.trim(),
          messagingSenderId: _fbMessagingSenderId.text.trim().isEmpty ? null : _fbMessagingSenderId.text.trim(),
          appId: _fbAppId.text.trim().isEmpty ? null : _fbAppId.text.trim(),
          measurementId: _fbMeasurementId.text.trim().isEmpty ? null : _fbMeasurementId.text.trim(),
        );
      }
      setState(() => _msg = 'Tersimpan. Muat ulang halaman untuk menerapkan konfigurasi Firebase.');
    } catch (e) {
      setState(() => _msg = 'Gagal menyimpan');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDevFields = kDebugMode || kIsWeb;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (showDevFields) ...[
            TextField(
              controller: _koperasiId,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Koperasi ID', helperText: 'Header X-Koperasi-Id untuk API'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrl,
              decoration: const InputDecoration(labelText: 'Base URL API', helperText: 'Contoh: https://mobile.komera.id'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _googleWebClientId,
              decoration: const InputDecoration(labelText: 'Google Web Client ID', helperText: 'Digunakan saat login Google di Web/Chrome'),
            ),
            const SizedBox(height: 8),
            const Divider(height: 32),
            const Text('Firebase Web', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _fbApiKey,
              decoration: const InputDecoration(labelText: 'apiKey'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fbAuthDomain,
              decoration: const InputDecoration(labelText: 'authDomain'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fbProjectId,
              decoration: const InputDecoration(labelText: 'projectId'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fbStorageBucket,
              decoration: const InputDecoration(labelText: 'storageBucket'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fbMessagingSenderId,
              decoration: const InputDecoration(labelText: 'messagingSenderId'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fbAppId,
              decoration: const InputDecoration(labelText: 'appId'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fbMeasurementId,
              decoration: const InputDecoration(labelText: 'measurementId (opsional)'),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton(onPressed: _loading ? null : _save, child: _loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan')),
          if (_msg != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_msg!)),
        ],
      ),
    );
  }
}
