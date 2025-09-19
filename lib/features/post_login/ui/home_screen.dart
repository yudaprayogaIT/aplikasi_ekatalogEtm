// lib/features/post_login/ui/home_screen.dart
import 'package:flutter/material.dart';
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
  // menyimpan status favorite tiap produk berdasar product.id
  final Map<int, bool> _favorites = {};

  // gambar dan sample product (pakai same assets names seperti ProductListPage)
  final List<String> images = [
    'assets/images/produk/item1.png',
    'assets/images/produk/item2.png',
    'assets/images/produk/item3.png',
    'assets/images/produk/item4.png',
  ];

  late final List<Product> _sampleProducts;

  @override
  void initState() {
    super.initState();
    // buat sample products (6 items) — setiap product membawa imageAsset
    _sampleProducts = List.generate(6, (i) {
      final id = i;
      final image = images.isNotEmpty ? images[id % images.length] : null;
      return Product(id: id, title: 'Lemari UPC #${id + 1}', imageAsset: image);
    });
  }

  void _onFavoriteChanged(int productId, bool fav) {
    setState(() {
      _favorites[productId] = fav;
    });
  }

  // small card tetap statis
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

    // kalkulasi padding bawah dinamis supaya tidak terjadi overflow karena BottomNavigationBar
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

              // large image placeholder
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

              // small cards
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

              // company card
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
                              Navigator.pushNamed(
                                context,
                                '/home',
                              );
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

              // Produk Baru header
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

              // horizontal product list: tinggi 218, gap 25
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
