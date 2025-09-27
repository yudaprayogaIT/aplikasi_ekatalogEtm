// lib/widgets/bottom_nav.dart
import 'package:flutter/material.dart';


class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const BottomNavBar({Key? key, this.currentIndex = 0}) : super(key: key);

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.home, label: 'Home', route: '/home'),
    _NavItem(icon: Icons.grid_view, label: 'Kategori', route: '/categories'),
    _NavItem(icon: Icons.favorite_border, label: 'Wishlist', route: '/wishlist'),
    _NavItem(icon: Icons.person_outline, label: 'Akun', route: '/account'),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    final route = _items[index].route;
    // ganti ke route yang sesuai; pushReplacement supaya tidak menumpuk banyak route
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) => _onTap(context, i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFB11F23),
      unselectedItemColor: Colors.grey,
      items: _items
          .map((it) => BottomNavigationBarItem(
                icon: Icon(it.icon),
                label: it.label,
              ))
          .toList(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}
