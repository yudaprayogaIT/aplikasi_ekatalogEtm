// // lib/features/post_login/ui/home_screen.dart
// import 'package:flutter/material.dart';
// import '../../../widgets/bottom_nav.dart';
// import '../../../widgets/profile_header.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // menyimpan status favorite tiap produk berdasar index
//   final Map<int, bool> _favorites = {};

//   // small card tetap statis
//   Widget _smallCard(String title, {String subtitle = '', Widget? leading}) {
//     return SizedBox(
//       width: 189,
//       height: 72,
//       child: Card(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: Center(
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               // pastikan baris mulai dari kiri sehingga teks akan sejajar kiri
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 if (leading != null)
//                   SizedBox(
//                     width: 40,
//                     height: 40,
//                     child: ClipOval(child: leading),
//                   )
//                 else
//                   const SizedBox(
//                     width: 40,
//                     height: 40,
//                     child: CircleAvatar(
//                       backgroundColor: Color(0xFFFDD100),
//                       child: Icon(
//                         Icons.card_giftcard,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 const SizedBox(width: 12),
//                 // penting: crossAxisAlignment.start supaya title & subtitle rata kiri
//                 Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontFamily: 'poppins',
//                         fontSize: 14,
//                       ),
//                     ),
//                     if (subtitle.isNotEmpty)
//                       Text(
//                         subtitle,
//                         style: const TextStyle(
//                           color: Color(0xCE000000),
//                           fontSize: 12,
//                         ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // product card: fixed size 160 x 218, menerima index untuk favorite toggle
//   Widget _productCard(int index, String title) {
//   final isFav = _favorites[index] ?? false;

//   return SizedBox(
//     width: 160,
//     height: 218, // total yang diinginkan
//     child: GestureDetector(
//       onTap: () {
//         Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetail(title: title)));
//       },
//       child: Card(
//         margin: EdgeInsets.zero, // penting agar tidak ada ekstra ruang dari Card
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 1.5,
//         clipBehavior: Clip.hardEdge,
//         child: Stack(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Gambar fixed 160
//                 SizedBox(
//                   height: 160,
//                   child: Container(
//                     color: Colors.grey[200],
//                     child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
//                   ),
//                 ),

//                 // Footer fixed 58 (tanpa padding vertikal)
//                 SizedBox(
//                   height: 58,
//                   child: Container(
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       // bottom radius tetap agar sesuai desain
//                       borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
//                     ),
//                     // hanya padding horizontal supaya tidak menambah tinggi
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     child: Row(
//                       children: [
//                         // Judul + 'Lihat' di kiri, gunakan FittedBox agar tidak memicu line-height besar
//                         Expanded(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               // Bungkus dengan FittedBox untuk mencegah textScale menggulung tinggi
//                               FittedBox(
//                                 fit: BoxFit.scaleDown,
//                                 alignment: Alignment.centerLeft,
//                                 child: Text(
//                                   title,
//                                   style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'poppins'),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                               FittedBox(
//                                 fit: BoxFit.scaleDown,
//                                 alignment: Alignment.centerLeft,
//                                 child: Text(
//                                   'Lihat',
//                                   style: TextStyle(color: Color(0xffB11F23), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Lato'),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         const SizedBox(width: 8),

//                         // tombol chevron kecil (kotak)
//                         Container(
//                           width: 34,
//                           height: 34,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.grey.shade300),
//                             boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
//                           ),
//                           child: const Center(child: Icon(Icons.arrow_forward_sharp, size: 20)),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             // ikon favorite di pojok kanan atas (di atas gambar)
//             Positioned(
//               top: 8,
//               right: 8,
//               child: Container(
//                 width: 34,
//                 height: 34,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.95),
//                   shape: BoxShape.circle,
//                   boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
//                 ),
//                 child: IconButton(
//                   padding: EdgeInsets.zero,
//                   icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, size: 18, color: isFav ? Colors.red : Colors.black87),
//                   onPressed: () {
//                     setState(() {
//                       _favorites[index] = !isFav;
//                     });
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }

//   @override
//   Widget build(BuildContext context) {
//     const primaryColor = Color(0xFFB11F23);

//     // kalkulasi padding bawah dinamis supaya tidak terjadi overflow karena BottomNavigationBar
//     final bottomInset = MediaQuery.of(context).viewPadding.bottom;
//     final bottomPadding = bottomInset + kBottomNavigationBarHeight + 16;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F8),
//       bottomNavigationBar: const BottomNavBar(currentIndex: 0),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.only(
//             left: 14,
//             right: 14,
//             top: 12,
//             bottom: bottomPadding,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               ProfileHeader(
//                 onTapProfile: () {
//                   Navigator.pushNamed(context, '/profile');
//                 },
//               ),

//               const SizedBox(height: 12),

//               // large image placeholder
//               Container(
//                 height: 240,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Center(
//                   child: Icon(Icons.image, size: 60, color: Colors.grey),
//                 ),
//               ),

//               const SizedBox(height: 12),

