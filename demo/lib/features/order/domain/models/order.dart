import '../../../cart/domain/models/cart_item.dart';

enum OrderStatus { pending, processing, delivered, cancelled }

class Order {
  final String id; // UUID for API calls
  final String billNumber; // For display (e.g. THE_2026...)
  final DateTime date;
  final List<CartItem> items;
  final double totalAmount;
  final OrderStatus status;

  Order({
    required this.id,
    required this.billNumber,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.pending,
  });
}
