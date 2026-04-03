import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ProfileScreen(), // "You" tab
    const CartScreen(),
    const CategoriesScreen(), // "Menu" tab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(CupertinoIcons.home, 'Home', 0),
            _buildNavItem(CupertinoIcons.person, 'You', 1),
            _buildNavItem(CupertinoIcons.cart, 'Cart', 2),
            _buildNavItem(Icons.menu, 'Menu', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF008296) : Colors.black87; // Amazon active cyan

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top active bar animation
            Positioned(
              top: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                width: isSelected ? 40 : 0,
                decoration: BoxDecoration(
                  color: const Color(0xFF008296),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
            
            // Icon and Label
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 4),
                AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: color,
                    fontSize: isSelected ? 11 : 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
