import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/presentation/providers/wishlist_provider.dart';
import '../../features/product/domain/models/product.dart';
import '../../core/constants/app_spacing.dart';
import '../../shared/utils/animated_popup.dart';

class ProductCard extends ConsumerWidget {
  final String id;
  final String variantId;
  final String title;
  final String price;
  final String imageUrl;
  final double rating;
  final String discount;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.id,
    required this.variantId,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.discount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    // Properly strip prefixes to identify the base product ID
    final baseId = id.replaceAll('trending_', '').replaceAll('related_', '').replaceAll('wish_', '');
    final isWishlisted = wishlist.any((item) => item.id == baseId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                      child: Hero(
                        tag: 'product_image_$id',
                        child: imageUrl.isNotEmpty 
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image, color: Colors.grey)),
                            )
                          : Container(color: Colors.grey.shade100, child: const Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                    if (discount.isNotEmpty && discount != '0')
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$discount% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Favorite Heart
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          final p = Product(
                            id: baseId,
                            variantId: variantId,
                            title: title, 
                            price: double.tryParse(price.replaceAll('\$', '')) ?? 0.0, 
                            imageUrl: imageUrl, 
                            rating: rating, 
                            category: 'General', 
                            discount: discount
                          );
                          ref.read(wishlistProvider.notifier).toggleWishlist(p);
                          
                          // Show Notification
                          AnimatedPopup.show(
                            context, 
                            message: isWishlisted ? 'Removed from Wishlist' : 'Added to Wishlist!',
                            icon: isWishlisted ? CupertinoIcons.heart : CupertinoIcons.heart_fill,
                            color: isWishlisted ? Colors.grey : Colors.redAccent,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: isWishlisted ? Colors.redAccent : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Details Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
