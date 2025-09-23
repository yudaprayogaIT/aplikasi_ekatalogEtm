// lib/features/post_login/ui/home_screen.dart
import 'dart:convert';
import 'package:ekatalog_etm/features/product/ui/product_detail_page.dart';
import 'package:ekatalog_etm/features/product/ui/product_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ekatalog_etm/features/product/widgets/product_card.dart';
import 'package:ekatalog_etm/models/product.dart';
import '../../../widgets/bottom_nav.dart';
import '../../../widgets/profile_header.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';

const double productCardHeight = 210;

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
    try {
      final jsonStr = await rootBundle.loadString('assets/data/products.json');
      final List<dynamic> arr = jsonDecode(jsonStr);
      final all = arr
          .map((m) => Product.fromMap(m as Map<String, dynamic>))
          .toList();

      setState(() {
        _sampleProducts.clear();
        // ambil 6 pertama (produk baru) - ini menampilkan newest berdasarkan urutan JSON
        _sampleProducts.addAll(all.take(6));
      });
    } catch (e) {
      debugPrint('Error loading products.json: $e');
      setState(() {
        _sampleProducts.clear();
      });
    }
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
    final auth = Provider.of<AuthService>(context);
    // company title fallback ke teks statis jika tidak ada company di provider
    final daerah = auth.daerah ?? 'Ekatunggal Tunas Mandiri';

    // branch priority: branch table -> company.branch_name -> fallback 'Bogor'
    final branchName = auth.branch != null
        ? (auth.branch!['branch_name']?.toString() ?? '')
        : (auth.company != null
            ? (auth.company!['branch_name']?.toString() ?? auth.company!['company_name']?.toString() ?? '')
            : '');

    final primaryColor = const Color(0xFFB11F23);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = bottomInset + kBottomNavigationBarHeight + 12;

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
                onTapProfile: () => Navigator.pushNamed(context, '/profile'),
              ),
              const SizedBox(height: 12),
              Container(
                height: 210,
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
                      // judul (company / fallback)
                      Text(
                        branchName,
                        style: const TextStyle(
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
                          Text(
                            // tampilkan branchName atau fallback
                            daerah.isNotEmpty ? daerah : 'Bogor',
                            style: const TextStyle(
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
                          width: 110,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              // BUKA halaman filterable per-branch (tanpa bloc)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductListPage(
                                    mode: ProductListMode.filterable,
                                  ),
                                ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
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
                      // Lihat Semua -> buka halaman ALL PRODUCTS tanpa filter
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductListPage(
                            mode: ProductListMode.newProducts,
                          ),
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

              // HORIZONTAL CARDS -> tampilkan produk baru (statik gambar)
              SizedBox(
                height: productCardHeight, // gunakan konstanta agar konsisten
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sampleProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  itemBuilder: (context, idx) {
                    final p = _sampleProducts[idx];
                    return ProductCard(
                      product: p,
                      isFavorite: _favorites[p.id] ?? false,
                      onFavoriteChanged: (id, fav) => _onFavoriteChanged(id, fav),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(product: p),
                        ),
                      ),
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
