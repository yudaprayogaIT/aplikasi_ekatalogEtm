// lib/features/product/ui/product_detail_page.dart
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

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB11F23),
        title: const Text('Lihat Detail'),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 260,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
              child: p.imageAsset != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(p.imageAsset!, fit: BoxFit.cover))
                  : const Center(child: Icon(Icons.image, size: 120, color: Colors.grey)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final isSelected = idx == _selectedThumbnail;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedThumbnail = idx),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.black87 : Colors.grey.shade300, width: isSelected ? 2 : 1),
                        color: Colors.grey[100],
                      ),
                      child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text('Pilih Warna', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
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
                    child: Text(c),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(p.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text('Detail Produk', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'Lemari ini mengandung nilai estetika bla.. bla.. bla. Deskripsi produk dapat diisi lebih lengkap di sini. Spesifikasi, ukuran, bahan, dan informasi lain dapat ditambahkan.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan ke keranjang')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB11F23)),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Tambah ke Keranjang', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
