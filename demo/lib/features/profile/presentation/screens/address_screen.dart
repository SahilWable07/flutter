import 'package:flutter/material.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAddressCard(
            context,
            type: 'Home',
            name: 'John Doe',
            address: '123 Main Street, Apt 4B\nNew York, NY 10001\nUnited States',
            phone: '+1 234 567 8900',
            isDefault: true,
          ),
          const SizedBox(height: 16),
          _buildAddressCard(
            context,
            type: 'Work',
            name: 'John Doe',
            address: '456 Business Ave, Suite 100\nSan Francisco, CA 94107\nUnited States',
            phone: '+1 987 654 3210',
            isDefault: false,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          // Mock Action
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Address clicked')));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, {required String type, required String name, required String address, required String phone, required bool isDefault}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDefault ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(type == 'Home' ? Icons.home : Icons.work, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Default', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const Divider(height: 32),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(address, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 8),
            Text(phone, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
