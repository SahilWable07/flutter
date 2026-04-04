import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demo/features/product/domain/models/product.dart';
import 'package:demo/core/config/app_config.dart';

class WishlistNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    return [];
  }

  Future<void> toggleWishlist(Product product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
         _toggleLocal(product);
         return;
      }
      
      final parts = token.split('.');
      if (parts.length != 3) {
         _toggleLocal(product);
         return;
      }
      
      final payloadRaw = base64Url.normalize(parts[1]);
      final payloadMap = json.decode(utf8.decode(base64Url.decode(payloadRaw)));
      
      final userId = payloadMap['user_id'];
      final clients = payloadMap['clients'] as Map?;
      final targetClientId = (clients != null && clients.keys.isNotEmpty) 
          ? clients.keys.first.toString() : AppConfig.defaultClientId;
      
      final baseUrl = AppConfig.wishlistUrl(targetClientId);
      final url = Uri.parse('$baseUrl/wishlist/toggle');

      print('Calling WISHLIST Toggle: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Connection': 'keep-alive',
          'Content-Type': 'application/json',
          'Origin': 'http://localhost:56024',
          'Referer': 'http://localhost:56024/',
          'Sec-Fetch-Dest': 'empty',
          'Sec-Fetch-Mode': 'cors',
          'Sec-Fetch-Site': 'cross-site',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 8.0.0; SM-G955U Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Mobile Safari/537.36',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "product_id": product.id,
          "user_id": userId,
          "client_id": targetClientId,
          "product_variant_id": product.variantId.isNotEmpty ? product.variantId : "e16045cb-138d-4abc-ad79-f9d3d7d48425"
        }),
      );

      print('WISHLIST Status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _toggleLocal(product);
      } else {
        print('Wishlist Failure Body: ${response.body}');
        _toggleLocal(product);
      }
    } catch (e) {
      print('Wishlist Error: $e');
      _toggleLocal(product);
    }
  }

  void _toggleLocal(Product product) {
    if (state.any((p) => p.id == product.id)) {
      state = state.where((p) => p.id != product.id).toList();
    } else {
      state = [...state, product];
    }
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, List<Product>>(() {
  return WishlistNotifier();
});

final wishlistCountProvider = Provider<int>((ref) {
  return ref.watch(wishlistProvider).length;
});
