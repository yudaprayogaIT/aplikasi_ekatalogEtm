// lib/features/product/ui/product_detail_page.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ekatalog_etm/models/product.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedThumbnail = 0;
  Timer? _timer;
  final Duration _rotateDuration = const Duration(seconds: 3);
  final Duration _animDuration = const Duration(milliseconds: 380);

  @override
  void initState() {
    super.initState();
    _startAutoRotate();
  }

  void _startAutoRotate() {
    _timer?.cancel();
    if (widget.product.colors.length > 1) {
      _timer = Timer.periodic(_rotateDuration, (_) {
        setState(() {
          _selectedThumbnail = (_selectedThumbnail + 1) % widget.product.colors.length;
        });
      });
    }
  }

  void _restartAutoRotate() {
    _timer?.cancel();
    Future.delayed(const Duration(milliseconds: 400), _startAutoRotate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onThumbnailTap(int idx) {
    setState(() {
      _selectedThumbnail = idx;
    });
    _restartAutoRotate();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final thumbs = p.colors.map((c) => c.thumbnail).toList();

    const horizontalPadding = 20.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxAvailableWidth = screenWidth - (horizontalPadding * 2);
    final imageSize = math.min(370.0, math.max(0.0, maxAvailableWidth));

    final mainImage = thumbs.isNotEmpty ? thumbs[_selectedThumbnail] : null;

    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFFB11F23), title: const Text('Lihat Detail'), leading: const BackButton(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Animated main image (slide horizontal)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  color: Colors.grey[200],
                  child: AnimatedSwitcher(
                    duration: _animDuration,
                    transitionBuilder: (child, animation) {
                      final offsetAnim = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(animation);
                      return SlideTransition(position: offsetAnim, child: FadeTransition(opacity: animation, child: child));
                    },
                    child: mainImage != null
                        ? Image.asset(
                            mainImage,
                            key: ValueKey(mainImage),
                            fit: BoxFit.cover,
                            width: imageSize,
                            height: imageSize,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 80)),
                          )
                        : const Center(key: ValueKey('no_image'), child: Icon(Icons.image, size: 120, color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Thumbnails horizontal
          if (thumbs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: thumbs.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final isSelected = idx == _selectedThumbnail;
                    return GestureDetector(
                      onTap: () => _onThumbnailTap(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 100 : 92,
                        height: isSelected ? 100 : 92,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? Colors.black87 : Colors.grey.shade300, width: isSelected ? 2 : 1),
                          color: Colors.grey[100],
                          boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))] : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            thumbs[idx],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 16),

          Padding(padding: const EdgeInsets.symmetric(horizontal: horizontalPadding), child: const Text('Pilih Warna', style: TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(p.colors.length, (i) {
                final c = p.colors[i];
                final selected = i == _selectedThumbnail;
                return GestureDetector(
                  onTap: () => _onThumbnailTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.yellow[700] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? Colors.black87 : Colors.grey.shade300),
                    ),
                    child: Text(c.name, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 12),

          Padding(padding: const EdgeInsets.symmetric(horizontal: horizontalPadding), child: Text(p.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: horizontalPadding), child: Text('Kode: ${p.colors.isNotEmpty ? p.colors[_selectedThumbnail].sku : p.baseCode}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.symmetric(horizontal: horizontalPadding), child: const Text('Detail Produk', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 6),
          Padding(padding: const EdgeInsets.symmetric(horizontal: horizontalPadding), child: Text(p.detail, style: const TextStyle(height: 1.4), textAlign: TextAlign.left)),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tambahkan ke keranjang: ${p.title} (${p.colors.isNotEmpty ? p.colors[_selectedThumbnail].sku : p.baseCode})')));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB11F23)),
                child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Tambah ke Keranjang', style: TextStyle(color: Colors.white))),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
