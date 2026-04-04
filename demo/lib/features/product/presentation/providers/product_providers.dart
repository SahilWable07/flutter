import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/product_repository.dart';
import '../../domain/models/product.dart';

// Provider for the API/Repository implementation
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ApiProductRepository();
});

// FutureProvider automatically handles Loading, Error, and Data states
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  return repository.getFeaturedProducts();
});

final trendingProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  return repository.getTrendingProducts();
});

final searchProductsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  final repository = ref.read(productRepositoryProvider);
  return repository.searchProducts(query);
});

final productDetailProvider = FutureProvider.family<Product, String>((ref, id) async {
  final repository = ref.read(productRepositoryProvider);
  return repository.getProductById(id);
});
