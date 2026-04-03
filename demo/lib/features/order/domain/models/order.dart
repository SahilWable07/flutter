import '../../../cart/domain/models/cart_item.dart';

enum OrderStatus { pending, processing, delivered, cancelled }

class Order {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double totalAmount;
  final OrderStatus status;

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.pending,
  });
}
