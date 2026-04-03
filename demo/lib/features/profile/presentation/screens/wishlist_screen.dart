import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../product/presentation/screens/product_detail_screen.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We use trending products as a mock placeholder for the wishlist
    final state = ref.watch(trendingProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        centerTitle: true,
      ),
      body: state.when(
        data: (products) {
          // Use a slice of products to mock wishlist
          final wishlistProducts = products.take(4).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.60,
            ),
            itemCount: wishlistProducts.length,
            itemBuilder: (context, index) {
              final product = wishlistProducts[index];
              return ProductCard(
                id: 'wish_${product.id}',
                title: product.title,
                price: '\$${product.price.toStringAsFixed(2)}',
                imageUrl: product.imageUrl,
                rating: product.rating,
                discount: product.discount,
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, _) => ProductDetailScreen(product: product),
                      transitionsBuilder: (context, animation, _, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error loading wishlist: $error')),
      ),
    );
  }
}
