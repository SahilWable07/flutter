import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/product.dart';

import 'package:demo/core/config/app_config.dart';

abstract class ProductRepository {
  Future<List<Product>> getFeaturedProducts();
  Future<List<Product>> getTrendingProducts();
  Future<List<Product>> searchProducts(String query);
  Future<Product> getProductById(String id);
}

class ApiProductRepository implements ProductRepository {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String> _getClientId() async {
    try {
      final token = await _getToken();
      if (token == null) return AppConfig.defaultClientId;
      final parts = token.split('.');
      if (parts.length != 3) return AppConfig.defaultClientId;
      final payloadMap = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final clients = payloadMap['clients'] as Map?;
      return (clients != null && clients.keys.isNotEmpty) 
          ? clients.keys.first.toString() : AppConfig.defaultClientId;
    } catch (e) {
      return AppConfig.defaultClientId;
    }
  }

  Future<List<Product>> _fetchProductsFromApi({String? query}) async {
    final token = await _getToken();
    final clientId = await _getClientId();
    final baseUrl = AppConfig.productUrl(clientId);
    final url = '$baseUrl/get-products';
    
    final Map<String, dynamic> requestBody = {};
    if (query != null && query.isNotEmpty) {
      requestBody['k'] = query;
    }
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          list = decoded['data'] ?? decoded['products'] ?? decoded['items'] ?? [];
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
          if (p['media'] != null && p['media'] is List && p['media'].isNotEmpty) {
            img = p['media'][0]['media_url'] ?? '';
          }
          if (img.isEmpty) img = p['imageUrl'] ?? p['image'] ?? '';

          double price = 0.0;
          if (p['variants'] != null && p['variants'] is List && p['variants'].isNotEmpty) {
            final v = p['variants'][0];
            price = parseDoubleRobust(v['discounted_price'] ?? v['regular_price'] ?? v['buying_price']);
          }
          if (price == 0.0) price = parseDoubleRobust(p['price'] ?? p['mrp']);

          String discount = '';
          if (p['variants'] != null && p['variants'] is List && (p['variants'] as List).isNotEmpty) {
            discount = p['variants'][0]['total_discount_percentage']?.toString() ?? '';
          }

          String vId = '';
          if (p['variants'] != null && p['variants'] is List && (p['variants'] as List).isNotEmpty) {
            vId = p['variants'][0]['product_variant_id']?.toString() ?? '';
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
  Future<List<Product>> searchProducts(String query) => _fetchProductsFromApi(query: query);

  @override
  Future<Product> getProductById(String id) async {
    final token = await _getToken();
    final clientId = await _getClientId();
    final baseUrl = AppConfig.productUrl(clientId);
    final url = '$baseUrl/product/$id?check_inventory=true';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
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
        if (data['media'] != null && data['media'] is List && (data['media'] as List).isNotEmpty) {
          img = data['media'][0]['media_url'] ?? '';
        }

        double price = 0.0;
        if (data['variants'] != null && data['variants'] is List && (data['variants'] as List).isNotEmpty) {
          final v = data['variants'][0];
          price = parseDoubleRobust(v['discounted_price'] ?? v['regular_price']);
        }

        return Product(
          id: data['product_id']?.toString() ?? id,
          variantId: data['variants']?[0]?['product_variant_id']?.toString() ?? '',
          title: data['name'] ?? 'Product',
          price: price,
          imageUrl: img,
          rating: 4.5,
          discount: '',
          category: 'General',
          description: data['description'] ?? '',
        );
      }
    } catch (e) {
      print('Detail API Error: $e');
    }
    throw Exception('Product not found');
  }
}
