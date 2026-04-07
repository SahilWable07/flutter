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
    return Category(
      id: json['id']?.toString() ?? json['category_id']?.toString() ?? '',
      name: json['category_name']?.toString() ?? json['name']?.toString() ?? '',
      icon: (json['category_icon_url'] ?? json['category_icon'] ?? json['icon'])?.toString(),
      imageUrl: (json['category_icon_url'] ?? json['presigned_image_url'] ?? json['imageUrl'])?.toString(),
      description: json['description']?.toString(),
      clientId: json['client_id']?.toString() ?? '',
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
      id: json['id']?.toString() ?? json['subcategory_id']?.toString() ?? '',
      parentCategoryId: (json['product_category_id'] ?? json['category_id'] ?? '').toString(),
      name: (json['sub_category_name'] ?? json['subcategory_name'] ?? json['name'] ?? 'Unknown').toString(),
      icon: (json['sub_category_icon_url'] ?? json['subcategory_icon'] ?? json['icon'])?.toString(),
      imageUrl: (json['sub_category_icon_url'] ?? json['presigned_image_url'] ?? json['imageUrl'])?.toString(),
    );
  }
}
