import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../providers/product_providers.dart';
import '../../../../shared/widgets/product_card.dart';
import 'product_detail_screen.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

class ProductListScreen extends ConsumerWidget {
  final String category;
  final String? searchQuery;
  final String? subcategoryId;
  final String? productCategoryId;

  const ProductListScreen({
    super.key, 
    required this.category,
    this.searchQuery,
    this.subcategoryId,
    this.productCategoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Priority logic for fetching products:
    // 1. Search Query
    // 2. Subcategory (POST API)
    // 3. Category (POST API)
    // 4. Defaults to Trending
    final state = (searchQuery != null && searchQuery!.isNotEmpty)
        ? ref.watch(searchProductsProvider(searchQuery!))
        : (subcategoryId != null && subcategoryId!.isNotEmpty)
            ? ref.watch(subcategoryProductsProvider(subcategoryId!))
            : (productCategoryId != null && productCategoryId!.isNotEmpty)
                ? ref.watch(categoryProductsProvider(productCategoryId!))
                : ref.watch(trendingProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        centerTitle: true,
      ),
      body: state.when(
        data: (products) {
          // Dummy filtering (in reality this is done via API)
          final filtered = products; 
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final product = filtered[index];
              return ProductCard(
                id: product.id,
                variantId: product.variantId,
                title: product.title,
                price: '\$${product.price.toStringAsFixed(2)}',
                imageUrl: product.imageUrl,
                rating: product.rating,
                discount: product.discount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(product: product),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.65,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => const ProductCardSkeleton(),
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
