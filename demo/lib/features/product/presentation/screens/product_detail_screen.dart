import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/utils/animated_popup.dart';
import '../../../profile/presentation/providers/wishlist_provider.dart';

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
    
    // 1. Fire the async API call update!
    await ref.read(cartProvider.notifier).addToCart(widget.product);
    
    if (!mounted) return;
    
    AnimatedPopup.show(context, message: 'Added to Cart!');
    
    setState(() => _isAddingToCart = false);
  }

  @override
  Widget build(BuildContext context) {
    final relatedProductsState = ref.watch(trendingProductsProvider);
    // 1. Observe Wishlist state
    final isWishlisted = ref.watch(wishlistProvider).any((item) => item.id == widget.product.id || item.title == widget.product.title);

    // 2. Fire the API call specific to this product to get full details properly!
    final detailState = ref.watch(productDetailProvider(widget.product.id));
    
    // 3. Gracefully fall back to the initial list-view product data while loading or if it fails
    final currentProduct = detailState.value ?? widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(
              isWishlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: isWishlisted ? Colors.pinkAccent : Colors.black87,
            ),
            onPressed: () {
              ref.read(wishlistProvider.notifier).toggleWishlist(widget.product);
              AnimatedPopup.show(
                context, 
                message: isWishlisted ? 'Removed from Wishlist' : 'Saved to Wishlist!', 
                icon: isWishlisted ? CupertinoIcons.heart : CupertinoIcons.heart_fill, 
                color: isWishlisted ? Colors.grey : Colors.pinkAccent
              );
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.cart),
            onPressed: () {
              // Navigation to cart remains if desired, but user focused on Wishlist in Home.
              // I'll keep this as contextually flexible.
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Image Carousel Area
          SliverToBoxAdapter(
            child: Hero(
              tag: 'product_image_${currentProduct.id}',
              child: Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                ),
                child: currentProduct.imageUrl.isNotEmpty 
                  ? Image.network(
                      currentProduct.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 100, color: Colors.grey),
                    )
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    currentProduct.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating Section
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < currentProduct.rating.floor() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentProduct.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      const Text('  (324 Ratings)', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Price Tag
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (currentProduct.discount.isNotEmpty)
                        Text(
                          '-${currentProduct.discount}% ',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.normal, color: Colors.red),
                        ),
                      Text(
                        '\$${currentProduct.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  const SizedBox(height: 16),
                  
                  // Dynamic Description from the specific API!
                  const Text(
                    'About this item',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Loading state or real text
                  detailState.when(
                    data: (fullProduct) => Text(
                      fullProduct.description.isNotEmpty ? fullProduct.description : 'No description available.',
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                    ),
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )),
                    error: (e, stack) => Text('Could not load extra details.', style: TextStyle(color: Colors.red.shade400)),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text(
                    'Related Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Related Products List
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250,
              child: relatedProductsState.when(
                data: (products) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      // Avoid showing the exact same product
                      if (p.id == widget.product.id) return const SizedBox.shrink(); 
                      
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ProductCard(
                          id: 'related_${p.id}',
                          variantId: p.variantId,
                          title: p.title,
                          price: '\$${p.price.toStringAsFixed(2)}',
                          imageUrl: p.imageUrl,
                          rating: p.rating,
                          discount: p.discount,
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => ProductDetailScreen(product: p),
                                transitionsBuilder: (_, animation, __, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)), // Space for sticky bottom bar
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD814), // Classic Amazon Yellow Add To Cart
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100), // fully rounded pill
                  side: const BorderSide(color: Color(0xFFFCD200)),
                ),
              ),
              child: _isAddingToCart 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text('Add to Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
            ),
          ),
        ),
      ),
    );
  }
}
