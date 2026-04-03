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

  const ProductListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can reuse the trending products provider or create a filtered one.
    // Let's use featured and trending combined, then filter by category locally for mock simplicity.
    final state = ref.watch(trendingProductsProvider);

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
