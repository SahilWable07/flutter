class AppConfig {
  static const String baseUrl =
      'https://platform-development-dev.157.20.214.214.nip.io/auth/api';
  static const String defaultClientId = 'a3ea1cda-c735-4798-8219-54bbb07795a9';

  // Service-specific URL helpers
  static String productUrl(String clientId) =>
      '$baseUrl/product/client/$clientId';
  static String cartUrl(String clientId) => '$baseUrl/cart/client/$clientId';
  static String wishlistUrl(String clientId) =>
      '$baseUrl/wishlist/client/$clientId';
  static String get authUrl => '$baseUrl/auth/login';
  // Category / Subcategory endpoints (using the public route variant as requested)
  static String categoryUrl(String clientId) =>
      '$baseUrl/product-category/client/$clientId';
  static String subcategoryUrl(String clientId) =>
      '$baseUrl/product-subcategory/client/$clientId';
  static String orderUrl(String clientId) => '$baseUrl/order/client/$clientId';
  static String paymentGatewayUrl(String clientId) => '$baseUrl/payment-gateway/client/$clientId';
  static String paymentCredentialsUrl(String clientId) => '$baseUrl/client-payment-credentials/client/$clientId';
}
