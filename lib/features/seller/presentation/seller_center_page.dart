import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'product_list_page.dart';
import 'product_form_page.dart';
import 'seller_shop_edit_page.dart';

class SellerCenterPage extends StatelessWidget {
  const SellerCenterPage({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seller Center'),
          actions: [
            IconButton(
              tooltip: 'Edit Toko',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SellerShopEditPage()));
              },
            ),
            IconButton(
              tooltip: 'Opsi Produk',
              icon: const Icon(Icons.tune),
              onPressed: () => context.go('/seller/options'),
            ),
            IconButton(
              tooltip: 'Pencairan',
              icon: const Icon(Icons.account_balance_outlined),
              onPressed: () => context.go('/seller/settlement'),
            ),
            IconButton(
              tooltip: 'Marketplace',
              icon: const Icon(Icons.storefront_outlined),
              onPressed: () => context.go('/kofood'),
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(text: 'Produk'),
            Tab(text: 'Tambah'),
          ]),
        ),
        body: const TabBarView(
          children: [
            ProductListPage(),
            ProductFormPage(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SellerShopEditPage()));
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Toko'),
        ),
      ),
    );
  }
}
