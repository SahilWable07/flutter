import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:demo/core/config/app_config.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse(AppConfig.authUrl);
    
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json',
        'client_id': AppConfig.defaultClientId,
        'Origin': 'https://platform-dev.baap.market',
        'Referer': 'https://platform-dev.baap.market/',
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }
}
