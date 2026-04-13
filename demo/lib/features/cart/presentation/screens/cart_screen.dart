import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../../../profile/presentation/screens/wishlist_screen.dart';
import '../screens/checkout_screen.dart';
import '../../../../shared/utils/animated_popup.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/glass_container.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: GlassContainer(
            borderRadius: 16,
            child: AppBar(
              title: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(CupertinoIcons.heart),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.cart, size: 100, color: Colors.grey.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey.shade400)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 110, 16, 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItem(context, ref, item, primaryColor);
                    },
                  ),
                ),
                // Custom Bottom Action Bar (not a bottomSheet to avoid Scaffolding overlap)
                if (cartItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 110), // Extra bottom padding for Main nav bar
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Sum', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                            Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
                            child: const Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, dynamic item, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: const Color(0xFFF9FAFB),
              child: item.product.imageUrl.isNotEmpty ? Image.network(item.product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey)) : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('\$${item.product.price.toStringAsFixed(2)}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyBtn(icon: CupertinoIcons.minus, onTap: () => ref.read(cartProvider.notifier).decrementQuantity(item.product.id)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold))),
                    _QtyBtn(icon: CupertinoIcons.plus, color: primaryColor, onTap: () => ref.read(cartProvider.notifier).addToCart(item.product)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20), onPressed: () => ref.read(cartProvider.notifier).removeFromCart(item.product.id)),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _QtyBtn({required this.icon, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: (color ?? Colors.grey).withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 14, color: color ?? Colors.grey)));
  }
}
