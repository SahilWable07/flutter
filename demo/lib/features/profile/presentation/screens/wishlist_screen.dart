import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wishlist_provider.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../product/presentation/screens/product_detail_screen.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/glass_container.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: GlassContainer(
            borderRadius: 16,
            child: AppBar(
              title: const Text('My Wishlist'),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
      ),
      body: wishlist.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_outline, size: 80, color: Colors.grey.withValues(alpha: 0.2)),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Your wishlist is empty.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: AppSpacing.l),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Go Shopping'),
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.m, 110, AppSpacing.m, AppSpacing.m),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.m,
              mainAxisSpacing: AppSpacing.m,
              childAspectRatio: 0.72,
            ),
            itemCount: wishlist.length,
            itemBuilder: (context, index) {
              final product = wishlist[index];
              return AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 300),
                child: ProductCard(
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
                ),
              );
            },
          ),
    );
  }
}
