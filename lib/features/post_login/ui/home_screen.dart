// lib/features/post_login/ui/home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ekatalog_etm/features/product/ui/product_list_page.dart';
import 'package:ekatalog_etm/features/product/ui/product_detail_page.dart';
import 'package:ekatalog_etm/features/product/widgets/product_card.dart';
import 'package:ekatalog_etm/models/product.dart';
import '../../../widgets/bottom_nav.dart';
import '../../../widgets/profile_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<int, bool> _favorites = {};
  final List<Product> _sampleProducts = [];

  @override
  void initState() {
    super.initState();
    _loadSampleProducts();
  }

  Future<void> _loadSampleProducts() async {
    final jsonStr = await rootBundle.loadString('assets/data/products.json');
    final List<dynamic> arr = jsonDecode(jsonStr);
    final all = arr.map((m) => Product.fromMap(m as Map<String, dynamic>)).toList();
    setState(() {
      _sampleProducts.clear();
      _sampleProducts.addAll(all.take(6)); // ambil 6 pertama
    });
  }

  void _onFavoriteChanged(int productId, bool fav) {
    setState(() {
      _favorites[productId] = fav;
    });
  }

  Widget _smallCard(String title, {String subtitle = '', Widget? leading}) {
    return SizedBox(
      width: 189,
      height: 72,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null)
                SizedBox(width: 40, height: 40, child: ClipOval(child: leading))
              else
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircleAvatar(
                    backgroundColor: Color(0xFFFDD100),
                    child: Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'poppins',
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xCE000000),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFB11F23);

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = bottomInset + kBottomNavigationBarHeight + 16;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            top: 12,
            bottom: bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHeader(
                onTapProfile: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              const SizedBox(height: 12),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 60, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _smallCard(
                      'Program',
                      subtitle: 'Loyalty',
                      leading: Image.asset(
                        'assets/images/iconProgram.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _smallCard(
                      'Eka Poin',
                      subtitle: '30000',
                      leading: Image.asset(
                        'assets/images/iconPoin.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ekatunggal Tunas Mandiri',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'poppins',
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Bogor',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'lato',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 89,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/home');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Lihat Produk',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'lato',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Produk Baru',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontFamily: 'poppins',
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        fontFamily: 'poppins',
                        color: Color.fromARGB(99, 0, 0, 0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 218,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sampleProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 25),
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  itemBuilder: (context, idx) {
                    final p = _sampleProducts[idx];
                    return ProductCard(
                      product: p,
                      isFavorite: _favorites[p.id] ?? false,
                      onFavoriteChanged: (id, fav) => _onFavoriteChanged(id, fav),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
