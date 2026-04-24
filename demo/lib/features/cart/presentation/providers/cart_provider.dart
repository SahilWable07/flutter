import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demo/features/cart/domain/models/cart_item.dart';
import 'package:demo/features/product/domain/models/product.dart';
import 'package:demo/core/config/app_config.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    // Trigger initial fetch
    Future.microtask(() => fetchCartItems());
    return [];
  }

  Future<void> fetchCartItems() async {
    final authData = await _getAuthData();
    if (authData == null) return;

    try {
      final baseUrl = AppConfig.cartUrl(authData['clientId']);
      final url = Uri.parse('$baseUrl/items');

      final response = await http.post(
        url,
        headers: await _getHeaders(
          token: authData['token'],
          includeContentType: true,
        ),
        body: jsonEncode({"page": 1, "limit": 250}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        _handleCartSync(decoded);
      }
    } catch (e) {
      print('Fetch Cart Error: $e');
    }
  }

  Future<Map<String, String>> _getHeaders({
    required String token,
    bool includeContentType = false,
  }) async {
    return {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
      if (includeContentType) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Origin': 'http://localhost:55021',
      'Referer': 'http://localhost:55021/',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Mobile Safari/537.36',
    };
  }

  Future<Map<String, dynamic>?> _getAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return null;

      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payloadRaw = base64Url.normalize(parts[1]);
      final payloadMap = json.decode(utf8.decode(base64Url.decode(payloadRaw)));

      final clients = payloadMap['clients'] as Map?;
      String targetClientId = AppConfig.defaultClientId;

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
      return null;
    }
  }

  Future<void> addToCart(Product product) async {
    final authData = await _getAuthData();
    if (authData == null) {
      _addLocal(product);
      return;
    }

    try {
      final baseUrl = AppConfig.cartUrl(authData['clientId']);
      final url = Uri.parse('$baseUrl/add');

      print('Calling ADD to Cart API: $url');

      final response = await http.put(
        url,
        headers: await _getHeaders(
          token: authData['token'],
          includeContentType: true,
        ),
        body: jsonEncode({
          "user_id": authData['userId'],
          "cart_items": [
            {
              "quantity": 1,
              "check_inventory": true,
              "product_id": product.id,
              "product_set": "full",
            },
          ],
        }),
      );

      print('ADD Product Resp Status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        _handleCartSync(decoded, product);
      } else {
        print('ADD API Failure Body: ${response.body}');
        _addLocal(product);
      }
    } catch (e) {
      print('Add API Exception: $e');
      _addLocal(product);
    }
  }

  void _addLocal(Product product) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      final updatedCart = List<CartItem>.from(state);
      updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(
        quantity: updatedCart[existingIndex].quantity + 1,
      );
      state = updatedCart;
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void _handleCartSync(dynamic decoded, [Product? fallbackProduct]) {
    try {
      List<dynamic>? items;
      if (decoded is Map) {
        final data = decoded['data'];
        if (data is List && data.isNotEmpty) {
          // Newest observed structure: data: [ { items: [...] } ]
          items = data[0]['items'] ?? data[0]['cart_items'];
        } else if (data is Map) {
          items = data['cart_items'] ?? data['items'] ?? data['products'];
        } else if (decoded.containsKey('cart_items') ||
            decoded.containsKey('items')) {
          items = decoded['cart_items'] ?? decoded['items'];
        }
      }

      if (items != null && items is List) {
        final List<CartItem> newCartItems = [];
        for (var i in items) {
          if (i is! Map) continue;

          final String pId =
              i['product_id']?.toString() ?? i['id']?.toString() ?? '0';

          // Observed: cart_item_ids: [ "..." ]
          String? ciId;
          if (i['cart_item_ids'] is List &&
              (i['cart_item_ids'] as List).isNotEmpty) {
            ciId = i['cart_item_ids'][0].toString();
          }
          ciId ??= i['cart_item_id']?.toString() ?? i['id']?.toString();

          final qty = int.tryParse(i['quantity']?.toString() ?? '1') ?? 1;

          final existing = state.where((item) => item.product.id == pId);
          if (existing.isNotEmpty) {
            newCartItems.add(
              existing.first.copyWith(cartItemId: ciId, quantity: qty),
            );
          } else if (fallbackProduct != null && (fallbackProduct.id == pId)) {
            newCartItems.add(
              CartItem(
                product: fallbackProduct,
                cartItemId: ciId,
                quantity: qty,
              ),
            );
          } else {
            // Observed fields: product_name, price, media: [ { media_url } ]
            try {
              final pJson = i['product'] ?? i;

              String img = '';
              if (pJson['media'] is List &&
                  (pJson['media'] as List).isNotEmpty) {
                img =
                    pJson['media'][0]['media_url'] ??
                    pJson['media'][0]['url'] ??
                    pJson['media'][0]['image_url'] ??
                    '';
              }
              if (img.isEmpty) {
                img = pJson['imageUrl'] ?? 
                      pJson['image_url'] ?? 
                      pJson['image'] ?? 
                      pJson['thumb'] ?? 
                      pJson['thumbnail'] ?? 
                      pJson['base_url'] ?? 
                      '';
              }

              final product = Product(
                id: pId,
                variantId: i['product_variant_id']?.toString() ?? '',
                title:
                    pJson['product_name'] ??
                    pJson['name'] ??
                    pJson['title'] ??
                    'Product',
                price: double.tryParse(pJson['price']?.toString() ?? '0') ?? 0,
                imageUrl: img,
                rating: 4.5,
                discount: '',
                category: '',
              );
              newCartItems.add(
                CartItem(product: product, cartItemId: ciId, quantity: qty),
              );
            } catch (e) {
              print('Error parsing cart item product: $e');
            }
          }
        }
        state = newCartItems;
      }
    } catch (e) {
      print('Sync Error: $e');
    }
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    final authData = await _getAuthData();
    final itemIndex = state.indexWhere((item) => item.product.id == productId);
    if (itemIndex < 0) return;

    final item = state[itemIndex];
    if (authData != null && item.cartItemId != null) {
      try {
        final baseUrl = AppConfig.cartUrl(authData['clientId']);
        final url = Uri.parse('$baseUrl/cart-item/${item.cartItemId}');
        final response = await http.put(
          url,
          headers: await _getHeaders(
            token: authData['token'],
            includeContentType: true,
          ),
          body: jsonEncode({
            "quantity": newQuantity,
            "cart_item_ids": [item.cartItemId],
          }),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _handleCartSync(json.decode(response.body));
        }
      } catch (e) {
        print('Update Error: $e');
      }
    }

    final updatedCart = List<CartItem>.from(state);
    updatedCart[itemIndex] = updatedCart[itemIndex].copyWith(
      quantity: newQuantity,
    );
    state = updatedCart;
  }

  void decrementQuantity(String productId) {
    final item = state.firstWhere((item) => item.product.id == productId);
    if (item.quantity > 1) {
      updateQuantity(productId, item.quantity - 1);
    } else {
      removeFromCart(productId);
    }
  }

  void incrementQuantity(String productId) {
    final item = state.firstWhere((item) => item.product.id == productId);
    updateQuantity(productId, item.quantity + 1);
  }

  Future<void> removeFromCart(String productId) async {
    final authData = await _getAuthData();
    final itemIndex = state.indexWhere((item) => item.product.id == productId);
    if (itemIndex < 0) return;

    final item = state[itemIndex];
    if (authData != null && item.cartItemId != null) {
      try {
        final baseUrl = AppConfig.cartUrl(authData['clientId']);
        final url = Uri.parse('$baseUrl/cart-items/delete');
        final response = await http.put(
          url,
          headers: await _getHeaders(
            token: authData['token'],
            includeContentType: true,
          ),
          body: jsonEncode({
            "cart_item_ids": [item.cartItemId],
          }),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _handleCartSync(json.decode(response.body));
        }
      } catch (e) {
        print('Delete Error: $e');
      }
    }
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clearCart() {
    state = [];
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  double total = 0;
  for (var item in cart) {
    total += item.product.price * item.quantity;
  }
  return total;
});

final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  int count = 0;
  for (var item in cart) {
    count += item.quantity;
  }
  return count;
});
