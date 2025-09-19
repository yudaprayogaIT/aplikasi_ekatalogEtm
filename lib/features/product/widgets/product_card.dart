// lib/features/product/widgets/product_card.dart
import 'package:flutter/material.dart';
import '../../../models/product.dart';

typedef FavoriteCallback = void Function(int productId, bool isFavorite);

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isFavorite;
  final FavoriteCallback onFavoriteChanged;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _anim = false;

  void _onFavPressed() {
    final newVal = !widget.isFavorite;
    setState(() => _anim = true);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() => _anim = false);
      widget.onFavoriteChanged(widget.product.id, newVal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFav = widget.isFavorite;

    return SizedBox(
      width: 160,
      height: 200,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==== Bagian gambar ====
              Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: widget.product.imageAsset != null
                        ? Image.asset(
                            widget.product.imageAsset!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                          ),
                  ),
                  // favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedScale(
                      scale: _anim ? 1.25 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isFav ? Colors.red : Colors.black87,
                          ),
                          onPressed: _onFavPressed,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ==== Bagian footer (judul + lihat + arrow) ====
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.product.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                fontFamily: 'poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Lihat',
                              style: TextStyle(
                                color: const Color(0xffB11F23),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Lato',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_forward_sharp, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
