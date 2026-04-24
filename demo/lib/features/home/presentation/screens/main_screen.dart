import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../order/presentation/screens/orders_screen.dart';
import '../../../../shared/widgets/glass_container.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    const OrdersScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding : 24),
        child: GlassContainer(
          borderRadius: 35,
          blur: 20,
          opacity: 0.1,
          color: Colors.white,
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildNavItem(Iconsax.home_1_copy, Iconsax.home_copy, "Home", 0, primaryColor)),
                Expanded(child: _buildNavItem(Iconsax.menu_copy, Iconsax.menu_copy, "Menu", 1, primaryColor)),
                Expanded(child: _buildNavItem(Iconsax.box_copy, Iconsax.box_copy, "Orders", 2, primaryColor)),
                Expanded(child: _buildNavItem(Iconsax.shopping_cart_copy, Iconsax.shopping_cart_copy, "Cart", 3, primaryColor, isCart: true)),
                Expanded(child: _buildNavItem(Iconsax.user_copy, Iconsax.user_copy, "Profile", 4, primaryColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index, Color primaryColor, {bool isCart = false}) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          isCart
              ? Consumer(
                  builder: (context, ref, child) {
                    final count = ref.watch(cartCountProvider);
                    return Badge.count(
                      count: count,
                      isLabelVisible: count > 0,
                      backgroundColor: primaryColor,
                      child: Icon(
                        isSelected ? activeIcon : icon,
                        color: isSelected ? primaryColor : Colors.black54,
                        size: 22,
                      ),
                    );
                  },
                )
              : Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? primaryColor : Colors.black54,
                  size: 22,
                ),
          if (isSelected) ...[
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}
