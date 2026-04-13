import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/product.dart';
import '../../domain/models/category.dart';
import 'package:demo/core/config/app_config.dart';

abstract class ProductRepository {
  Future<List<Product>> getFeaturedProducts();
  Future<List<Product>> getTrendingProducts();
  Future<List<Product>> searchProducts(String query);
  Future<Product> getProductById(String id);
  Future<List<Category>> getCategories();
  Future<List<Subcategory>> getSubcategories(String categoryId);
  Future<List<Product>> getProductsBySubcategory(String subcategoryId);
  Future<List<Product>> getProductsByCategory(String categoryId);
}

class ApiProductRepository implements ProductRepository {
  final String _s3Base = 'https://new-platform-erp-dev.s3.ap-south-1.amazonaws.com/';

  String _normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    // Remove leading slash if present
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '$_s3Base$cleanUrl';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders({bool includeContentType = false}) async {
    final token = await _getToken();
    return {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
      if (includeContentType) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<String> _getClientId() async {
    try {
      final token = await _getToken();
      if (token == null) return AppConfig.defaultClientId;
      final parts = token.split('.');
      if (parts.length != 3) return AppConfig.defaultClientId;
      final payloadMap = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final clients = payloadMap['clients'] as Map?;
      if (clients != null && clients.isNotEmpty) {
        if (clients.containsKey(AppConfig.defaultClientId)) return AppConfig.defaultClientId;
        return clients.keys.first.toString();
      }
      return AppConfig.defaultClientId;
    } catch (_) {
      return AppConfig.defaultClientId;
    }
  }

  Future<List<Product>> _fetchProductsFromApi({String? query, String? subcategoryId, String? categoryId}) async {
    final clientId = await _getClientId();
    final url = '${AppConfig.productUrl(clientId)}/get-products';
    final requestBody = {
      if (query != null) 'k': query,
      if (subcategoryId != null) 'sub_category_ids': subcategoryId,
      if (categoryId != null) 'product_category_ids': categoryId,
    };

    try {
      final response = await http.post(Uri.parse(url), headers: await _getHeaders(includeContentType: true), body: jsonEncode(requestBody));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final list = (decoded is List) ? decoded : (decoded['data'] ?? decoded['products'] ?? []);
        return (list as List).map((p) {
          String img = '';
          if (p['media'] != null && p['media'] is List && p['media'].isNotEmpty) {
            img = _normalizeUrl(p['media'][0]['media_url']);
          }
          if (img.isEmpty) img = _normalizeUrl(p['imageUrl'] ?? p['image']);

          double price = 0.0;
          if (p['variants'] != null && p['variants'] is List && p['variants'].isNotEmpty) {
            final v = p['variants'][0];
            price = (v['discounted_price'] ?? v['regular_price'] ?? 0.0).toDouble();
          }

          return Product(
            id: p['product_id']?.toString() ?? p['id']?.toString() ?? '0',
            variantId: (p['variants'] != null && p['variants'].isNotEmpty) ? p['variants'][0]['product_variant_id']?.toString() ?? '' : '',
            title: p['name'] ?? p['title'] ?? 'Product',
            price: price,
            imageUrl: img,
            rating: (p['rating'] ?? 4.5).toDouble(),
            category: p['category']?.toString() ?? 'General',
          );
        }).toList();
      }
    } catch (e) { print('API Error: $e'); }
    return [];
  }

  @override
  Future<List<Product>> getFeaturedProducts() => _fetchProductsFromApi();
  @override
  Future<List<Product>> getTrendingProducts() => _fetchProductsFromApi();
  @override
  Future<List<Product>> searchProducts(String query) => _fetchProductsFromApi(query: query);
  @override
  Future<List<Product>> getProductsBySubcategory(String subcategoryId) => _fetchProductsFromApi(subcategoryId: subcategoryId);
  @override
  Future<List<Product>> getProductsByCategory(String categoryId) => _fetchProductsFromApi(categoryId: categoryId);

  @override
  Future<Product> getProductById(String id) async {
    final clientId = await _getClientId();
    final url = '${AppConfig.productUrl(clientId)}/product/$id?check_inventory=true';
    try {
      final response = await http.get(Uri.parse(url), headers: await _getHeaders());
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body)['data'] ?? json.decode(response.body);
        String img = '';
        if (data['media'] != null && (data['media'] as List).isNotEmpty) img = _normalizeUrl(data['media'][0]['media_url']);
        return Product(
          id: data['product_id']?.toString() ?? id,
          variantId: (data['variants'] != null && data['variants'].isNotEmpty) ? data['variants'][0]['product_variant_id']?.toString() ?? '' : '',
          title: data['name'] ?? 'Product',
          price: (data['variants'] != null && data['variants'].isNotEmpty) ? (data['variants'][0]['discounted_price'] ?? 0.0).toDouble() : 0.0,
          imageUrl: img,
          rating: 4.5,
          category: 'General',
          description: data['description'] ?? '',
        );
      }
    } catch (_) {}
    throw Exception('Product not found');
  }

  @override
  Future<List<Category>> getCategories() async {
    final clientId = await _getClientId();
    final url = '${AppConfig.categoryUrl(clientId)}/categories?page=1&limit=10';
    try {
      final response = await http.get(Uri.parse(url), headers: await _getHeaders());
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body)['data'] ?? [];
        return (data as List).map((item) {
          final cat = Category.fromJson(item);
          // Manually normalize Category images if needed
          return Category(
            id: cat.id, name: cat.name, clientId: cat.clientId,
            imageUrl: _normalizeUrl(cat.imageUrl),
            icon: _normalizeUrl(cat.icon),
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<Subcategory>> getSubcategories(String categoryId) async {
    final clientId = await _getClientId();
    final url = '${AppConfig.subcategoryUrl(clientId)}/subcategories';
    try {
      final response = await http.post(Uri.parse(url), headers: await _getHeaders(includeContentType: true), body: jsonEncode({"category_ids": categoryId, "page": 1, "limit": 10}));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body)['data'] ?? [];
        return (data as List).map((item) {
          final sub = Subcategory.fromJson(item);
          return Subcategory(
              id: sub.id, parentCategoryId: sub.parentCategoryId, name: sub.name,
              imageUrl: _normalizeUrl(sub.imageUrl),
              icon: _normalizeUrl(sub.icon)
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}
