import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';

// Provides the repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// State class to hold loading/error/user data
class AuthState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, Map<String, dynamic>? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Don't use ?? so we can clear errors by passing null
      user: user ?? this.user,
    );
  }
}

// Notifier to handle the login logic
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _initPersistentLogin();
    return AuthState(isLoading: true); 
  }

  Future<void> _initPersistentLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userDataStr = prefs.getString('user_data');
      
      if (token != null && userDataStr != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payloadStr = _decodeBase64(parts[1]);
          final payloadMap = jsonDecode(payloadStr);
          
          final exp = payloadMap['exp'];
          if (exp != null) {
            final DateTime expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            if (expiryTime.isAfter(DateTime.now())) {
               // Token valid
               state = state.copyWith(isLoading: false, user: jsonDecode(userDataStr));
               return;
            }
          }
        }
      }
      // If we got here, no valid token or expired
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      state = state.copyWith(isLoading: false, user: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, user: null);
    }
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0: break;
      case 2: output += '=='; break;
      case 3: output += '='; break;
      default: throw Exception('Illegal base64url string!');
    }
    return utf8.decode(base64Url.decode(output));
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.login(email, password);
      
      final prefs = await SharedPreferences.getInstance();

      // Robust token traversal
      String tokenToSave = '';
      void findToken(dynamic obj) {
        if (obj is Map) {
          final keys = ['token', 'access_token', 'accessToken', 'id_token', 'jwt', 'data'];
          for (var k in keys) {
            if (obj.containsKey(k)) {
               if (obj[k] is String && obj[k].isNotEmpty) {
                 tokenToSave = obj[k];
                 return;
               } else if (obj[k] is Map) {
                 findToken(obj[k]);
                 if (tokenToSave.isNotEmpty) return;
               }
            }
          }
        }
      }
      findToken(response);
      
      if (tokenToSave.isEmpty) {
        // Log error if real endpoint lacks token
        print('CRITICAL: Login success but no token found in response: $response');
        state = AuthState(isLoading: false, error: 'Authorization error: token not found');
        return false;
      }

      await prefs.setString('auth_token', tokenToSave);
      await prefs.setString('user_data', jsonEncode(response));

      state = state.copyWith(isLoading: false, user: response);
      return true; // Login successful
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false; // Login failed
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    state = AuthState(); // Reset state
  }
}

// The provider to use in your UI
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
