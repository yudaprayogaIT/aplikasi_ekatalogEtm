// lib/models/product.dart
class Product {
  final int id;
  final String title;
  final String? imageAsset; // optional asset path

  Product({
    required this.id,
    required this.title,
    this.imageAsset,
  });
}
