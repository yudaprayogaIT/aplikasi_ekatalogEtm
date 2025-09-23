// lib/features/product/ui/product_detail_page.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ekatalog_etm/models/product.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final Color accentYellow = const Color(0xFFFDD100);
final Color primaryColor = const Color(0xFFB11F23);

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedThumbnail = 0;
  Timer? _timer;
  final Duration _rotateDuration = const Duration(seconds: 3);
  final Duration _animDuration = const Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    // pilih index awal: first color with isDefault true, else 0
    final idx = widget.product.colors.indexWhere((c) => c.isDefault);
    _selectedThumbnail = idx >= 0 ? idx : 0;

    if (widget.product.colors.length > 1) {
      _timer = Timer.periodic(_rotateDuration, (_) {
        setState(() {
          _selectedThumbnail =
              (_selectedThumbnail + 1) % widget.product.colors.length;
        });
      });
    }
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
    // restart timer
    if (_timer != null) {
      _timer!.cancel();
      _timer = Timer.periodic(_rotateDuration, (_) {
        setState(() {
          _selectedThumbnail =
              (_selectedThumbnail + 1) % widget.product.colors.length;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final thumbs = p.colors.map((c) => c.thumbnail).toList();

    const horizontalPadding = 20.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxAvailableWidth = screenWidth - (horizontalPadding * 2);
    final imageSize = math.min(370.0, math.max(0.0, maxAvailableWidth));

    final selectedColor =
        (p.colors.isNotEmpty &&
            _selectedThumbnail >= 0 &&
            _selectedThumbnail < p.colors.length)
        ? p.colors[_selectedThumbnail]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lihat Detail",
          style: TextStyle(
            fontFamily: 'poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        leading: IconButton(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          icon: const Icon(FontAwesomeIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 80, // <--- tinggi AppBar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    color: Colors.grey[200],
                    child: thumbs.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.image,
                              size: 120,
                              color: Colors.grey,
                            ),
                          )
                        : AnimatedSwitcher(
                            duration: _animDuration,
                            transitionBuilder: (child, anim) {
                              final inAnim = Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(anim);
                              return SlideTransition(
                                position: inAnim,
                                child: FadeTransition(
                                  opacity: anim,
                                  child: child,
                                ),
                              );
                            },
                            child: Image.asset(
                              thumbs[_selectedThumbnail],
                              key: ValueKey<int>(_selectedThumbnail),
                              fit: BoxFit.cover,
                              width: imageSize,
                              height: imageSize,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, size: 80),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (thumbs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
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
                        onTap: () => _onThumbnailTap(idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: isSelected ? 100 : 92,
                          height: isSelected ? 100 : 92,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black87
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            color: isSelected ? accentYellow : Colors.grey[100],
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
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

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: const Text(
                'Pilih Warna',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'poppins',
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(p.colors.length, (i) {
                  final c = p.colors[i];
                  final selected = i == _selectedThumbnail;
                  return GestureDetector(
                    onTap: () => _onThumbnailTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? accentYellow : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c.name,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: Text(
                p.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'poppins',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: const Text(
                'Detail Produk',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(79, 0, 0, 0),
                  fontFamily: 'poppins',
                  fontSize: 12,
                ),
              ),
            ),

            // const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                thickness: 1, // ketebalan garis
                color: Colors.black26, // warna garis
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: Text(
                p.detail,
                style: const TextStyle(
                  height: 1.4,
                  fontFamily: 'poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 20),

            // Padding(
            //   padding: const EdgeInsets.symmetric(
            //     horizontal: horizontalPadding,
            //   ),
            //   child: SizedBox(
            //     width: double.infinity,
            //     child: ElevatedButton(
            //       onPressed: () {
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           SnackBar(
            //             content: Text(
            //               'Tambahkan ke keranjang: ${p.title} (${selectedColor?.sku})',
            //             ),
            //           ),
            //         );
            //       },
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: primaryColor,
            //       ),
            //       child: const Padding(
            //         padding: EdgeInsets.symmetric(vertical: 12),
            //         child: Text(
            //           'Tambah ke Keranjang',
            //           style: TextStyle(color: Colors.white),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
