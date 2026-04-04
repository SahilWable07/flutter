import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
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
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 65,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(CupertinoIcons.home, 'Home', 0),
              _buildNavItem(CupertinoIcons.person, 'You', 1),
              _buildNavItem(CupertinoIcons.cart, 'Cart', 2, isCart: true),
              _buildNavItem(Icons.grid_view, 'Menu', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool isCart = false}) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: isCart
                  ? Consumer(
                      builder: (context, ref, child) {
                        final count = ref.watch(cartCountProvider);
                        return Badge.count(
                          count: count,
                          isLabelVisible: count > 0,
                          backgroundColor: Colors.white,
                          textColor: Theme.of(context).primaryColor,
                          child: Icon(icon, key: ValueKey(isSelected), color: Colors.white, size: isSelected ? 24 : 22),
                        );
                      },
                    )
                  : Icon(icon, key: ValueKey(isSelected), color: Colors.white, size: isSelected ? 24 : 22),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 350),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
