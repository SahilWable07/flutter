import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../domain/models/order.dart';
import '../../../../core/config/app_config.dart';
import '../../../cart/domain/models/cart_item.dart';

class OrderNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    return [];
  }

  String _generateAlphanumericId(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
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
      'Origin': 'https://e-commerce-ai.lovable.app',
      'Referer': 'https://e-commerce-ai.lovable.app/',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
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
        if (clients.containsValue(AppConfig.defaultClientId) ||
            clients.containsKey(AppConfig.defaultClientId)) {
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

  Future<String?> createOrder({
    required List<CartItem> cartItems,
    required double total,
    required Map<String, dynamic>? userData,
  }) async {
    final authData = await _getAuthData();
    if (authData == null) return null;

    try {
      final userId = authData['userId'];
      final clientId = authData['clientId'];
      final token = authData['token'];

      final orderDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final deliveryDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().add(const Duration(days: 7)));
      final dueDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().add(const Duration(days: 1)));
      final billNum = "INV${_generateAlphanumericId(11)}";
      final trackNum = "TRK${_generateAlphanumericId(11)}";

      final address =
          (userData != null &&
              userData['user_address'] is List &&
              userData['user_address'].isNotEmpty)
          ? userData['user_address'][0]
          : {
              "house_no": "",
              "village": "",
              "street": "",
              "locality": "",
              "city": "",
              "state": "Maharashtra",
              "country": "India",
              "zip_code": "",
            };

      final payload = {
        "currency": "INR",
        "bill_number": billNum,
        "order_date": orderDate,
        "quotation_id": null,
        "payment_method": "cash",
        "payment_status": "pending",
        "paid_amount": 0,
        "gst": 0, // Global GST usually 0 as items have their own
        "shipping_fee": 0,
        "order_status": "confirmed",
        "tracking_number": trackNum,
        "delivery_date": deliveryDate,
        "due_date": dueDate,
        "price_type": "regular_price",
        "customer": {
          "first_name": userData?['first_name'] ?? "User",
          "last_name": userData?['last_name'] ?? "",
          "phone_number": userData?['phone'] ?? userData?['phoneNumber'] ?? "",
          "email": userData?['email'] ?? "",
          "country_code": "+91",
        },
        "order_items": cartItems.map((item) {
          return {
            "product_id": item.product.id,
            "product_variant_id": item.product.variantId.isNotEmpty
                ? item.product.variantId
                : null,
            "quantity": item.quantity,
            "discount_ids": [],
            "gst": 0,
          };
        }).toList(),
        "shipping_address": {
          "type": "D",
          "house_no": address['house_no']?.toString() ?? "",
          "village": address['village']?.toString() ?? "",
          "street": address['street']?.toString() ?? "",
          "locality": address['locality']?.toString() ?? "",
          "city": address['city']?.toString() ?? "",
          "state": address['state']?.toString() ?? "",
          "country": address['country']?.toString() ?? "India",
          "zip_code": address['zip_code']?.toString() ?? "",
        },
        "billing_address": {
          "type": "D",
          "house_no": address['house_no']?.toString() ?? "",
          "village": address['village']?.toString() ?? "",
          "street": address['street']?.toString() ?? "",
          "locality": address['locality']?.toString() ?? "",
          "city": address['city']?.toString() ?? "",
          "state": address['state']?.toString() ?? "",
          "country": address['country']?.toString() ?? "India",
          "zip_code": address['zip_code']?.toString() ?? "",
        },
        "client_id": clientId.toString(),
        "user_id": userId.toString(),
        "created_by": userId.toString(),
        "updated_by": userId.toString(),
        "payment_id": "",
      };

      final url = Uri.parse('${AppConfig.orderUrl(clientId)}/order');
      final response = await http.post(
        url,
        headers: await _getHeaders(token: token, includeContentType: true),
        body: jsonEncode(payload),
      );

      print('Order Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final orderId = (decoded['data'] is Map)
            ? decoded['data']['id']?.toString()
            : billNum;

        final mockOrder = Order(
          id: orderId ?? billNum,
          date: DateTime.now(),
          items: List.from(cartItems),
          totalAmount: total,
          status: OrderStatus.processing,
        );
        state = [mockOrder, ...state];
        return orderId ?? billNum;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['error'] ??
            errorData['message'] ??
            'Order creation failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Order API Error: $e');
      rethrow;
    }
  }
}

final ordersProvider = NotifierProvider<OrderNotifier, List<Order>>(() {
  return OrderNotifier();
});
