// lib/screens/account_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      appBar: AppBar(title: const Text('Akun')),
      body: const Center(child: Text('Halaman Akun (static)')),
    );
  }
}
