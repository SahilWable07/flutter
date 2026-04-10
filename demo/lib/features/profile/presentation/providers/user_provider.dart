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

  Future<Map<String, String>> _getHeaders(
      {required String token, bool includeContentType = false}) async {
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

  Future<Map<String, dynamic>> _getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) throw Exception('No authentication token found');

    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid authentication token');

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
  }

  Future<Map<String, dynamic>> _fetchUserInfo() async {
    final auth = await _getAuthData();
    final url = Uri.parse(
        '${AppConfig.baseUrl}/users/client/${auth['clientId']}/user/${auth['userId']}');

    final response = await http.get(
      url,
      headers: await _getHeaders(token: auth['token']),
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
      final auth = await _getAuthData();
      final url = Uri.parse(
          '${AppConfig.baseUrl}/users/client/${auth['clientId']}/user/${auth['userId']}/profile-info');

      // Map addresses to the exact structure in the short curl: all strings
      final addressJson = addresses.map((a) {
        final map = a.toJson();
        // Convert everything to string as per the user's short curl example
        return map.map((key, value) => MapEntry(key, value.toString()));
      }).toList();

      final response = await http.put(
        url,
        headers: await _getHeaders(token: auth['token'], includeContentType: true),
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
