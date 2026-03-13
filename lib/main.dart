import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/runtime.dart';
import 'package:dio/dio.dart';
import 'core/notification/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

String? _pendingRouteAfterLaunch;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final p = await SharedPreferences.getInstance();
  final url = p.getString('base_url');
  if (url != null && url.isNotEmpty) {
    RuntimeConfig.baseUrl = url;
  } else if (kIsWeb) {
    final host = Uri.base.host;
    final origin = Uri.base.origin;
    final isLocal = host == 'localhost' || host == '127.0.0.1';
    RuntimeConfig.baseUrl = isLocal ? 'http://localhost:8000' : origin;
  }
  final webClientId = p.getString('google_web_client_id');
  if (webClientId != null && webClientId.isNotEmpty) {
    RuntimeConfig.googleWebClientId = webClientId;
  }
  if (kIsWeb) {
    final apiKey = p.getString('firebase_api_key') ?? '';
    final authDomain = p.getString('firebase_auth_domain') ?? '';
    final projectId = p.getString('firebase_project_id') ?? '';
    final storageBucket = p.getString('firebase_storage_bucket') ?? '';
    final messagingSenderId = p.getString('firebase_messaging_sender_id') ?? '';
    final appId = p.getString('firebase_app_id') ?? '';
    final measurementId = p.getString('firebase_measurement_id') ?? '';
    final hasCustom = apiKey.isNotEmpty && projectId.isNotEmpty && messagingSenderId.isNotEmpty && appId.isNotEmpty;
    try {
      await Firebase.initializeApp(
        options: hasCustom
            ? FirebaseOptions(
                apiKey: apiKey,
                authDomain: authDomain.isNotEmpty ? authDomain : null,
                projectId: projectId,
                storageBucket: storageBucket.isNotEmpty ? storageBucket : null,
                messagingSenderId: messagingSenderId,
                appId: appId,
                measurementId: measurementId.isNotEmpty ? measurementId : null,
              )
            : DefaultFirebaseOptions.web,
      );
    } catch (_) {}
  } else {
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }
  await NotificationService.initialize();
  try {
    if (RuntimeConfig.oneSignalAppId.isNotEmpty) {
      OneSignal.Notifications.addClickListener((event) {
        final data = Map<String, dynamic>.from(event.notification.additionalData ?? {});
        final type = '${data['type'] ?? ''}';
        if (type == 'kofood_driver_accepted' || type == 'kofood_order_new') {
          final id = data['order_id'] ?? data['orderId'] ?? data['orderID'];
          if (id != null && id.toString().isNotEmpty) {
            final ctx = rootNavigatorKey.currentContext;
            final route = '/kofood/tracking/$id';
            if (ctx != null) {
              try {
                GoRouter.of(ctx).go(route);
              } catch (_) {}
            } else {
              _pendingRouteAfterLaunch = route;
            }
          }
        }
      });
    }
  } catch (_) {}
  try {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      final data = message.data;
      final type = data['type'] ?? '';
      if (type == 'kofood_driver_accepted') {
        final orderNumber = data['number'] ?? '';
        final ctx = rootNavigatorKey.currentContext;
        final body = (n?.body?.isNotEmpty ?? false)
            ? n!.body!
            : (orderNumber.isNotEmpty ? 'Pesanan $orderNumber diterima driver' : 'Pesanan diterima driver');
        if (ctx != null) {
          showDialog<void>(
            context: ctx,
            builder: (dctx) => AlertDialog(
              title: Text(n?.title ?? 'Driver Menerima Pesanan'),
              content: Text(body),
              actions: [
                TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Tutup')),
                TextButton(
                  onPressed: () {
                    Navigator.of(dctx).pop();
                    final id = data['order_id'] ?? data['orderId'] ?? '';
                    if (id.toString().isNotEmpty) {
                      try {
                        GoRouter.of(rootNavigatorKey.currentContext!).go('/kofood/tracking/$id');
                      } catch (_) {}
                    }
                  },
                  child: const Text('Lihat'),
                ),
              ],
            ),
          );
        } else if (n != null) {
          NotificationService.show(n.title ?? 'Driver Menerima Pesanan', body);
        }
      } else if (n != null) {
        NotificationService.show(n.title ?? 'Notifikasi', n.body ?? '');
      }
    });
  } catch (_) {}
  try {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final data = initial.data;
      final type = '${data['type'] ?? ''}';
      if (type == 'kofood_driver_accepted' || type == 'kofood_order_new') {
        final id = data['order_id'] ?? data['orderId'] ?? data['orderID'];
        if (id != null && id.toString().isNotEmpty) {
          _pendingRouteAfterLaunch = '/kofood/tracking/$id';
        }
      }
    }
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final data = message.data;
      final type = '${data['type'] ?? ''}';
      if (type == 'kofood_driver_accepted' || type == 'kofood_order_new') {
        final id = data['order_id'] ?? data['orderId'] ?? data['orderID'];
        if (id != null && id.toString().isNotEmpty) {
          try {
            GoRouter.of(rootNavigatorKey.currentContext!).go('/kofood/tracking/$id');
          } catch (_) {
            _pendingRouteAfterLaunch = '/kofood/tracking/$id';
          }
        }
      }
    });
  } catch (_) {}
  try {
    try {
      final kopId = p.getString('koperasi_id') ?? '1';
      final dio = Dio(BaseOptions(baseUrl: RuntimeConfig.baseUrl, headers: {
        'Accept': 'application/json',
        'X-Koperasi-Id': kopId,
      }));
      final res = await dio.get('/api/v1/public-config');
      final data = Map<String, dynamic>.from(res.data ?? {});
      final mapsKey = '${data['maps_api_key'] ?? ''}';
      final onesignal = '${data['onesignal_app_id'] ?? ''}';
      if (mapsKey.isNotEmpty) {
        RuntimeConfig.mapsApiKey = mapsKey;
      }
      if (onesignal.isNotEmpty) {
        RuntimeConfig.oneSignalAppId = onesignal;
      }
    } catch (_) {}
  } catch (_) {}
  runApp(const ProviderScope(child: KomeraApp()));
  if (_pendingRouteAfterLaunch != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = rootNavigatorKey.currentContext;
      final route = _pendingRouteAfterLaunch;
      _pendingRouteAfterLaunch = null;
      if (ctx != null && route != null) {
        try {
          GoRouter.of(ctx).go(route);
        } catch (_) {}
      }
    });
  }
}

class KomeraApp extends ConsumerWidget {
  const KomeraApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: buildKomeraTheme(),
      routerConfig: router,
    );
  }
}
