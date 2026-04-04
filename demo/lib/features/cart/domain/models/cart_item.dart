import '../../../product/domain/models/product.dart';

class CartItem {
  final String? cartItemId; // The unique ID from the backend cart
  final Product product;
  final int quantity;

  CartItem({this.cartItemId, required this.product, this.quantity = 1});

  CartItem copyWith({String? cartItemId, Product? product, int? quantity}) {
    return CartItem(
      cartItemId: cartItemId ?? this.cartItemId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
