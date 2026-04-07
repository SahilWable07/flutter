import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/features/profile/presentation/providers/user_provider.dart';
import 'package:demo/features/profile/domain/models/user_address.dart';
import 'package:demo/features/profile/presentation/screens/address_screen.dart';
import 'package:demo/features/cart/domain/models/cart_item.dart';
import 'package:demo/features/cart/presentation/providers/cart_provider.dart';
import 'package:demo/features/order/presentation/providers/order_provider.dart';
import 'package:demo/shared/utils/animated_popup.dart';
import 'package:demo/core/services/payment_service.dart';
import 'package:demo/core/config/app_config.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _currentStep = 0;
  UserAddress? _selectedAddress;
  String _selectedPayment = 'Pay on Delivery';

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final userInfoAsync = ref.watch(userInfoProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && _selectedAddress == null) {
            AnimatedPopup.show(context, message: 'Please select an address', color: Colors.orange);
            return;
          }
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _placeOrder(cartItems, total, userInfoAsync.value);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 32),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: details.onStepContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentStep == 2 ? 'Place Order' : 'Continue',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Address'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildAddressStep(userInfoAsync),
          ),
          Step(
            title: const Text('Payment'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildPaymentStep(),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: _buildReviewStep(cartItems, total),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep(AsyncValue<Map<String, dynamic>> userInfoAsync) {
    return userInfoAsync.when(
      data: (user) {
        final List<dynamic> addressRaw = user['user_address'] ?? user['addresses'] ?? [];
        final addresses = addressRaw.map((a) => UserAddress.fromJson(a)).toList();

        if (addresses.isEmpty) {
          return Column(
            children: [
              const Text('No addresses found'),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen())),
                child: const Text('Add Address'),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select delivery address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...addresses.map((addr) => RadioListTile<UserAddress>(
                  value: addr,
                  groupValue: _selectedAddress,
                  onChanged: (val) => setState(() => _selectedAddress = val),
                  title: Text(addr.tag, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${addr.houseNo}, ${addr.street}, ${addr.city}'),
                  secondary: const Icon(CupertinoIcons.location),
                  activeColor: Colors.indigo,
                  contentPadding: EdgeInsets.zero,
                )),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showAddressForm(context, allAddresses: addresses),
              icon: const Icon(Icons.add),
              label: const Text('Add New Address'),
            ),
          ],
        );
      },
      loading: () => const CupertinoActivityIndicator(),
      error: (e, __) => Text('Error: $e'),
    );
  }

  void _showAddressForm(BuildContext context, {required List<UserAddress> allAddresses}) {
    final houseController = TextEditingController();
    final streetController = TextEditingController();
    final cityController = TextEditingController();
    final zipController = TextEditingController();
    final tagController = TextEditingController(text: 'Home');

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
              const Text('Add Delivery Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

                    final currentList = List<UserAddress>.from(allAddresses);
                    currentList.add(newAddress);

                    Navigator.pop(context);
                    await ref.read(userInfoProvider.notifier).updateAddresses(currentList);
                    setState(() {
                      _selectedAddress = newAddress;
                    });
                  },
                  child: const Text('Save & Select'),
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

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select payment method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        RadioListTile<String>(
          value: 'Pay on Delivery',
          groupValue: _selectedPayment,
          onChanged: (val) => setState(() => _selectedPayment = val!),
          title: const Text('Pay on Delivery'),
          subtitle: const Text('Cash or UPI at your doorstep'),
          secondary: const Icon(CupertinoIcons.money_dollar),
        ),
        RadioListTile<String>(
          value: 'Online Payment',
          groupValue: _selectedPayment,
          onChanged: (val) => setState(() => _selectedPayment = val!),
          title: const Text('Credit/Debit Card / UPI'),
          subtitle: const Text('Fast & Secure checkout'),
          secondary: const Icon(CupertinoIcons.creditcard),
        ),
      ],
    );
  }

  Widget _buildReviewStep(List<CartItem> items, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Text('${item.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item.product.title)),
                  Text('\$${(item.product.price * item.quantity).toStringAsFixed(2)}'),
                ],
              ),
            )),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedAddress != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(CupertinoIcons.location, size: 16, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(child: Text('Shipping to: ${_selectedAddress!.tag}, ${_selectedAddress!.city}', style: const TextStyle(fontSize: 12))),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _placeOrder(List<CartItem> items, double total, Map<String, dynamic>? user) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CupertinoActivityIndicator()),
    );

    // 1. Create the order on the backend
    final orderId = await ref.read(ordersProvider.notifier).createOrder(
      cartItems: items,
      total: total,
      userData: user,
    );

    if (!mounted) return;
    Navigator.pop(context); // close loader

    if (orderId == null) {
      AnimatedPopup.show(context, message: 'Order creation failed.', color: Colors.red);
      return;
    }

    // 2. Handle Payment logic
    if (_selectedPayment == 'Online Payment') {
      // Get auth data for payment API
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      // Parse clientId and userId from token
      String clientId = AppConfig.defaultClientId;
      String userId = '';
      try {
        final payloadRaw = token.split('.')[1];
        final payloadMap = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(payloadRaw))));
        userId = payloadMap['user_id'] ?? '';
        final cl = payloadMap['clients'] as Map?;
        if (cl != null && cl.isNotEmpty) clientId = cl.keys.first;
      } catch (_) {}

      final error = await PaymentService.processEasebuzzPayment(
        clientId: clientId,
        userId: userId,
        token: token,
        amount: total,
        referenceId: orderId,
      );

      if (error != null) {
        AnimatedPopup.show(context, message: error, color: Colors.red);
      } else {
        // Redirection success
        ref.read(cartProvider.notifier).clearCart();
        Navigator.pop(context);
        AnimatedPopup.show(context, message: 'Redirecting to payment...');
      }
    } else {
      // Cash on Delivery
      ref.read(cartProvider.notifier).clearCart();
      Navigator.pop(context);
      AnimatedPopup.show(context, message: 'Order placed successfully!');
    }
  }
}
