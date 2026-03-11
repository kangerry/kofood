import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../home/presentation/home_page.dart';
import '../../search/presentation/search_page.dart';
import '../../orders/presentation/orders_page.dart';
import '../../wallet/presentation/wallet_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../seller/presentation/seller_dashboard_page.dart';
import '../../seller/presentation/seller_center_page.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final isAnggota = auth.role == UserRole.anggota;
    final isMerchant = auth.role == UserRole.merchant;
    List<Widget> pages;
    List<BottomNavigationBarItem> items;
    if (isAnggota) {
      pages = const [
        HomePage(),
        SearchPage(),
        OrdersPage(),
        WalletPage(),
        ProfilePage(),
      ];
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ];
    } else if (isMerchant) {
      pages = const [
        SellerDashboardPage(),
        OrdersPage(),
        SellerCenterPage(),
        ProfilePage(),
      ];
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Seller'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ];
    } else {
      pages = const [
        HomePage(),
        SearchPage(),
        OrdersPage(),
        ProfilePage(),
      ];
      items = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ];
    }
    final currentIndex = _index >= pages.length ? pages.length - 1 : _index;
    return Scaffold(
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => _index = i >= items.length ? items.length - 1 : i),
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }
}

class ShellScaffold extends ConsumerWidget {
  final Widget child;
  final String location;
  const ShellScaffold({super.key, required this.child, required this.location});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isAnggota = auth.role == UserRole.anggota;
    final isMerchant = auth.role == UserRole.merchant;
    late final List<_TabItem> tabs;
    if (isAnggota) {
      tabs = [
        _TabItem('/kofood', const Icon(Icons.home_outlined), 'Home'),
        _TabItem('/search', const Icon(Icons.search_outlined), 'Search'),
        _TabItem('/orders', const Icon(Icons.receipt_long_outlined), 'Orders'),
        _TabItem('/wallet', const Icon(Icons.account_balance_wallet_outlined), 'Wallet'),
        _TabItem('/profile', const Icon(Icons.person_outline), 'Profile'),
      ];
    } else if (isMerchant) {
      tabs = [
        _TabItem('/kofood', const Icon(Icons.home_outlined), 'Home'),
        _TabItem('/search', const Icon(Icons.search_outlined), 'Search'),
        _TabItem('/orders', const Icon(Icons.receipt_long_outlined), 'Orders'),
        _TabItem('/seller/center', const Icon(Icons.storefront_outlined), 'Seller'),
        _TabItem('/profile', const Icon(Icons.person_outline), 'Profile'),
      ];
    } else {
      tabs = [
        _TabItem('/kofood', const Icon(Icons.home_outlined), 'Home'),
        _TabItem('/search', const Icon(Icons.search_outlined), 'Search'),
        _TabItem('/orders', const Icon(Icons.receipt_long_outlined), 'Orders'),
        _TabItem('/profile', const Icon(Icons.person_outline), 'Profile'),
      ];
    }
    int current = 0;
    for (var i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) {
        current = i;
        break;
      }
    }
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: current,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          final p = tabs[i].path;
          context.go(p);
        },
        items: [
          for (final t in tabs) BottomNavigationBarItem(icon: t.icon, label: t.label),
        ],
      ),
    );
  }
}

class _TabItem {
  final String path;
  final Icon icon;
  final String label;
  _TabItem(this.path, this.icon, this.label);
}