//               // two small cards — side by side (scroll horizontal bila sempit)
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: [
//                     _smallCard(
//                       'Program',
//                       subtitle: 'Loyalty',
//                       leading: Image.asset(
//                         'assets/images/iconProgram.png',
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     _smallCard(
//                       'Eka Poin',
//                       subtitle: '30000',
//                       leading: Image.asset(
//                         'assets/images/iconPoin.png',
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 12),

//               // company card
//               Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(14.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Ekatunggal Tunas Mandiri',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontFamily: 'poppins',
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on,
//                             size: 16,
//                             color: primaryColor,
//                           ),
//                           const SizedBox(width: 4),
//                           const Text(
//                             'Bogor',
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontFamily: 'lato',
//                               fontSize: 12,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: SizedBox(
//                           width: 89,
//                           height: 36,
//                           child: ElevatedButton(
//                             onPressed: () {
//                               Navigator.pushNamed(
//                                 context,
//                                 '/home',
//                               ); // ganti sesuai rute
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: primaryColor,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               padding: EdgeInsets.zero,
//                             ),
//                             child: const Text(
//                               'Lihat Produk',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontFamily: 'lato',
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 18),

//               // Produk Baru header
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Produk Baru',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: primaryColor,
//                       fontFamily: 'poppins',
//                       fontSize: 14,
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: () {},
//                     child: const Text(
//                       'Lihat Semua',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 12,
//                         fontFamily: 'poppins',
//                         color: Color.fromARGB(99, 0, 0, 0),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 8),

//               // horizontal product list: tinggi 218, gap 25
//               SizedBox(
//                 height: 218,
//                 child: ListView(
//                   scrollDirection: Axis.horizontal,
//                   children: [
//                     _productCard(0, 'Lemari UPC'),
//                     const SizedBox(width: 25),
//                     _productCard(1, 'Lemari UPC'),
//                     const SizedBox(width: 25),
//                     _productCard(2, 'Lemari UPC'),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 28),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Simple product detail page (contoh)
// class ProductDetail extends StatelessWidget {
//   final String title;
//   const ProductDetail({super.key, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(title)),
//       body: Center(child: Text('Detail produk: $title')),
//     );
//   }
// }

// lib/features/post_login/ui/home_screen.dart
import 'package:ekatalog_etm/features/product/ui/product_list_page.dart';
import 'package:flutter/material.dart';
import '../../../widgets/bottom_nav.dart';
import '../../../widgets/profile_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // menyimpan status favorite tiap produk berdasar index
  final Map<int, bool> _favorites = {};
  // status animasi pop per produk
  final Map<int, bool> _favAnim = {};

  // sample produk untuk horizontal list (ganti dengan data real nanti)
  final List<String> _sampleTitles = List.generate(
    6,
    (i) => 'Lemari UPC #${i + 1}',
  );

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
            // pastikan baris mulai dari kiri sehingga teks akan sejajar kiri
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
              // penting: crossAxisAlignment.start supaya title & subtitle rata kiri
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

  // product card: fixed size 160 x 218, menerima index untuk favorite toggle
  Widget _productCard(int index, String title) {
    final isFav = _favorites[index] ?? false;
    final anim = _favAnim[index] ?? false;

    return SizedBox(
      width: 160,
      height: 218, // total yang diinginkan
      child: GestureDetector(
        onTap: () {
          // navigasi ke detail produk
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetail(title: title)),
          );
        },
        child: Card(
          margin:
              EdgeInsets.zero, // penting agar tidak ada ekstra ruang dari Card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1.5,
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gambar fixed 160
                  SizedBox(
                    height: 160,
                    child: Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),

                  // Footer fixed 58 (tanpa padding vertikal)
                  SizedBox(
                    height: 58,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        // bottom radius tetap agar sesuai desain
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      // hanya padding horizontal supaya tidak menambah tinggi
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          // Judul + 'Lihat' di kiri, gunakan FittedBox agar tidak memicu line-height besar
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bungkus dengan FittedBox untuk mencegah textScale menggulung tinggi
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      fontFamily: 'poppins',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Lihat',
                                    style: TextStyle(
                                      color: const Color(0xffB11F23),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Lato',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // tombol chevron kecil (kotak)
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

              // ikon favorite di pojok kanan atas (di atas gambar) dengan animasi pop
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedScale(
                  scale: anim ? 1.25 : 1.0,
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
                      onPressed: () {
                        // toggle favorite + play simple scale animation
                        setState(() {
                          _favorites[index] = !isFav;
                          _favAnim[index] = true;
                        });
                        // reset anim state shortly after
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted) {
                            setState(() {
                              _favAnim[index] = false;
                            });
                          }
                        });
                      },
                    ),
                  ),
                ),
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

              // large image placeholder (boleh disesuaikan height)
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

              // two small cards — side by side (scroll horizontal bila sempit)
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
                              ); // ganti sesuai rute
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
                  itemCount: _sampleTitles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 25),
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  itemBuilder: (context, idx) {
                    return _productCard(idx, _sampleTitles[idx]);
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

// Simple product detail page (contoh)
class ProductDetail extends StatelessWidget {
  final String title;
  const ProductDetail({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Detail produk: $title')),
    );
  }
}
