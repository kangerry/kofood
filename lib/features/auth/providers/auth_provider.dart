import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/preferences.dart';
import '../../../core/config/runtime.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

enum UserRole { anggota, merchant }

class AuthState {
  final String? token;
  final UserRole? role;
  final String? userId;
  final bool initialized;
  const AuthState({this.token, this.role, this.userId, this.initialized = false});
  AuthState copyWith({String? token, UserRole? role, String? userId, bool? initialized}) {
    return AuthState(
      token: token ?? this.token,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      initialized: initialized ?? this.initialized,
    );
  }
  bool get isLoggedIn => token != null && role != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Preferences prefs;
  final Dio dio;
  AuthNotifier(this.prefs, this.dio) : super(const AuthState()) {
    _load();
  }

  Future<void> _load() async {
    final token = await prefs.getToken();
    final roleStr = await prefs.getRole();
    final userId = await prefs.getUserId();
    final role = roleStr == 'merchant'
        ? UserRole.merchant
        : (roleStr == 'anggota' ? UserRole.anggota : null);
    state = state.copyWith(token: token, role: role, userId: userId, initialized: true);
  }

  Future<void> loginEmail({required String email, required String password, String? type}) async {
    final res = await dio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
      if (type != null) 'type': type,
    });
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final userId = (data['user']?['id'] ?? '').toString();
    final koperasiId = (data['koperasi_id'] ?? '').toString();
    final roleStr = (data['role'] ?? '').toString();
    final role = roleStr == 'merchant' ? UserRole.merchant : UserRole.anggota;
    await prefs.saveAuth(token: token, role: role.name, userId: userId);
    if (koperasiId.isNotEmpty) {
      await prefs.setKoperasiId(koperasiId);
    }
    state = state.copyWith(token: token, role: role, userId: userId);
    await _tryRegisterDeviceToken();
  }

  Future<void> loginGoogle() async {
    try {
      UserCredential credential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        credential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final g = GoogleSignIn(scopes: const ['email', 'profile', 'openid']);
        try { await g.signOut(); } catch (_) {}
        final googleUser = await g.signIn();
        if (googleUser == null) {
          throw Exception('Login dibatalkan');
        }
        final googleAuth = await googleUser.authentication;
        final cred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await FirebaseAuth.instance.signInWithCredential(cred);
      }
      final user = credential.user ?? FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Token kosong');
      }
      final gUid = user?.providerData.firstWhere(
            (p) => p.providerId == 'google.com',
            orElse: () => user!.providerData.isNotEmpty ? user!.providerData.first : user!.providerData.firstWhere((_) => true),
          ).uid;
      final payload = {
        'google_id': gUid ?? user?.uid ?? '',
        'email': user?.email ?? '',
        'name': user?.displayName ?? 'User Google',
        'id_token': idToken,
      };
      final Response<dynamic> res = await dio.post('/api/v1/auth/login-google', data: payload);
      final data = Map<String, dynamic>.from(res.data ?? {});
      final token = '${data['token'] ?? ''}';
      final userId = (data['user']?['id'] ?? data['user_id'] ?? '').toString();
      final koperasiId = (data['koperasi_id'] ?? '').toString();
      final roleStr = (data['role'] ?? '').toString();
      final role = roleStr == 'merchant' ? UserRole.merchant : UserRole.anggota;
      if (token.isEmpty) {
        throw Exception('Token tidak valid');
      }
      await prefs.saveAuth(token: token, role: role.name, userId: userId);
      if (koperasiId.isNotEmpty) {
        await prefs.setKoperasiId(koperasiId);
      }
      state = state.copyWith(token: token, role: role, userId: userId);
      await _tryRegisterDeviceToken();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerAnggota({required String nama, required String email, required String password}) async {
    final res = await dio.post('/api/v1/auth/register-anggota', data: {
      'nama': nama,
      'email': email,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final userId = (data['user']?['id'] ?? '').toString();
    final koperasiId = (data['koperasi_id'] ?? '').toString();
    final roleStr = (data['role'] ?? '').toString();
    final role = roleStr == 'merchant' ? UserRole.merchant : UserRole.anggota;
    await prefs.saveAuth(token: token, role: role.name, userId: userId);
    if (koperasiId.isNotEmpty) {
      await prefs.setKoperasiId(koperasiId);
    }
    state = state.copyWith(token: token, role: role, userId: userId);
  }

  Future<void> registerMerchant({
    required String namaToko,
    required String email,
    required String password,
    String? telepon,
    String? alamat,
    double? latitude,
    double? longitude,
  }) async {
    final res = await dio.post('/api/v1/auth/register-merchant', data: {
      'nama_toko': namaToko,
      'email': email,
      'password': password,
      if (telepon != null) 'telepon': telepon,
      if (alamat != null) 'alamat': alamat,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final userId = (data['user']?['id'] ?? '').toString();
    final koperasiId = (data['koperasi_id'] ?? '').toString();
    final roleStr = (data['role'] ?? '').toString();
    final role = roleStr == 'merchant' ? UserRole.merchant : UserRole.anggota;
    await prefs.saveAuth(token: token, role: role.name, userId: userId);
    if (koperasiId.isNotEmpty) {
      await prefs.setKoperasiId(koperasiId);
    }
    state = state.copyWith(token: token, role: role, userId: userId);
    await _tryRegisterDeviceToken();
  }
  Future<void> applySeller({
    required String namaToko,
    required String deskripsi,
    required String alamat,
    required double latitude,
    required double longitude,
    String? nib,
    String? pirt,
  }) async {
    await dio.post('/api/v1/auth/apply-seller', data: {
      'nama_toko': namaToko,
      'deskripsi': deskripsi,
      'alamat': alamat,
      'latitude': latitude,
      'longitude': longitude,
      if (nib != null && nib.isNotEmpty) 'nib': nib,
      if (pirt != null && pirt.isNotEmpty) 'pirt': pirt,
    });
  }
  Future<void> switchToMerchant() async {
    final res = await dio.post('/api/v1/auth/switch-to-merchant');
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final userId = (data['user']?['id'] ?? '').toString();
    final koperasiId = (data['koperasi_id'] ?? '').toString();
    final roleStr = (data['role'] ?? '').toString();
    final role = roleStr == 'merchant' ? UserRole.merchant : UserRole.anggota;
    await prefs.saveAuth(token: token, role: role.name, userId: userId);
    if (koperasiId.isNotEmpty) {
      await prefs.setKoperasiId(koperasiId);
    }
    state = state.copyWith(token: token, role: role, userId: userId);
    await _tryRegisterDeviceToken();
  }
  Future<void> logout() async {
    try {
      await dio.post('/api/v1/auth/logout');
    } catch (_) {}
    try { await FirebaseAuth.instance.signOut(); } catch (_) {}
    try { await GoogleSignIn().signOut(); } catch (_) {}
    await prefs.clearAuth();
    state = const AuthState(initialized: true);
  }

  Future<void> _tryRegisterDeviceToken() async {
    try {
      try {
        await Firebase.initializeApp();
      } catch (_) {}
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      String? token;
      if (kIsWeb) {
        final vapid = RuntimeConfig.webVapidKey;
        token = await messaging.getToken(vapidKey: vapid.isNotEmpty ? vapid : null);
      } else {
        token = await messaging.getToken();
      }
      if (token == null || token.isEmpty) return;
      String platform = 'web';
      if (!kIsWeb) {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            platform = 'android';
            break;
          case TargetPlatform.iOS:
            platform = 'ios';
            break;
          default:
            platform = 'other';
        }
      }
      await dio.post('/api/v1/auth/register-device-token', data: {
        'token': token,
        'platform': platform,
      });
      // Optional: Register OneSignal Player ID if OneSignal App ID is configured
      if (RuntimeConfig.oneSignalAppId.isNotEmpty) {
        try {
          OneSignal.initialize(RuntimeConfig.oneSignalAppId);
          await OneSignal.Notifications.requestPermission(true);
          final playerId = OneSignal.User.pushSubscription.id;
          if (playerId != null && playerId.isNotEmpty) {
            await dio.post('/api/v1/auth/register-device-token', data: {
              'token': playerId,
              'platform': 'onesignal',
            });
          }
        } catch (_) {}
      }
    } catch (_) {}
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.read(preferencesProvider);
  final d = ref.read(dioProvider);
  return AuthNotifier(prefs, d);
});
