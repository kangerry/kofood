import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/kofood/presentation/pages/merchant_list_page.dart';
import '../features/kofood/presentation/pages/merchant_detail_page.dart';
import '../features/kofood/presentation/pages/product_detail_page.dart';
import '../features/kofood/presentation/pages/cart_page.dart';
import '../features/kofood/presentation/pages/checkout_page.dart';
import '../features/kofood/presentation/pages/order_tracking_page.dart';
import '../features/kofood/presentation/pages/order_history_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/search/presentation/search_page.dart';
import '../features/orders/presentation/orders_page.dart';
import '../features/wallet/presentation/wallet_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/seller/presentation/seller_dashboard_page.dart';
import '../features/seller/presentation/seller_center_page.dart';
import '../features/seller/presentation/product_edit_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  final loggedIn = auth.isLoggedIn;
  final role = auth.role;
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: loggedIn ? '/kofood' : '/login',
    redirect: (ctx, st) {
      final p = st.uri.path;
      final loggingIn = p == '/login' || p == '/register';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/kofood';
      if (p.startsWith('/wallet') && role != UserRole.anggota) return '/kofood';
      // Seller routes diizinkan untuk anggota yang sudah login juga.
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (ctx, st) => const LoginPage()),
      GoRoute(path: '/register', builder: (ctx, st) => const RegisterPage()),
      GoRoute(path: '/settings', builder: (ctx, st) => const SettingsPage()),
      ShellRoute(
        builder: (ctx, st, child) => ShellScaffold(location: st.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (ctx, st) => const HomePage()),
          GoRoute(path: '/search', builder: (ctx, st) => const SearchPage()),
          GoRoute(path: '/orders', builder: (ctx, st) => const OrdersPage()),
          GoRoute(path: '/wallet', builder: (ctx, st) => const WalletPage()),
          GoRoute(path: '/profile', builder: (ctx, st) => const ProfilePage()),
          GoRoute(path: '/seller', builder: (ctx, st) => const SellerDashboardPage()),
          GoRoute(path: '/seller/center', builder: (ctx, st) => const SellerCenterPage()),
          GoRoute(
            path: '/seller/product/:id/edit',
            builder: (ctx, st) => ProductEditPage(productId: st.pathParameters['id']!),
          ),
          GoRoute(
            path: '/kofood',
            builder: (ctx, st) => const MerchantListPage(),
            routes: [
              GoRoute(
                path: 'merchant/:id',
                builder: (ctx, st) => MerchantDetailPage(merchantId: st.pathParameters['id']!),
              ),
              GoRoute(
                path: 'product/:id',
                builder: (ctx, st) => ProductDetailPage(productId: st.pathParameters['id']!),
              ),
              GoRoute(
                path: 'cart',
                builder: (ctx, st) => const CartPage(),
              ),
              GoRoute(
                path: 'checkout',
                builder: (ctx, st) => const CheckoutPage(),
              ),
              GoRoute(
                path: 'tracking/:orderId',
                builder: (ctx, st) => OrderTrackingPage(orderId: st.pathParameters['orderId']!),
              ),
              GoRoute(
                path: 'history',
                builder: (ctx, st) => const OrderHistoryPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
