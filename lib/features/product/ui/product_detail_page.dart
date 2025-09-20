// lib/features/product/ui/product_detail_page.dart
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ekatalog_etm/models/product.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedThumbnail = 0; // index untuk highlight thumbnail
  int _displayImageIndex = 0; // index gambar yang ditampilkan di AnimatedSwitcher

  final CarouselSliderController _carouselController = CarouselSliderController();

  bool _autoPlayEnabled = true;
  final Duration _autoInterval = const Duration(seconds: 2);
  final Duration _animDuration = const Duration(milliseconds: 600);

  bool _isAnimating = false; // block multiple animations

  @override
  void initState() {
    super.initState();
    _selectedThumbnail = 0;
    _displayImageIndex = 0;
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Ketika user mengetuk thumbnail:
  /// - segera nonaktifkan autoplay (rebuild options)
  /// - langsung jump ke halaman target pada carousel (tanpa animasi bertahap)
  /// - ubah _displayImageIndex sehingga AnimatedSwitcher melakukan transisi halus
  /// - setelah durasi anim, enable autoplay kembali
  Future<void> _onThumbnailTap(int idx) async {
    final thumbs = widget.product.colors.map((c) => c.thumbnail).toList();
    if (thumbs.isEmpty) return;
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _autoPlayEnabled = false;
    });

    // ubah display image terlebih dahulu supaya AnimatedSwitcher mulai transisi
    setState(() {
      _displayImageIndex = idx;
    });

    // sinkronkan posisi carousel: lakukan jump (jika tersedia) atau animateToPage dengan duration 0
    try {
      // prefer jumpToPage (instant), fallback ke animateToPage(Duration.zero)
      if (_carouselController.jumpToPage != null) {
        // jumpToPage is synchronous
        _carouselController.jumpToPage(idx);
      } else {
        await _carouselController.animateToPage(idx, duration: Duration.zero);
      }
    } catch (e) {
      // fallback: kalau method tidak tersedia, coba animateToPage biasa
      try {
        await _carouselController.animateToPage(idx, duration: const Duration(milliseconds: 50));
      } catch (_) {}
    }

    // tunggu durasi animasi visual agar transisi terasa smooth, lalu re-enable autoplay
    await Future.delayed(_animDuration + const Duration(milliseconds: 50));

    if (!mounted) return;

    setState(() {
      _selectedThumbnail = idx;
      _isAnimating = false;
      _autoPlayEnabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final thumbs = p.colors.map((c) => c.thumbnail).toList();

    final double horizontalPadding = 20.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxAvailableWidth = screenWidth - (horizontalPadding * 2);
    final double imageSize = math.min(370.0, math.max(0.0, maxAvailableWidth));

    final ProductColor? selectedColor = (p.colors.isNotEmpty && _selectedThumbnail >= 0 && _selectedThumbnail < p.colors.length)
        ? p.colors[_selectedThumbnail]
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB11F23),
        title: const Text('Lihat Detail'),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Carousel + AnimatedSwitcher overlay
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Carousel di background : bertanggung jawab untuk autoplay/infinite loop
                    Container(
                      width: imageSize,
                      height: imageSize,
                      color: Colors.grey[200],
                      child: CarouselSlider.builder(
                        carouselController: _carouselController,
                        itemCount: thumbs.isEmpty ? 1 : thumbs.length,
                        itemBuilder: (context, index, realIdx) {
                          if (thumbs.isEmpty) {
                            return const Center(child: Icon(Icons.image, size: 120, color: Colors.grey));
                          }
                          final img = thumbs[index];
                          return Image.asset(
                            img,
                            fit: BoxFit.cover,
                            width: imageSize,
                            height: imageSize,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 80)),
                          );
                        },
                        options: CarouselOptions(
                          height: imageSize,
                          viewportFraction: 1.0,
                          initialPage: _selectedThumbnail,
                          enableInfiniteScroll: thumbs.length > 1,
                          autoPlay: _autoPlayEnabled && thumbs.length > 1,
                          autoPlayInterval: _autoInterval,
                          autoPlayAnimationDuration: _animDuration,
                          autoPlayCurve: Curves.easeInOut,
                          enlargeCenterPage: false,
                          onPageChanged: (index, reason) {
                            // sinkronisasi index highlight; kalau tidak sedang animasi manual, update displayImage
                            setState(() {
                              _selectedThumbnail = index % (thumbs.isEmpty ? 1 : thumbs.length);
                            });
                            if (!_isAnimating) {
                              setState(() {
                                _displayImageIndex = _selectedThumbnail;
                              });
                            }
                          },
                          scrollDirection: Axis.horizontal,
                        ),
                      ),
                    ),

                    // AnimatedSwitcher overlay untuk cross-fade / slide effect ketika kita jump manual.
                    // Ini akan memberikan efek transisi halus meskipun carousel di bawah di-jump langsung.
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: true,
                        child: AnimatedSwitcher(
                          duration: _animDuration,
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            // kombinasikan fade + slight vertical slide
                            final offsetAnim = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation);
                            return SlideTransition(position: offsetAnim, child: FadeTransition(opacity: animation, child: child));
                          },
                          child: Container(
                            key: ValueKey<int>(_displayImageIndex),
                            width: imageSize,
                            height: imageSize,
                            color: Colors.transparent,
                            child: thumbs.isEmpty
                                ? const Center(child: Icon(Icons.image, size: 120, color: Colors.grey))
                                : Image.asset(
                                    thumbs[_displayImageIndex],
                                    fit: BoxFit.cover,
                                    width: imageSize,
                                    height: imageSize,
                                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 80)),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Thumbnails horizontal (highlight)
          if (thumbs.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                          boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))] : null,
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

          // Pilih Warna (buttons)
          Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding), child: const Text('Pilih Warna', style: TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(height: 8),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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

          Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding), child: Text(p.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          const SizedBox(height: 4),
          Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding), child: Text('Kode: ${selectedColor?.sku ?? p.baseCode}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          const SizedBox(height: 12),
          Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding), child: const Text('Detail Produk', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 6),
          Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding), child: Text(p.detail, style: const TextStyle(height: 1.4), textAlign: TextAlign.left)),
          const SizedBox(height: 20),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tambahkan ke keranjang: ${p.title} (${selectedColor?.sku ?? p.baseCode})')));
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

  ProductColor? get selectedColor {
    final p = widget.product;
    if (p.colors.isNotEmpty && _selectedThumbnail >= 0 && _selectedThumbnail < p.colors.length) {
      return p.colors[_selectedThumbnail];
    }
    return null;
  }
}
