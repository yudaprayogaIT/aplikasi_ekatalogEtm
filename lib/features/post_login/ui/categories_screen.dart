// lib/features/post_login/ui/categories_screen.dart
// import 'dart:json' as json; // jika rootBundle.loadString mengembalikan string json, ini opsional
import 'dart:convert';
import 'package:ekatalog_etm/features/product/ui/product_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../widgets/bottom_nav.dart';

class Category {
  final String name;
  final String tipe;
  final String image;

  Category({required this.name, required this.tipe, required this.image});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        name: json['name'] as String,
        tipe: json['tipe'] as String,
        image: json['image'] as String,
      );
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with TickerProviderStateMixin {
  late Future<List<Category>> _futureCategories;

  // which tipe is expanded; null = none
  String? _expandedTipe;

  @override
  void initState() {
    super.initState();
    _futureCategories = _loadCategories();
  }

  Future<List<Category>> _loadCategories() async {
    final jsonString = await rootBundle.loadString('assets/data/categories.json');
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded.map((e) => Category.fromJson(e)).toList();
  }

  String _shortTitleForTipe(String tipe) {
    final l = tipe.toLowerCase();
    if (l.contains('material')) return 'Material';
    if (l.contains('furniture')) return 'Furniture';
    // fallback: take first word capitalized
    return tipe.split(' ').first.capitalize();
  }

  void _toggleExpand(String tipe) {
    setState(() {
      if (_expandedTipe == tipe) _expandedTipe = null;
      else _expandedTipe = tipe;
    });
  }

  void _openProductList(Category cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListPage(filterCategory: cat.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB11F23),
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Kategori',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Category>>(
          future: _futureCategories,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
              return const Center(child: Text('Belum ada kategori.'));
            }

            // group by tipe
            final Map<String, List<Category>> grouped = {};
            for (var c in categories) {
              grouped.putIfAbsent(c.tipe, () => []).add(c);
            }

            // ensure ordered: Material first (if exists), Furniture next, then others
            final List<String> orderedTipes = [];
            if (grouped.keys.any((k) => k.toLowerCase().contains('material'))) {
              final k = grouped.keys.firstWhere((k) => k.toLowerCase().contains('material'));
              orderedTipes.add(k);
            }
            if (grouped.keys.any((k) => k.toLowerCase().contains('furniture'))) {
              final k = grouped.keys.firstWhere((k) => k.toLowerCase().contains('furniture'));
              orderedTipes.add(k);
            }
            for (var k in grouped.keys) {
              if (!orderedTipes.contains(k)) orderedTipes.add(k);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                children: orderedTipes.map((tipe) {
                  final list = grouped[tipe]!;
                  final isExpanded = _expandedTipe == tipe;

                  // choose the widget (collapsed horizontal list OR expanded grid)
                  final Widget content = isExpanded
                      ? Container(
                          key: ValueKey('expanded-$tipe'),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: list.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.68,
                            ),
                            itemBuilder: (context, index) {
                              final cat = list[index];
                              return GestureDetector(
                                onTap: () => _openProductList(cat),
                                child: _CategoryTile(category: cat),
                              );
                            },
                          ),
                        )
                      : SizedBox(
                          key: ValueKey('collapsed-$tipe'),
                          height: 170,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final cat = list[index];
                              return _CategoryTile(
                                category: cat,
                                width: 120,
                                onTap: () => _openProductList(cat),
                              );
                            },
                          ),
                        );

                  // Wrap with AnimatedSize + AnimatedSwitcher for smooth height + crossfade/slide
                  final animated = ClipRect(
                    // ClipRect prevents overflow during size transition
                    child: AnimatedSize(
                      key: ValueKey('size-$tipe'),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeInOut,
                      // removed vsync parameter to support SDKs that don't accept it
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 60),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          // Slide from slightly above when expanding, and fade
                          final offsetAnim = Tween<Offset>(
                            begin: Offset(0, isExpanded ? -0.02 : 0.0),
                            end: Offset.zero,
                          ).animate(animation);

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: offsetAnim, child: child),
                          );
                        },
                        // `content` has a unique key depending on expanded/collapsed,
                        // so AnimatedSwitcher will animate between them
                        child: content,
                      ),
                    ),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header row: title + lihat semua
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _shortTitleForTipe(tipe),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _toggleExpand(tipe),
                              child: Text(
                                isExpanded ? 'Sembunyikan' : 'Lihat semua',
                                style: TextStyle(
                                  color: const Color(0xFFB11F23),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // animated content
                      animated,

                      const SizedBox(height: 18),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Modified category tile: gambar + label jadi satu (label overlay di bawah gambar)
class _CategoryTile extends StatelessWidget {
  final Category category;
  final double? width;
  final VoidCallback? onTap;

  const _CategoryTile({
    required this.category,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // fixed height that matches ratio used in grids (so overlay looks consistent)
    final tileWidth = width ?? double.infinity;
    final tileHeight = width != null ? (width! / 0.68) : 180.0;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: tileWidth,
        height: tileHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // image background (covers full card)
            if (category.image.isNotEmpty)
              Image.asset(
                category.image,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image)),
                ),
              )
            else
              Container(color: Colors.grey[200]),

            // bottom red label overlay with rounded bottom corners
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFB11F23),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // subtle gradient above label for readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 50,
              height: 36,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return SizedBox(
        width: width,
        child: GestureDetector(
          onTap: onTap,
          child: card,
        ),
      );
    } else {
      return SizedBox(width: width, child: card);
    }
  }
}

// extension helper untuk capitalize (fallback)
extension _Cap on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
