// lib/models/product.dart
class ProductColor {
  final String name;
  final String sku;
  final String thumbnail;

  ProductColor({required this.name, required this.sku, required this.thumbnail});

  factory ProductColor.fromJson(Map<String, dynamic> json) => ProductColor(
        name: json['name'] as String,
        sku: json['sku'] as String,
        thumbnail: json['thumbnail'] as String,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sku': sku,
        'thumbnail': thumbnail,
      };
}

class Product {
  final int id;
  final String title;
  final String baseCode;
  final String category;
  final String subCategory;
  final String detail;
  final List<ProductColor> colors;

  Product({
    required this.id,
    required this.title,
    required this.baseCode,
    required this.category,
    required this.subCategory,
    required this.detail,
    required this.colors,
  });

  factory Product.fromMap(Map<String, dynamic> m) {
    final List<dynamic> colorList = m['colors'] ?? [];
    return Product(
      id: m['id'] as int,
      title: m['title'] as String,
      baseCode: m['base_code'] as String,
      category: m['category'] as String,
      subCategory: m['sub_category'] as String,
      detail: m['detail'] as String,
      colors: colorList.map((c) => ProductColor.fromJson(c)).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'base_code': baseCode,
        'category': category,
        'sub_category': subCategory,
        'detail': detail,
        'colors': colors.map((c) => c.toJson()).toList(),
      };

  // helper: default color (first)
  ProductColor? get defaultColor => colors.isNotEmpty ? colors[0] : null;

  // find color by name, case-insensitive
  ProductColor? colorByName(String name) {
    try {
      return colors.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}
