class AppConfig {
  static const String baseUrl = 'https://platform-development-dev.157.20.214.214.nip.io/auth/api';
  static const String defaultClientId = '621916a4-c731-41b8-851d-06ac039a0c75';
  
  // Service-specific URL helpers
  static String productUrl(String clientId) => '$baseUrl/product/client/$clientId';
  static String cartUrl(String clientId) => '$baseUrl/cart/client/$clientId';
  static String wishlistUrl(String clientId) => '$baseUrl/wishlist/client/$clientId';
  static String get authUrl => '$baseUrl/auth/login';
}
