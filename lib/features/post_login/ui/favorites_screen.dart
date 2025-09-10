// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import '../../../widgets/bottom_nav.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      appBar: AppBar(title: const Text('Favorit')),
      body: const Center(child: Text('Halaman Favorit (static)')),
    );
  }
}
