import 'package:flutter/material.dart';
import 'seller_shop_edit_page.dart';

class SellerDashboardPage extends StatelessWidget {
  const SellerDashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Edit Toko',
            icon: const Icon(Icons.edit_location_alt_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SellerShopEditPage())),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: const [
          _StatCard(title: 'Omzet', value: 'Rp 12.5jt', icon: Icons.paid_outlined),
          _StatCard(title: 'Pesanan', value: '128', icon: Icons.receipt_long_outlined),
          _StatCard(title: 'Produk', value: '42', icon: Icons.fastfood_outlined),
          _StatCard(title: 'Rating', value: '4.7', icon: Icons.star_outline),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SellerShopEditPage())),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit Toko'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}
