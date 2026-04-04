import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../../domain/models/user_address.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  @override
  Widget build(BuildContext context) {
    final userInfoAsync = ref.watch(userInfoProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('My Addresses'), centerTitle: true),
      body: userInfoAsync.when(
        data: (user) {
          final List<dynamic> addressRaw = user['user_address'] ?? 
                                           user['addresses'] ?? [];
          final addresses = addressRaw.map((a) => UserAddress.fromJson(a)).toList();

          if (addresses.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final a = addresses[index];
              return _buildAddressCard(context, a, index: index, allAddresses: addresses);
            },
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: userInfoAsync.maybeWhen(
        data: (user) {
          final List<dynamic> addressRaw = user['user_address'] ?? user['addresses'] ?? [];
          final addresses = addressRaw.map((a) => UserAddress.fromJson(a)).toList();
          return FloatingActionButton(
            backgroundColor: Theme.of(context).primaryColor,
            onPressed: () => _showAddressForm(context, allAddresses: addresses),
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildEmptyState() {
     return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.location, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No addresses yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Add a delivery address to get started', style: TextStyle(color: Colors.grey)),
          ],
        ),
     );
  }

  Widget _buildAddressCard(BuildContext context, UserAddress address, {required int index, required List<UserAddress> allAddresses}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(address.tag.toLowerCase() == 'home' ? CupertinoIcons.house : CupertinoIcons.briefcase, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(address.tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 24),
            Text(
              '${address.houseNo}, ${address.street}\n${address.village}, ${address.city}\n${address.state}, ${address.country}\n${address.zipCode}',
              style: const TextStyle(height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showAddressForm(context, address: address, index: index, allAddresses: allAddresses),
                  icon: const Icon(CupertinoIcons.pencil, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteAddress(index, allAddresses),
                  icon: const Icon(CupertinoIcons.trash, size: 16, color: Colors.redAccent),
                  label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showAddressForm(BuildContext context, {UserAddress? address, int? index, List<UserAddress>? allAddresses}) {
    final houseController = TextEditingController(text: address?.houseNo ?? '');
    final streetController = TextEditingController(text: address?.street ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    final zipController = TextEditingController(text: address?.zipCode ?? '');
    final tagController = TextEditingController(text: address?.tag ?? 'Home');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(address == null ? 'Add Delivery Address' : 'Edit Address', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildField('Tag (Home/Work)', tagController),
              _buildField('House No', houseController),
              _buildField('Street/Road', streetController),
              _buildField('City', cityController),
              _buildField('Zip Code', zipController),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final newAddress = UserAddress(
                      type: 'D',
                      tag: tagController.text,
                      houseNo: houseController.text,
                      street: streetController.text,
                      city: cityController.text,
                      zipCode: zipController.text,
                      village: cityController.text, 
                      locality: '',
                      state: 'Maharashtra', 
                      country: 'India',
                    );

                    final currentList = allAddresses != null ? List<UserAddress>.from(allAddresses) : <UserAddress>[];
                    if (index != null) {
                      currentList[index] = newAddress;
                    } else {
                      currentList.add(newAddress);
                    }

                    Navigator.pop(context);
                    await ref.read(userInfoProvider.notifier).updateAddresses(currentList);
                  },
                  child: const Text('Save Address'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  void _deleteAddress(int index, List<UserAddress> allAddresses) async {
    final newList = List<UserAddress>.from(allAddresses);
    newList.removeAt(index);
    await ref.read(userInfoProvider.notifier).updateAddresses(newList);
  }
}
