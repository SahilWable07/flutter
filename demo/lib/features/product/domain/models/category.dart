class Category {
  final String id;
  final String name;
  final String? icon;
  final String? imageUrl;
  final String? description;
  final String clientId;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.imageUrl,
    this.description,
    required this.clientId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Handling multiple possible JSON mappings from the API
    return Category(
      id: json['id'] ?? (json['category_id'] ?? '').toString(),
      name: json['category_name'] ?? (json['name'] ?? ''),
      icon: json['category_icon'] ?? json['icon'],
      imageUrl: json['presigned_image_url'] ?? json['imageUrl'],
      description: json['description'],
      clientId: (json['client_id'] ?? '').toString(),
    );
  }
}

class Subcategory {
  final String id;
  final String parentCategoryId;
  final String name;
  final String? icon;
  final String? imageUrl;

  Subcategory({
    required this.id,
    required this.parentCategoryId,
    required this.name,
    this.icon,
    this.imageUrl,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['subcategory_id'] ?? (json['id'] ?? '').toString(),
      parentCategoryId: (json['category_id'] ?? '').toString(),
      name: json['subcategory_name'] ?? (json['name'] ?? ''),
      icon: json['subcategory_icon'] ?? json['icon'],
      imageUrl: json['presigned_image_url'] ?? json['imageUrl'],
    );
  }
}
