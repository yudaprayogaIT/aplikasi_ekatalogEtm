// lib/models/product.dart
class ProductColor {
  final String name;
  final String sku;
  final String thumbnail;
  final bool isDefault;

  ProductColor({
    required this.name,
    required this.sku,
    required this.thumbnail,
    this.isDefault = false,
  });

  factory ProductColor.fromMap(Map<String, dynamic> m) {
    return ProductColor(
      name: (m['name'] ?? '') as String,
      sku: (m['sku'] ?? '') as String,
      thumbnail: (m['thumbnail'] ?? '') as String,
      isDefault: (m['is_default'] is bool) ? m['is_default'] as bool : false,
    );
  }
}

class Product {
  final int id;
  final String title;
  final String category;
  final String subCategory;
  final String detail;
  final List<ProductColor> colors;
  final List<String> branches;
  final String tipe;

  Product({
    required this.id,
    required this.title,
    required this.category,
    required this.subCategory,
    required this.detail,
    required this.colors,
    required this.branches,
    required this.tipe,
  });

  factory Product.fromMap(Map<String, dynamic> m) {
    final colorsList = <ProductColor>[];
    if (m['colors'] is List) {
      for (var c in (m['colors'] as List)) {
        if (c is Map) {
          colorsList.add(ProductColor.fromMap(Map<String, dynamic>.from(c)));
        }
      }
    }
    List<String> branches = [];
    if (m['branches'] is List) {
      for (var b in (m['branches'] as List)) {
        if (b is String) branches.add(b);
      }
    }

    return Product(
      id: (m['id'] is int) ? m['id'] as int : int.tryParse('${m['id']}') ?? 0,
      title: m['title'] ?? '',
      category: m['category'] ?? '',
      subCategory: m['sub_category'] ?? '',
      detail: m['detail'] ?? '',
      colors: colorsList,
      branches: branches,
      tipe: m['tipe'] ?? '',
    );
  }
}
