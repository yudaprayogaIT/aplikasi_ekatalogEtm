// lib/features/product/ui/product_detail_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/product.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedThumbnail = 0;
  String _selectedColor = 'Putih';
  final List<String> _colors = ['Putih', 'Hitam', 'Biru', 'Coklat'];

  // sesuaikan nama file jika perlu (sama seperti di ProductListPage)
  final List<String> images = [
    'assets/images/produk/item1.png',
    'assets/images/produk/item2.png',
    'assets/images/produk/item3.png',
    'assets/images/produk/item4.png',
  ];

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    const horizontalPadding = 20.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxAvailableWidth = screenWidth - (horizontalPadding * 2);
    final imageSize = math.min(370.0, math.max(0.0, maxAvailableWidth));

    // build thumbnail list starting from product id to have consistent images per product
    final startIndex = images.isNotEmpty ? (p.id % images.length) : 0;
    final thumbs = images.isNotEmpty
        ? List.generate(images.length, (i) => images[(startIndex + i) % images.length])
        : <String>[];

    // determine which image should show in main view
    final mainImage = thumbs.isNotEmpty ? thumbs[_selectedThumbnail.clamp(0, thumbs.length - 1)] : p.imageAsset;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB11F23),
        title: const Text('Lihat Detail'),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar utama
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    color: Colors.grey[200],
                    child: mainImage != null
                        ? Image.asset(
                            mainImage,
                            fit: BoxFit.cover,
                            width: imageSize,
                            height: imageSize,
                          )
                        : const Center(child: Icon(Icons.image, size: 120, color: Colors.grey)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Thumbnails horizontal (sejajar kiri)
            if (thumbs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: thumbs.length,
                    padding: EdgeInsets.zero,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, idx) {
                      final isSelected = idx == _selectedThumbnail;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedThumbnail = idx),
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? Colors.black87 : Colors.grey.shade300, width: isSelected ? 2 : 1),
                            color: Colors.grey[100],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(thumbs[idx], fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Pilih Warna (label)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: const Text('Pilih Warna', style: TextStyle(fontWeight: FontWeight.w700)),
            ),

            const SizedBox(height: 8),

            // warna pilihan (Wrap)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((c) {
                  final selected = c == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? Colors.yellow[700] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selected ? Colors.black87 : Colors.grey.shade300),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Item Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: const Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 4),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Text(p.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 12),

            // Detail Produk
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: const Text('Detail Produk', style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: const Text(
                'Lemari ini mengandung nilai estetika bla.. bla.. bla. Deskripsi produk dapat diisi lebih lengkap di sini. Spesifikasi, ukuran, bahan, dan informasi lain dapat ditambahkan.',
                style: TextStyle(height: 1.4),
                textAlign: TextAlign.left,
              ),
            ),

            const SizedBox(height: 20),

            // Tombol tambah keranjang
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan ke keranjang')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB11F23)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Tambah ke Keranjang', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
