import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../../domain/models/order.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ordersProvider.notifier).fetchOrders());
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Order History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.cube_box, size: 80, color: Colors.grey.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Text('No orders found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(context, order, primaryColor);
              },
            ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.billNumber}', 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy').format(order.date), 
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(order.status),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${order.items.length} Items', style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('₹${order.totalAmount.toStringAsFixed(2)}', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showTimelineBottomSheet(context, order.id, primaryColor),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Timeline'),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimelineBottomSheet(BuildContext context, String orderId, Color primaryColor) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Order Tracking', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('ID: #$orderId', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 24),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: ref.read(ordersProvider.notifier).fetchOrderTimeline(orderId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No timeline data available', style: TextStyle(color: Colors.grey.shade400)));
                    }

                    final timeline = snapshot.data!;
                    return ListView.builder(
                      controller: controller,
                      itemCount: timeline.length,
                      itemBuilder: (context, index) {
                        final event = timeline[index];
                        final isLast = index == timeline.length - 1;
                        
                        // Resilient field mapping for timeline events
                        final status = (event['status'] ?? event['status_name'] ?? event['state'] ?? 'Update').toString();
                        final description = (event['remarks'] ?? event['remarks_name'] ?? event['comment'] ?? event['description'] ?? 'Order update processed').toString();
                        final rawDate = event['created_at'] ?? event['date'] ?? event['updated_at'];
                        
                        String formattedDate = 'Recent';
                        try {
                          if (rawDate != null) {
                            formattedDate = DateFormat('MMM dd, hh:mm a').format(DateTime.parse(rawDate.toString()));
                          }
                        } catch (_) {}

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: index == 0 ? primaryColor : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: index == 0 ? primaryColor : Colors.grey.shade300, width: 2),
                                    boxShadow: index == 0 ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
                                  ),
                                  child: index == 0 ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 50,
                                    color: index == 0 ? primaryColor.withOpacity(0.2) : Colors.grey.shade200,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: index == 0 ? Colors.black : Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(description, style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
                                  const SizedBox(height: 6),
                                  Text(formattedDate, style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String text;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Processing';
        break;
      case OrderStatus.processing:
        color = Colors.blue;
        text = 'In Transit';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = 'Delivered';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
