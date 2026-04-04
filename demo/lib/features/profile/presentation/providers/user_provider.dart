import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/models/user_address.dart';

class UserState {
  final AsyncValue<Map<String, dynamic>> userInfo;
  UserState({required this.userInfo});
}

class UserNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    return _fetchUserInfo();
  }

  Future<Map<String, dynamic>> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('No authentication token found');

    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid authentication token');

    String decodeBase64(String str) {
      String output = str.replaceAll('-', '+').replaceAll('_', '/');
      switch (output.length % 4) {
        case 0: break;
        case 2: output += '=='; break;
        case 3: output += '='; break;
        default: throw Exception('Illegal base64url string!');
      }
      return utf8.decode(base64Url.decode(output));
    }

    final payloadMap = jsonDecode(decodeBase64(parts[1]));
    final userId = payloadMap['user_id'];
    
    final clients = payloadMap['clients'] as Map?;
    final clientId = (clients != null && clients.keys.isNotEmpty) 
        ? clients.keys.first.toString() 
        : AppConfig.defaultClientId;

    if (userId == null) throw Exception('User ID not found in token');

    final url = Uri.parse('${AppConfig.baseUrl}/users/client/$clientId/user/$userId');
    
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json, text/plain, */*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      return data['user'] ?? data['data'] ?? data;
    } else {
      throw Exception('Failed to load user info: ${response.statusCode}');
    }
  }

  Future<void> updateAddresses(List<UserAddress> addresses) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception('Not logged in');

      final parts = token.split('.');
      final payloadMap = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final userId = payloadMap['user_id'];
      final clients = payloadMap['clients'] as Map?;
      final clientId = (clients != null && clients.keys.isNotEmpty) 
          ? clients.keys.first.toString() 
          : AppConfig.defaultClientId;

      final url = Uri.parse('${AppConfig.baseUrl}/users/client/$clientId/user/$userId/profile-info');
      
      // Map addresses to the exact structure in the short curl: all strings
      final addressJson = addresses.map((a) {
        final map = a.toJson();
        // Convert everything to string as per the user's short curl example
        return map.map((key, value) => MapEntry(key, value.toString()));
      }).toList();
      
      final response = await http.put(
        url,
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "user_address": addressJson,
          "addresses": addressJson,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        state = AsyncValue.data(await _fetchUserInfo());
      } else {
        throw Exception('Update failed: ${response.body}');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final userInfoProvider = AsyncNotifierProvider<UserNotifier, Map<String, dynamic>>(UserNotifier.new);
