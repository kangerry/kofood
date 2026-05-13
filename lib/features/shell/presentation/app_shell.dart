import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/kofood/presentation/controllers/cart_provider.dart';
import '../../home/presentation/home_page.dart';
import '../../search/presentation/search_page.dart';
import '../../orders/presentation/orders_page.dart';
import '../../wallet/presentation/wallet_page.dart';
import '../../profile/presentation/profile_page.dart';
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
    List<Widget> pages;
    List<NavigationDestination> items;
    if (isAnggota) {
      pages = const [
        HomePage(),
        SearchPage(),
        OrdersPage(),
        WalletPage(),
        ProfilePage(),
      ];
      items = const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ];
    } else {
      pages = const [
        HomePage(),
        SearchPage(),
        OrdersPage(),
        ProfilePage(),
      ];
      items = const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ];
    }
    final currentIndex = _index >= pages.length ? pages.length - 1 : _index;
    return Scaffold(
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => setState(() => _index = i >= items.length ? items.length - 1 : i),
        destinations: items,
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
    final cart = ref.watch(cartProvider);
    final cartCount = cart.items.fold<int>(0, (p, e) => p + e.quantity);
    late final List<_TabItem> tabs;
    if (isAnggota) {
      tabs = [
        _TabItem(
          '/home',
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        ),
        _TabItem(
          '/search',
          const NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
        ),
        _TabItem(
          '/orders',
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
        ),
        _TabItem(
          '/wallet',
          const NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        ),
        _TabItem(
          '/profile',
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ),
      ];
    } else {
      tabs = [
        _TabItem(
          '/home',
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        ),
        _TabItem(
          '/search',
          const NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
        ),
        _TabItem(
          '/orders',
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
        ),
        _TabItem(
          '/profile',
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ),
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
      body: SafeArea(
        child: Stack(
          children: [
            child,
            if (isAnggota)
              Positioned(
                top: 8,
                right: 10,
                child: _CartOverlayButton(
                  count: cartCount,
                  onTap: () {
                    if (location.startsWith('/kofood/cart')) return;
                    context.go('/kofood/cart');
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (i) => context.go(tabs[i].path),
        destinations: [for (final t in tabs) t.destination],
      ),
    );
  }
}

class _TabItem {
  final String path;
  final NavigationDestination destination;
  _TabItem(this.path, this.destination);
}

class _CartOverlayButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _CartOverlayButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 22),
              if (count > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
