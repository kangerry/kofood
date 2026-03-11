import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Preferences {
  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<void> saveAuth({required String token, required String role, required String userId}) async {
    final p = await _prefs();
    await p.setString('token', token);
    await p.setString('role', role);
    await p.setString('user_id', userId);
  }

  Future<String?> getToken() async {
    final p = await _prefs();
    return p.getString('token');
    }

  Future<String?> getRole() async {
    final p = await _prefs();
    return p.getString('role');
  }

  Future<String?> getUserId() async {
    final p = await _prefs();
    return p.getString('user_id');
  }

  Future<void> setKoperasiId(String id) async {
    final p = await _prefs();
    await p.setString('koperasi_id', id);
  }

  Future<String> getKoperasiId() async {
    final p = await _prefs();
    return p.getString('koperasi_id') ?? '1';
  }

  Future<void> clearAuth() async {
    final p = await _prefs();
    await p.remove('token');
    await p.remove('role');
    await p.remove('user_id');
  }

  Future<void> setBaseUrl(String url) async {
    final p = await _prefs();
    await p.setString('base_url', url);
  }

  Future<String?> getBaseUrl() async {
    final p = await _prefs();
    return p.getString('base_url');
  }

  Future<void> setGoogleWebClientId(String clientId) async {
    final p = await _prefs();
    await p.setString('google_web_client_id', clientId);
  }

  Future<String?> getGoogleWebClientId() async {
    final p = await _prefs();
    return p.getString('google_web_client_id');
  }

  Future<void> setFirebaseWebConfig({
    String? apiKey,
    String? authDomain,
    String? projectId,
    String? storageBucket,
    String? messagingSenderId,
    String? appId,
    String? measurementId,
  }) async {
    final p = await _prefs();
    if (apiKey != null) await p.setString('firebase_api_key', apiKey);
    if (authDomain != null) await p.setString('firebase_auth_domain', authDomain);
    if (projectId != null) await p.setString('firebase_project_id', projectId);
    if (storageBucket != null) await p.setString('firebase_storage_bucket', storageBucket);
    if (messagingSenderId != null) await p.setString('firebase_messaging_sender_id', messagingSenderId);
    if (appId != null) await p.setString('firebase_app_id', appId);
    if (measurementId != null) await p.setString('firebase_measurement_id', measurementId);
  }

  Future<Map<String, String>> getFirebaseWebConfig() async {
    final p = await _prefs();
    return {
      'apiKey': p.getString('firebase_api_key') ?? '',
      'authDomain': p.getString('firebase_auth_domain') ?? '',
      'projectId': p.getString('firebase_project_id') ?? '',
      'storageBucket': p.getString('firebase_storage_bucket') ?? '',
      'messagingSenderId': p.getString('firebase_messaging_sender_id') ?? '',
      'appId': p.getString('firebase_app_id') ?? '',
      'measurementId': p.getString('firebase_measurement_id') ?? '',
    };
  }
}

final preferencesProvider = Provider<Preferences>((ref) => Preferences());
