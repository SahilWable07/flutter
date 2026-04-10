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
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders({
    bool includeContentType = false,
  }) async {
    final token = await _getToken();
    return {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
      if (includeContentType) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Origin': 'http://localhost:55021',
      'Referer': 'http://localhost:55021/',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Mobile Safari/537.36',
    };
  }

  Future<String> _getClientId() async {
    try {
      final token = await _getToken();
      if (token == null) return AppConfig.defaultClientId;
      final parts = token.split('.');
      if (parts.length != 3) return AppConfig.defaultClientId;
      final payloadMap = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final clients = payloadMap['clients'] as Map?;

      if (clients != null && clients.isNotEmpty) {
        // Prioritize default client ID if it exists in the token's clients
        if (clients.containsKey(AppConfig.defaultClientId)) {
          return AppConfig.defaultClientId;
        }
        return clients.keys.first.toString();
      }
      return AppConfig.defaultClientId;
    } catch (e) {
      return AppConfig.defaultClientId;
    }
  }

  Future<List<Product>> _fetchProductsFromApi({
    String? query,
    String? subcategoryId,
    String? categoryId,
  }) async {
    final clientId = await _getClientId();
    final baseUrl = AppConfig.productUrl(clientId);
    final url = '$baseUrl/get-products';

    final Map<String, dynamic> requestBody = {};
    if (query != null && query.isNotEmpty) {
      requestBody['k'] = query;
    }
    if (subcategoryId != null && subcategoryId.isNotEmpty) {
      requestBody['sub_category_ids'] = subcategoryId;
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      requestBody['product_category_ids'] = categoryId;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(includeContentType: true),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          list =
              decoded['data'] ?? decoded['products'] ?? decoded['items'] ?? [];
        }

        return list.map((p) {
          // Robust parsing logic
          double parseDoubleRobust(dynamic val, [double defaultVal = 0.0]) {
            if (val == null) return defaultVal;
            if (val is num) return val.toDouble();
            if (val is String) return double.tryParse(val) ?? defaultVal;
            return defaultVal;
          }

          String img = '';
          if (p['media'] != null &&
              p['media'] is List &&
              p['media'].isNotEmpty) {
            img = p['media'][0]['media_url'] ?? '';
          }
          if (img.isEmpty) img = p['imageUrl'] ?? p['image'] ?? '';

          double price = 0.0;
          if (p['variants'] != null &&
              p['variants'] is List &&
              p['variants'].isNotEmpty) {
            final v = p['variants'][0];
            price = parseDoubleRobust(
              v['discounted_price'] ?? v['regular_price'] ?? v['buying_price'],
            );
          }
          if (price == 0.0) price = parseDoubleRobust(p['price'] ?? p['mrp']);

          String discount = '';
          if (p['variants'] != null &&
              p['variants'] is List &&
              (p['variants'] as List).isNotEmpty) {
            discount =
                p['variants'][0]['total_discount_percentage']?.toString() ?? '';
          }

          String vId = '';
          int stock = 0;
          if (p['variants'] != null &&
              p['variants'] is List &&
              (p['variants'] as List).isNotEmpty) {
            final variant = p['variants'][0];
            vId = variant['product_variant_id']?.toString() ?? '';
            // Attempt to parse stock from common inventory fields
            stock =
                int.tryParse(
                  variant['available_stock']?.toString() ??
                      variant['total_stock']?.toString() ??
                      variant['inventory']?.toString() ??
                      '0',
                ) ??
                0;
          }

          return Product(
            id: p['product_id']?.toString() ?? p['id']?.toString() ?? '0',
            variantId: vId,
            title: p['name'] ?? p['title'] ?? 'Product',
            price: price,
            imageUrl: img,
            rating: parseDoubleRobust(p['rating'], 4.5),
            discount: discount,
            category: p['category']?.toString() ?? 'General',
            stockQuantity: stock,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Product API Error: $e');
      return [];
    }
  }

  @override
  Future<List<Product>> getFeaturedProducts() => _fetchProductsFromApi();

  @override
  Future<List<Product>> getTrendingProducts() => _fetchProductsFromApi();

  @override
  Future<List<Product>> searchProducts(String query) =>
      _fetchProductsFromApi(query: query);

  @override
  Future<List<Product>> getProductsBySubcategory(String subcategoryId) =>
      _fetchProductsFromApi(subcategoryId: subcategoryId);

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) =>
      _fetchProductsFromApi(categoryId: categoryId);

  @override
  Future<Product> getProductById(String id) async {
    final clientId = await _getClientId();
    final baseUrl = AppConfig.productUrl(clientId);
    final url = '$baseUrl/product/$id?check_inventory=true';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final p = json.decode(response.body);
        final data = p['data'] ?? p;

        // Use same robust parsing
        double parseDoubleRobust(dynamic val, [double defaultVal = 0.0]) {
          if (val == null) return defaultVal;
          if (val is num) return val.toDouble();
          if (val is String) return double.tryParse(val) ?? defaultVal;
          return defaultVal;
        }

        String img = '';
        if (data['media'] != null &&
            data['media'] is List &&
            (data['media'] as List).isNotEmpty) {
          img = data['media'][0]['media_url'] ?? '';
        }

        double price = 0.0;
        if (data['variants'] != null &&
            data['variants'] is List &&
            (data['variants'] as List).isNotEmpty) {
          final v = data['variants'][0];
          price = parseDoubleRobust(
            v['discounted_price'] ?? v['regular_price'],
          );
        }

        String vId = '';
        int stock = 0;
        if (data['variants'] != null &&
            data['variants'] is List &&
            (data['variants'] as List).isNotEmpty) {
          final variant = data['variants'][0];
          vId = variant['product_variant_id']?.toString() ?? '';
          stock =
              int.tryParse(
                variant['available_stock']?.toString() ??
                    variant['total_stock']?.toString() ??
                    variant['inventory']?.toString() ??
                    '0',
              ) ??
              0;
        }

        return Product(
          id: data['product_id']?.toString() ?? id,
          variantId: vId,
          title: data['name'] ?? 'Product',
          price: price,
          imageUrl: img,
          rating: 4.5,
          discount: '',
          category: 'General',
          description: data['description'] ?? '',
          stockQuantity: stock,
        );
      }
    } catch (e) {
      print('Detail API Error: $e');
    }
    throw Exception('Product not found');
  }

  @override
  Future<List<Category>> getCategories() async {
    final clientId = await _getClientId();
    final baseUrl = AppConfig.categoryUrl(clientId);
    final url = '$baseUrl/categories?page=1&limit=10';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];
        return data.map((item) => Category.fromJson(item)).toList();
      }
    } catch (e) {
      print('Category API Error: $e');
    }
    return [];
  }

  @override
  Future<List<Subcategory>> getSubcategories(String categoryId) async {
    final clientId = await _getClientId();
    final token = await _getToken();
    final url = '${AppConfig.subcategoryUrl(clientId)}/subcategories';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(includeContentType: true),
        body: jsonEncode({
          "category_ids": categoryId, // Keep this as a potential filter
          "page": 1,
          "limit": 10,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];
        return data.map((item) => Subcategory.fromJson(item)).toList();
      }
    } catch (e) {
      print('Subcategory API Error: $e');
    }
    return [];
  }
}
