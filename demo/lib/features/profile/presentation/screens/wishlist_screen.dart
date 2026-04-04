import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wishlist_provider.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../product/presentation/screens/product_detail_screen.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Use the real integrated provider!
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        centerTitle: true,
      ),
      body: wishlist.isEmpty 
        ? const Center(child: Text('Your wishlist is empty.'))
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: wishlist.length,
            itemBuilder: (context, index) {
              final product = wishlist[index];
              return ProductCard(
                id: 'wish_${product.id}',
                variantId: product.variantId,
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
          ),
    );
  }
}
