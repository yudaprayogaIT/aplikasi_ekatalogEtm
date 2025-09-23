// lib/models/product.dart
class ProductColor {
  final String name;
  final String sku;
  final String thumbnail;

  ProductColor({
    required this.name,
    required this.sku,
    required this.thumbnail,
  });

  factory ProductColor.fromMap(Map<String, dynamic> m) {
    return ProductColor(
      name: (m['name'] ?? '') as String,
      sku: (m['sku'] ?? '') as String,
      thumbnail: (m['thumbnail'] ?? '') as String,
    );
  }
}

class Product {
  final int id;
  final String tipe; // new field
  final String title;
  final String baseCode;
  final String category;
  final String subCategory;
  final String detail;
  final List<ProductColor> colors;
  final List<String> branches; // support multi-branch

  Product({
    required this.id,
    required this.tipe,
    required this.title,
    required this.baseCode,
    required this.category,
    required this.subCategory,
    required this.detail,
    required this.colors,
    required this.branches,
  });

  factory Product.fromMap(Map<String, dynamic> m) {
    final colorsList = <ProductColor>[];
    if (m['colors'] is List) {
      for (var c in (m['colors'] as List)) {
        if (c is Map) {
          colorsList.add(ProductColor.fromMap(Map<String, dynamic>.from(c)));
        } else if (c is Map<String, dynamic>) {
          colorsList.add(ProductColor.fromMap(c));
        }
      }
    }

    List<String> branches = [];
    if (m['branches'] is List) {
      for (var b in (m['branches'] as List)) {
        if (b is String) branches.add(b);
      }
    } else if (m['branch'] is String) {
      branches = [(m['branch'] as String)];
    }

    return Product(
      id: (m['id'] is int) ? m['id'] as int : int.tryParse('${m['id']}') ?? 0,
      tipe: (m['tipe'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      baseCode: (m['base_code'] ?? '') as String,
      category: (m['category'] ?? '') as String,
      subCategory: (m['sub_category'] ?? m['subCategory'] ?? '') as String,
      detail: (m['detail'] ?? '') as String,
      colors: colorsList,
      branches: branches,
    );
  }

  /// check availability on branch (case-insensitive)
  bool availableInBranch(String branchFilter) {
    if (branchFilter.isEmpty) return true;
    for (var b in branches) {
      if (b.toLowerCase().trim() == branchFilter.toLowerCase().trim()) return true;
    }
    return false;
  }
}
