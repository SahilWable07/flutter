import '../../domain/models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getFeaturedProducts();
  Future<List<Product>> getTrendingProducts();
}

class MockProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getFeaturedProducts() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));

    return [
      const Product(
        id: 'f_0',
        title: 'Sony WH-1000XM4 Noise Cancelling',
        price: 348.00,
        imageUrl: 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=500&q=80',
        rating: 4.8,
        discount: '15',
        category: 'Electronics',
      ),
      const Product(
        id: 'f_1',
        title: 'Nike Air Max 270 React',
        price: 150.00,
        imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500&q=80',
        rating: 4.5,
        discount: '25',
        category: 'Shoes',
      ),
      const Product(
        id: 'f_2',
        title: 'Apple iPad Pro 11-inch',
        price: 799.00,
        imageUrl: 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=500&q=80',
        rating: 4.9,
        discount: '',
        category: 'Electronics',
      ),
      const Product(
        id: 'f_3',
        title: 'Minimalist Leather Backpack',
        price: 120.00,
        imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500&q=80',
        rating: 4.3,
        discount: '10',
        category: 'Fashion',
      ),
      const Product(
        id: 'f_4',
        title: 'Professional DSLR Camera',
        price: 1200.00,
        imageUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=500&q=80',
        rating: 4.7,
        discount: '5',
        category: 'Electronics',
      ),
    ];
  }

  @override
  Future<List<Product>> getTrendingProducts() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    return [
      const Product(
        id: 't_0',
        title: 'Classic White Sneakers',
        price: 89.99,
        imageUrl: 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=500&q=80',
        rating: 4.2,
        discount: '20',
        category: 'Shoes',
      ),
      const Product(
        id: 't_1',
        title: 'Smart Fitness Watch',
        price: 199.99,
        imageUrl: 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=500&q=80',
        rating: 4.6,
        discount: '',
        category: 'Wearables',
      ),
      const Product(
        id: 't_2',
        title: 'Casual Denim Jacket',
        price: 65.00,
        imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500&q=80',
        rating: 4.4,
        discount: '15',
        category: 'Fashion',
      ),
      const Product(
        id: 't_3',
        title: 'Wireless Gaming Mouse',
        price: 75.50,
        imageUrl: 'https://images.unsplash.com/photo-1527814050087-152745339fbc?w=500&q=80',
        rating: 4.7,
        discount: '10',
        category: 'Electronics',
      ),
      const Product(
        id: 't_4',
        title: 'Modern Coffee Table',
        price: 320.00,
        imageUrl: 'https://images.unsplash.com/photo-1532372576444-dda9541f4ad8?w=500&q=80',
        rating: 4.5,
        discount: '',
        category: 'Home',
      ),
      const Product(
        id: 't_5',
        title: 'Premium Sunglasses',
        price: 150.00,
        imageUrl: 'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=500&q=80',
        rating: 4.8,
        discount: '30',
        category: 'Accessories',
      ),
    ];
  }
}
