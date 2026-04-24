import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../cart/presentation/screens/checkout_screen.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/utils/animated_popup.dart';
import '../../../profile/presentation/providers/wishlist_provider.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/glass_container.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isAddingToCart = false;

  void _handleAddToCart() async {
    if (_isAddingToCart) return;
    setState(() => _isAddingToCart = true);
    await ref.read(cartProvider.notifier).addToCart(widget.product);
    if (!mounted) return;
    AnimatedPopup.show(context, message: 'Added to Cart!', icon: CupertinoIcons.cart_fill);
    setState(() => _isAddingToCart = false);
  }

  void _handleBuyNow() async {
    await ref.read(cartProvider.notifier).addToCart(widget.product);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final relatedProductsState = ref.watch(trendingProductsProvider);
    
    // Properly handle prefixed IDs for wishlist consistency
    final baseId = widget.product.id.replaceAll('trending_', '').replaceAll('related_', '').replaceAll('wish_', '');
    final isWishlisted = ref.watch(wishlistProvider).any((item) => item.id == baseId);
    
    final detailState = ref.watch(productDetailProvider(baseId));
    final currentProduct = detailState.value ?? widget.product;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: const Icon(CupertinoIcons.chevron_left, size: 22),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Create a version of the product with the clean Base ID for toggling
                        final toggleProduct = widget.product.copyWith(id: baseId);
                        ref.read(wishlistProvider.notifier).toggleWishlist(toggleProduct);
                        AnimatedPopup.show(context, message: isWishlisted ? 'Removed' : 'Wishlisted', icon: isWishlisted ? CupertinoIcons.heart : CupertinoIcons.heart_fill, color: isWishlisted ? Colors.grey : Colors.redAccent);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                        child: Icon(isWishlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart, color: isWishlisted ? Colors.redAccent : Colors.black87, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                        child: Consumer(
                          builder: (context, ref, _) {
                            final count = ref.watch(cartCountProvider);
                            return Badge.count(count: count, isLabelVisible: count > 0, child: const Icon(CupertinoIcons.cart, size: 22));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Hero(
              tag: 'product_image_${currentProduct.id}',
              child: Container(
                height: 450,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 20, bottom: 40),
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB), borderRadius: BorderRadius.vertical(bottom: Radius.circular(50))),
                child: currentProduct.imageUrl.isNotEmpty ? Image.network(currentProduct.imageUrl, fit: BoxFit.contain) : const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text('Official Store', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold))),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(currentProduct.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(currentProduct.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('₹${currentProduct.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryColor)),
                      const SizedBox(width: 12),
                      if (currentProduct.discount.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)), child: Text('-${currentProduct.discount}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  detailState.when(
                    data: (fullProduct) => Text(fullProduct.description.isNotEmpty ? fullProduct.description : 'Premium quality product with comfortable materials and elegant design. Perfect for daily use.', style: TextStyle(color: Colors.black54, height: 1.6, fontSize: 15)),
                    loading: () => const Center(child: CupertinoActivityIndicator()),
                    error: (e, _) => const Text('Details currently unavailable.'),
                  ),
                  const SizedBox(height: 32),
                  const Text('Related Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 260,
              child: relatedProductsState.when(
                data: (products) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    if (p.id == widget.product.id) return const SizedBox.shrink();
                    return Container(width: 160, margin: const EdgeInsets.only(right: 16), child: ProductCard(id: 'related_${p.id}', variantId: p.variantId, title: p.title, price: '\$${p.price.toStringAsFixed(2)}', imageUrl: p.imageUrl, rating: p.rating, discount: p.discount, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)))));
                  },
                ),
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: OutlinedButton(
                    onPressed: _handleAddToCart,
                    style: OutlinedButton.styleFrom(side: BorderSide(color: primaryColor, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: _isAddingToCart ? const CupertinoActivityIndicator() : const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _handleBuyNow,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
