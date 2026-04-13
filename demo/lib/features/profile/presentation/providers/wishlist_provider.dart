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
    // Optimistic Update
    final previousState = state;
    _toggleLocal(product);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) return;
      
      final parts = token.split('.');
      if (parts.length != 3) return;
      
      // Basic payload extraction
      final payloadRaw = base64Url.normalize(parts[1]);
      final payloadMap = json.decode(utf8.decode(base64Url.decode(payloadRaw)));
      
      final userId = payloadMap['user_id'];
      final clients = payloadMap['clients'] as Map?;
      final targetClientId = (clients != null && clients.keys.isNotEmpty) 
          ? clients.keys.first.toString() : AppConfig.defaultClientId;
      
      final baseUrl = AppConfig.wishlistUrl(targetClientId);
      final url = Uri.parse('$baseUrl/wishlist/toggle');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token',
          // Removed browser-specific hardcoded headers (Origin, Referer, User-Agent)
          // to ensure cross-platform compatibility.
        },
        body: jsonEncode({
          "product_id": product.id,
          "user_id": userId,
          "client_id": targetClientId,
          "product_variant_id": product.variantId.isNotEmpty ? product.variantId : "",
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Rollback on failure if needed, but for wishlist, 
        // we often keep the local state for better UX unless it's a critical error.
        print('Wishlist Sync Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Wishlist Service Error: $e');
      // Optional: state = previousState; // Rollback
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
