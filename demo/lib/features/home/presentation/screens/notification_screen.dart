import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications list
    final notifications = [
      {'title': 'Order Shipped!', 'desc': 'Your order #12345 has been shipped.', 'time': '2 hours ago', 'icon': CupertinoIcons.cube_box, 'color': Colors.blue},
      {'title': 'Flash Sale', 'desc': 'Up to 50% off on electronics today!', 'time': '5 hours ago', 'icon': CupertinoIcons.tag, 'color': Colors.red},
      {'title': 'Welcome to E-Commerce', 'desc': 'Thanks for joining our platform.', 'time': '1 day ago', 'icon': CupertinoIcons.person_add, 'color': Colors.green},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications yet'))
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (notif['color'] as Color).withOpacity(0.1),
                    child: Icon(notif['icon'] as IconData, color: notif['color'] as Color),
                  ),
                  title: Text(notif['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notif['desc'] as String),
                  trailing: Text(notif['time'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () {
                    // Handle Notification tap
                  },
                );
              },
            ),
    );
  }
}
