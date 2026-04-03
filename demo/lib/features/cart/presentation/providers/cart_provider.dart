import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cart_item.dart';
import '../../../product/domain/models/product.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  void addToCart(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      // Increase quantity
      final updatedCart = List<CartItem>.from(state);
      updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(
        quantity: updatedCart[existingIndex].quantity + 1,
      );
      state = updatedCart;
    } else {
      // Add new item
      state = [...state, CartItem(product: product)];
    }
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void decrementQuantity(String productId) {
    final existingIndex = state.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      final currentQuantity = state[existingIndex].quantity;
      if (currentQuantity > 1) {
        final updatedCart = List<CartItem>.from(state);
        updatedCart[existingIndex] = updatedCart[existingIndex].copyWith(
          quantity: currentQuantity - 1,
        );
        state = updatedCart;
      } else {
        removeFromCart(productId);
      }
    }
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0, (total, current) => total + (current.product.price * current.quantity));
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider.notifier).totalAmount;
});
