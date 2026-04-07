import 'dart:convert';
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
      final targetClientId = (clients != null && clients.keys.isNotEmpty) 
          ? clients.keys.first.toString() : AppConfig.defaultClientId;
      
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
      final deliveryDate = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 7)));
      final billNum = "INV${DateTime.now().millisecondsSinceEpoch}";
      final trackNum = "TRK${DateTime.now().millisecondsSinceEpoch}";

      final address = (userData != null && userData['user_address'] is List && userData['user_address'].isNotEmpty) 
          ? userData['user_address'][0] 
          : {
              "house_no": "",
              "village": "",
              "street": "",
              "locality": "",
              "city": "",
              "state": "",
              "country": "India",
              "zip_code": ""
            };

      final payload = {
        "currency": "INR",
        "bill_number": billNum,
        "order_date": orderDate,
        "quotation_id": null,
        "payment_method": "online",
        "payment_status": "pending",
        "paid_amount": 0,
        "gst": 0,
        "shipping_fee": 0,
        "order_status": "pending",
        "tracking_number": trackNum,
        "delivery_date": deliveryDate,
        "due_date": orderDate,
        "price_type": "regular_price",
        "customer": {
          "first_name": userData?['first_name'] ?? "User",
          "last_name": userData?['last_name'] ?? "",
          "phone_number": userData?['phone'] ?? "",
          "email": userData?['email'] ?? "",
          "country_code": "+91"
        },
        "order_items": cartItems.map((item) => {
          "product_id": item.product.id,
          "product_variant_id": item.product.variantId,
          "quantity": item.quantity,
          "gst": 0,
          "discount": 0,
          "discount_type": "percentage"
        }).toList(),
        "shipping_address": {
          "house_no": address['house_no']?.toString() ?? "",
          "village": address['village']?.toString() ?? "",
          "street": address['street']?.toString() ?? "",
          "locality": address['locality']?.toString() ?? "",
          "city": address['city']?.toString() ?? "",
          "state": address['state']?.toString() ?? "",
          "country": address['country']?.toString() ?? "India",
          "zip_code": address['zip_code']?.toString() ?? ""
        },
        "billing_address": {
          "house_no": address['house_no']?.toString() ?? "",
          "village": address['village']?.toString() ?? "",
          "street": address['street']?.toString() ?? "",
          "locality": address['locality']?.toString() ?? "",
          "city": address['city']?.toString() ?? "",
          "state": address['state']?.toString() ?? "",
          "country": address['country']?.toString() ?? "India",
          "zip_code": address['zip_code']?.toString() ?? ""
        },
        "client_id": clientId,
        "user_id": userId,
        "created_by": userId,
        "updated_by": userId,
        "payment_id": ""
      };

      final url = Uri.parse('${AppConfig.orderUrl(clientId)}/order');
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      print('Order Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final orderId = (decoded['data'] is Map) ? decoded['data']['id']?.toString() : billNum;

        final mockOrder = Order(
          id: orderId ?? billNum,
          date: DateTime.now(),
          items: List.from(cartItems),
          totalAmount: total,
          status: OrderStatus.processing,
        );
        state = [mockOrder, ...state];
        return orderId ?? billNum;
      }
      return null;
    } catch (e) {
      print('Order API Error: $e');
      return null;
    }
  }
}

final ordersProvider = NotifierProvider<OrderNotifier, List<Order>>(() {
  return OrderNotifier();
});
