// lib/screens/categories_screen.dart
import 'package:flutter/material.dart';
import '../../../widgets/bottom_nav.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      appBar: AppBar(title: const Text('Kategori')),
      body: const Center(child: Text('Halaman Kategori (static)')),
    );
  }
}
