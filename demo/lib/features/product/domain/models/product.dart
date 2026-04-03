class Product {
  final String id;
  final String title;
  final double price;
  final String imageUrl;
  final double rating;
  final String discount;
  final String category;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.rating,
    this.discount = '',
    required this.category,
  });

  // Factory for potential JSON parsing later
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      discount: json['discount'] as String? ?? '',
      category: json['category'] as String,
    );
  }
}
