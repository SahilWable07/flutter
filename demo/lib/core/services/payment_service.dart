import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class PaymentService {
  static Future<String?> processEasebuzzPayment({
    required String clientId,
    required String userId,
    required String token,
    required double amount,
    required String referenceId, // Order ID
  }) async {
    try {
      // 1. Fetch Client Payment Credentials
      final credsUrl = '${AppConfig.paymentCredentialsUrl(clientId)}?page=1&limit=10';
      final credsResponse = await http.get(
        Uri.parse(credsUrl),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Authorization': 'Bearer $token',
        },
      );

      if (credsResponse.statusCode < 200 || credsResponse.statusCode >= 300) {
        print('Failed to fetch credentials: ${credsResponse.body}');
        return 'Could not fetch payment credentials';
      }

      final credsData = jsonDecode(credsResponse.body);
      final List<dynamic> credsList = credsData['data'] ?? [];
      
      // Find Easebuzz credential
      final easebuzzCred = credsList.firstWhere(
        (c) => c['gateway']?.toString().toLowerCase() == 'easebuzz',
        orElse: () => null,
      );

      if (easebuzzCred == null) {
        return 'Easebuzz payment gateway not configured for this client';
      }

      final String paymentCredentialId = easebuzzCred['id'];
      final String providerId = easebuzzCred['provider_id'] ?? '';

      // 2. Generate Easebuzz Payment Link
      final generateUrl = '${AppConfig.paymentGatewayUrl(clientId)}/generate/link/easebuzz';
      final payload = {
        "amount": amount,
        "client_id": clientId,
        "user_id": userId,
        "payment_credential_id": paymentCredentialId,
        "provider_id": providerId,
        "gateway": "easebuzz",
        "reference_id": referenceId,
        "return_url": "https://development.d3kq8oy4csoq2n.amplifyapp.com/ecommerce/orders?payment_success=true&order_id=$referenceId",
        "payment_mode": "upi",
        "requested_by": userId,
        "date": DateTime.now().toIso8601String(),
        "type": "order",
        "payment_id": ""
      };

      final response = await http.post(
        Uri.parse(generateUrl),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        // Assuming the link is in 'data' or similar
        final String? paymentLink = data['data']?['url'] ?? data['payment_url'] ?? data['url'] ?? data['data'];

        if (paymentLink != null && await canLaunchUrl(Uri.parse(paymentLink))) {
          await launchUrl(Uri.parse(paymentLink), mode: LaunchMode.externalApplication);
          return null; // Success (link opened)
        } else {
          return 'Could not open payment link';
        }
      } else {
        print('Generate Link Error: ${response.body}');
        return 'Payment generation failed';
      }
    } catch (e) {
      print('Easebuzz Integration Error: $e');
      return e.toString();
    }
  }
}
