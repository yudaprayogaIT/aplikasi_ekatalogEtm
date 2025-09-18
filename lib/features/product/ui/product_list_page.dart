// lib/features/product/ui/product_list_page.dart
import 'package:flutter/material.dart';
import '../../../models/product.dart'; // sesuaikan path bila perlu
import '../widgets/product_card.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final List<Product> _items = [];
  final Map<int, bool> _favorites = {};
  final ScrollController _scrollController = ScrollController();
  bool _loadingMore = false;
  bool _hasMore = true;

  static const int _pageSize = 10;
  static const int _maxItems = 50; // simulasi total produk

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitial() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _appendItems();
  }

  void _onScroll() {
    if (!_loadingMore &&
        _hasMore &&
        _scrollController.position.pixels >= (_scrollController.position.maxScrollExtent - 200)) {
      _appendItems();
    }
  }

  void _appendItems() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);

    await Future.delayed(const Duration(milliseconds: 600)); // simulasi network

    final start = _items.length;
    final nextCount = (_items.length + _pageSize) <= _maxItems ? _pageSize : (_maxItems - _items.length);

    if (nextCount <= 0) {
      setState(() {
        _hasMore = false;
        _loadingMore = false;
      });
      return;
    }

    final newItems = List.generate(nextCount, (i) {
      final id = start + i;
      return Product(id: id, title: 'Lemari UPC #${id + 1}', imageAsset: null);
    });

    setState(() {
      _items.addAll(newItems);
      _loadingMore = false;
      if (_items.length >= _maxItems) _hasMore = false;
    });
  }

  void _onFavoriteChanged(int productId, bool fav) {
    setState(() {
      _favorites[productId] = fav;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB11F23),
        title: const Text('Produk Baru'),
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                itemCount: _items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 160 / 218, // menjaga ukuran card sama seperti home
                ),
                itemBuilder: (context, idx) {
                  final p = _items[idx];
                  return ProductCard(
                    product: p,
                    isFavorite: _favorites[p.id] ?? false,
                    onFavoriteChanged: _onFavoriteChanged,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)));
                    },
                  );
                },
              ),
            ),

            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),

            if (!_hasMore && !_loadingMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text('Semua produk dimuat', style: TextStyle(color: Colors.grey.shade600)),
              ),
          ],
        ),
      ),
    );
  }
}
