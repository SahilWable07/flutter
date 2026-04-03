import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Notifier to handle the login logic (Updated for Riverpod 3.x)
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // In Riverpod 3.x Notifier we can access providers via ref
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.login(email, password);
      state = state.copyWith(isLoading: false, user: response);
      return true; // Login successful
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false; // Login failed
    }
  }

  void logout() {
    state = AuthState();
  }
}

// The provider to use in your UI
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
