import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../../../profile/presentation/screens/wishlist_screen.dart';
import '../screens/checkout_screen.dart';
import '../../../product/presentation/screens/product_detail_screen.dart';
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
                            Text('₹${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: primaryColor)),
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
    return InkWell(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: item.product))
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Container
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: 'product_image_${item.product.id}',
                      child: item.product.imageUrl.isNotEmpty
                          ? Image.network(
                              item.product.imageUrl, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.broken_image, color: Colors.grey, size: 30),
                            )
                          : const Icon(Icons.image, color: Colors.grey, size: 30),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildAttributeRow("Colour :", _buildColorDot(Colors.black)),
                      const SizedBox(height: 2),
                      _buildAttributeRow("Size :", const Text("S", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      const SizedBox(height: 2),
                      _buildAttributeRow("Design:", const Text("parfx", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      const SizedBox(height: 8),
                      
                      // Pricing Row
                      Row(
                        children: [
                          const Text("Full set ", style: TextStyle(color: Colors.grey, fontSize: 16)),
                          Text(
                            "₹${(item.product.price * item.quantity).toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Color(0xFF109D59),
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "₹${item.product.price.toStringAsFixed(2)} × ${item.quantity}",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        "₹${(item.product.price * 2 * item.quantity).toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Qty and Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => ref.read(cartProvider.notifier).decrementQuantity(item.product.id),
                        child: const Icon(CupertinoIcons.minus, size: 16),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      GestureDetector(
                        onTap: () => ref.read(cartProvider.notifier).incrementQuantity(item.product.id),
                        child: const Icon(CupertinoIcons.plus, size: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text("Pieces: ${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          
          // Bottom Buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove Item'),
                        content: const Text('Are you sure you want to remove this item from your cart?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(cartProvider.notifier).removeFromCart(item.product.id);
                              Navigator.pop(context);
                            },
                            child: const Text('Remove', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.trash, size: 20, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text("Remove Item", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAttributeRow(String label, Widget value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(width: 8),
        value,
      ],
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1),
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
