// lib/features/product/ui/product_list_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ekatalog_etm/models/product.dart';
import 'package:ekatalog_etm/features/product/widgets/product_card.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  final String branchFilter;

  const ProductListPage({Key? key, this.branchFilter = ''}) : super(key: key);

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final List<Product> _allProducts = [];
  final List<Product> _items = [];
  final Map<int, bool> _favorites = {};
  final ScrollController _scrollController = ScrollController();
  bool _loadingMore = false;
  bool _hasMore = true;

  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadProductsJson().then((_) => _appendItems());
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadProductsJson() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/products.json');
      final List<dynamic> arr = jsonDecode(jsonStr) as List<dynamic>;
      final all = arr.map((m) => Product.fromMap(m as Map<String, dynamic>)).toList();
      final filtered = all.where((p) => p.availableInBranch(widget.branchFilter)).toList();
      _allProducts.clear();
      _allProducts.addAll(filtered);
      setState(() {});
    } catch (e) {
      debugPrint('Error load products.json (list): $e');
      setState(() => _allProducts.clear());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_loadingMore && _hasMore && _scrollController.position.pixels >= (_scrollController.position.maxScrollExtent - 200)) {
      _appendItems();
    }
  }

  void _appendItems() async {
    if (_loadingMore) return;
    if (_items.length >= _allProducts.length) {
      setState(() => _hasMore = false);
      return;
    }

    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final start = _items.length;
    final nextCount = ((_items.length + _pageSize) <= _allProducts.length) ? _pageSize : (_allProducts.length - _items.length);
    final newItems = _allProducts.sublist(start, start + nextCount);

    setState(() {
      _items.addAll(newItems);
      _loadingMore = false;
      if (_items.length >= _allProducts.length) _hasMore = false;
    });
  }

  void _onFavoriteChanged(int productId, bool fav) {
    setState(() => _favorites[productId] = fav);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.branchFilter.isEmpty ? 'Semua Produk' : 'Produk - ${widget.branchFilter}';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: const Color(0xFFB11F23), title: Text(title), leading: const BackButton(color: Colors.white)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _items.isEmpty
            ? const Center(child: Text('Tidak ada produk'))
            : Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      controller: _scrollController,
                      itemCount: _items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: productCardHeight, // gunakan konstanta tinggi dari ProductCard
                      ),
                      itemBuilder: (context, idx) {
                        final p = _items[idx];
                        return ProductCard(
                          product: p,
                          isFavorite: _favorites[p.id] ?? false,
                          onFavoriteChanged: _onFavoriteChanged,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: p))),
                        );
                      },
                    ),
                  ),
                  if (_loadingMore) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator(strokeWidth: 2)),
                  if (!_hasMore && !_loadingMore) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('Semua produk dimuat', style: TextStyle(color: Colors.grey.shade600))),
                ],
              ),
      ),
    );
  }
}
