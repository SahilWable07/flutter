import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthRepository {
  // Hardcoded client id as requested
  static const String _clientId = 'a3ea1cda-c735-4798-8219-54bbb07795a9';
  static const String _baseUrl = 'https://platform-development-dev.157.20.214.214.nip.io/auth/api';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json',
        'client_id': _clientId, // Passing client_id in headers (modify if it needs to be 'X-Client-Id')
        // Optional headers from your curl
        'Origin': 'https://development.d3kq8oy4csoq2n.amplifyapp.com',
        'Referer': 'https://development.d3kq8oy4csoq2n.amplifyapp.com/',
      },
      body: jsonEncode({
        "email": email,
        "password": password,
        "captchaToken": null,
        "client_id": _clientId, // Also passing in body just in case the API expects it here
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }
}
