// lib/post_login/ui/wishlist_screen.dart
import 'package:flutter/material.dart';
import '../../../widgets/bottom_nav.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      appBar: AppBar(title: const Text('Wishlist')),
      body: const Center(child: Text('Halaman Wishlist (static)')),
    );
  }
}
