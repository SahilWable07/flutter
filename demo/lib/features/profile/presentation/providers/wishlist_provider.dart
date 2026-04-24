import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demo/features/product/domain/models/product.dart';
import 'package:demo/core/config/app_config.dart';

class WishlistNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    // Initial fetch to populate the list on app startup
    Future.microtask(() => fetchWishlist());
    return [];
  }

  Future<Map<String, dynamic>?> _getAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return null;

      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payloadRaw = base64Url.normalize(parts[1]);
      final payloadMap = json.decode(utf8.decode(base64Url.decode(payloadRaw)));

      final clients = payloadMap['clients'] as Map?;
      String targetClientId = AppConfig.defaultClientId;

      // Extract the most relevant client ID from the token
      if (clients != null && clients.isNotEmpty) {
        if (clients.containsKey(AppConfig.defaultClientId)) {
          targetClientId = AppConfig.defaultClientId;
        } else {
          targetClientId = clients.keys.first.toString();
        }
      }

      return {
        'token': token,
        'userId': payloadMap['user_id'],
        'clientId': targetClientId,
      };
    } catch (e) {
      print('Auth Prep Error: $e');
      return null;
    }
  }

  Future<void> fetchWishlist() async {
    final authData = await _getAuthData();
    if (authData == null) return;

    try {
      final token = authData['token'];
      final userId = authData['userId'];
      final clientId = authData['clientId'];
      
      final baseUrl = AppConfig.wishlistUrl(clientId);
      final url = Uri.parse('$baseUrl/wishlist/list'); // Common ERP list endpoint

      print('WISH_SYNC: Fetching list...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "page": 1,
          "limit": 500,
          "user_id": userId,
          "client_id": clientId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> itemsRaw = decoded['data'] ?? decoded['items'] ?? decoded['rows'] ?? [];
        
        final List<Product> fetchedItems = [];
        for (var row in itemsRaw) {
          final p = row['product'] ?? row;
          String pId = (p['product_id'] ?? p['id'] ?? row['product_id'] ?? row['id'] ?? '').toString();
          
          // CRITICAL: Standardize ID by removing ALL common e-commerce prefixes
          pId = pId.replaceAll(RegExp(r'^(trending_|related_|wish_|home_|fav_)'), '');
          
          if (pId.isEmpty || pId == 'null') continue;

          String img = '';
          if (p['media'] is List && (p['media'] as List).isNotEmpty) {
            img = p['media'][0]['media_url'] ?? p['media'][0]['url'] ?? '';
          }
          if (img.isEmpty) img = p['imageUrl'] ?? p['image_url'] ?? p['image'] ?? p['thumb'] ?? '';

          fetchedItems.add(Product(
            id: pId,
            variantId: (row['product_variant_id'] ?? p['variant_id'] ?? '').toString(),
            title: p['product_name'] ?? p['name'] ?? p['title'] ?? 'Product',
            price: double.tryParse(p['price']?.toString() ?? '0') ?? 0.0,
            imageUrl: img,
            rating: double.tryParse(p['rating']?.toString() ?? '4.5') ?? 4.5,
            category: (p['category'] ?? '').toString(),
            discount: (p['discount'] ?? '').toString(),
          ));
        }
        
        state = fetchedItems;
        print('WISH_SYNC: Success. Count: ${state.length}');
      }
    } catch (e) {
      print('WISH_SYNC: Error $e');
    }
  }

  Future<void> toggleWishlist(Product product) async {
    // 1. Clean the incoming product ID
    final cleanId = product.id.replaceAll(RegExp(r'^(trending_|related_|wish_|home_|fav_)'), '');
    final cleanProduct = product.copyWith(id: cleanId);

    // 2. Optimistic Update (Immediate UI response)
    final isAlreadyIn = state.any((p) => p.id == cleanId);
    if (isAlreadyIn) {
      state = state.where((p) => p.id != cleanId).toList();
    } else {
      state = [...state, cleanProduct];
    }

    // 3. Sync with Server
    try {
      final authData = await _getAuthData();
      if (authData == null) return;
      
      final baseUrl = AppConfig.wishlistUrl(authData['clientId']);
      final url = Uri.parse('$baseUrl/wishlist/toggle');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authData['token']}',
        },
        body: jsonEncode({
          "product_id": cleanId,
          "user_id": authData['userId'],
          "client_id": authData['clientId'],
          "product_variant_id": cleanProduct.variantId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Optional: Re-fetch list to ensure consistency if toggle response doesn't provide full data
        fetchWishlist();
      }
    } catch (e) {
      print('WISH_TOGGLE: Sync Error $e');
    }
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, List<Product>>(() {
  return WishlistNotifier();
});

final wishlistCountProvider = Provider<int>((ref) {
  return ref.watch(wishlistProvider).length;
});
