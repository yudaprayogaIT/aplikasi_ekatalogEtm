// lib/features/product/ui/product_detail_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ekatalog_etm/models/product.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedThumbnail = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    const horizontalPadding = 20.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxAvailableWidth = screenWidth - (horizontalPadding * 2);
    final imageSize = math.min(370.0, math.max(0.0, maxAvailableWidth));

    final thumbs = p.colors.map((c) => c.thumbnail).toList();
    final mainImage = (thumbs.isNotEmpty && _selectedThumbnail >= 0 && _selectedThumbnail < thumbs.length)
        ? thumbs[_selectedThumbnail]
        : null;

    final selectedColor = (_selectedThumbnail >= 0 && _selectedThumbnail < p.colors.length) ? p.colors[_selectedThumbnail] : null;

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
                children: List.generate(p.colors.length, (i) {
                  final c = p.colors[i];
                  final selected = i == _selectedThumbnail;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedThumbnail = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? Colors.yellow[700] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selected ? Colors.black87 : Colors.grey.shade300),
                      ),
                      child: Text(
                        c.name,
                        style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),

            // Nama item + SKU
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Text(p.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 4),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Text('Kode: ${selectedColor?.sku ?? p.baseCode}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
              child: Text(
                p.detail,
                style: const TextStyle(height: 1.4),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tambahkan ke keranjang: ${p.title} (${selectedColor?.sku ?? p.baseCode})')),
                    );
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
