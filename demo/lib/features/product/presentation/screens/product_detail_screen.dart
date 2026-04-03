import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../../shared/widgets/product_card.dart';

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
    
    // Simulate slight network/processing delay for professional feel
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    ref.read(cartProvider.notifier).addToCart(widget.product);
    
    ScaffoldMessenger.of(context).clearSnackBars(); // Ensure only one shows at a time
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Added to Cart!'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    
    setState(() => _isAddingToCart = false);
  }

  @override
  Widget build(BuildContext context) {
    final relatedProductsState = ref.watch(trendingProductsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.heart),
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved to Wishlist!'), duration: Duration(seconds: 1)),
              );
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.cart),
            onPressed: () {
              Navigator.pop(context); // Optional: Provide dynamic cart routing
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
              tag: 'product_image_${widget.product.id}',
              child: Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                ),
                child: Image.network(
                  widget.product.imageUrl,
                  fit: BoxFit.contain,
                ),
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
                    widget.product.title,
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
                            index < widget.product.rating.floor() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.product.rating.toStringAsFixed(1),
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
                      const Text(
                        '-15% ',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal, color: Colors.red),
                      ),
                      Text(
                        '\$${widget.product.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('M.R.P.: \$999.00', style: TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough)),
                  const SizedBox(height: 24),

                  // Divider
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'About this item',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Premium build quality ensuring long lasting effectiveness.\n'
                    '• Advanced features optimized for daily professional use.\n'
                    '• Elegant modern finish that compliments any aesthetic.\n'
                    '• Comprehensive warranty included directly from the manufacturer.',
                    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
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
