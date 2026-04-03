import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/order.dart';

class OrderNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    return [];
  }

  void addOrder(Order order) {
    state = [order, ...state];
  }
}

final ordersProvider = NotifierProvider<OrderNotifier, List<Order>>(() {
  return OrderNotifier();
});
