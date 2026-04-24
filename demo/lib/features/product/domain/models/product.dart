class Product {
  final String id; // This will map to product_id
  final String variantId; // This will map to product_variant_id
  final String title;
  final double price;
  final String imageUrl;
  final double rating;
  final String discount;
  final String category;

  final String description;
  final int stockQuantity;

  const Product({
    required this.id,
    required this.variantId,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.rating,
    this.discount = '',
    required this.category,
    this.description = '',
    this.stockQuantity = 0,
  });

  Product copyWith({
    String? id,
    String? variantId,
    String? title,
    double? price,
    String? imageUrl,
    double? rating,
    String? discount,
    String? category,
    String? description,
    int? stockQuantity,
  }) {
    return Product(
      id: id ?? this.id,
      variantId: variantId ?? this.variantId,
      title: title ?? this.title,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      discount: discount ?? this.discount,
      category: category ?? this.category,
      description: description ?? this.description,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }

  // Factory for potential JSON parsing later
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      variantId: json['variantId'] as String? ?? '',
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      discount: json['discount'] as String? ?? '',
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      stockQuantity: json['stockQuantity'] as int? ?? 0,
    );
  }
}
