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
import 'package:demo/shared/widgets/status_views.dart';
import 'package:demo/core/constants/app_spacing.dart';

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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && _selectedAddress == null) {
            AnimatedPopup.show(context, message: 'Please select a delivery address', icon: Icons.location_on);
            return;
          }
          if (_currentStep == 1 && _selectedPayment == 'Online Payment') {
            _placeOrder(cartItems, total, userInfoAsync.value);
          } else if (_currentStep < 2) {
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
              height: 56,
              child: ElevatedButton(
                onPressed: details.onStepContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
                child: Text(
                  _currentStep == 1 && _selectedPayment == 'Online Payment'
                    ? 'Proceed to Payment'
                    : (_currentStep == 2 
                        ? (_selectedPayment == 'Online Payment' ? 'Pay Now' : 'Confirm Order')
                        : 'Continue'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Address', style: TextStyle(fontSize: 12)),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildAddressStep(userInfoAsync),
          ),
          Step(
            title: const Text('Payment', style: TextStyle(fontSize: 12)),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildPaymentStep(),
          ),
          Step(
            title: const Text('Review', style: TextStyle(fontSize: 12)),
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
          return Center(
            child: Column(
              children: [
                const Icon(CupertinoIcons.location_slash, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No addresses found', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddressForm(context, allAddresses: addresses),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Address'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...addresses.map((addr) {
              final String addrId = '${addr.tag}_${addr.houseNo}_${addr.zipCode}';
              final String selectedId = _selectedAddress != null 
                  ? '${_selectedAddress!.tag}_${_selectedAddress!.houseNo}_${_selectedAddress!.zipCode}' 
                  : '';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedId == addrId ? Theme.of(context).primaryColor : Colors.grey.shade200,
                    width: 2,
                  ),
                ),
                child: RadioListTile<String>(
                  value: addrId,
                  groupValue: selectedId,
                  onChanged: (val) {
                    setState(() {
                      _selectedAddress = addr;
                    });
                  },
                  title: Text(
                    addr.tag.isNotEmpty ? addr.tag : 'Address', 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text('${addr.houseNo}, ${addr.street}, ${addr.city}'),
                  secondary: Icon(CupertinoIcons.location_solid, color: selectedId == addrId ? Theme.of(context).primaryColor : Colors.grey),
                  activeColor: Theme.of(context).primaryColor,
                  contentPadding: const EdgeInsets.all(8),
                ),
              );
            }),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddressForm(context, allAddresses: addresses),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add New Address'),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, __) => ErrorView(
        message: 'Unable to load profile info. Please try again.',
        onRetry: () => ref.refresh(userInfoProvider),
      ),
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Address', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              _buildField('Tag (Home/Work)', tagController, icon: Icons.tag),
              _buildField('House / Flat No', houseController, icon: Icons.home_outlined),
              _buildField('Street / Locality', streetController, icon: Icons.map_outlined),
              _buildField('City', cityController, icon: Icons.location_city_outlined),
              _buildField('Zip Code', zipController, icon: Icons.pin_drop_outlined, isNumber: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (houseController.text.isEmpty || cityController.text.isEmpty || zipController.text.isEmpty) {
                      AnimatedPopup.show(context, message: 'Please fill required fields', color: Colors.orange);
                      return;
                    }
                    
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
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('Save Address'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {IconData? icon, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildPaymentOption('Pay on Delivery', 'Cash or UPI on delivery', CupertinoIcons.money_dollar_circle),
        _buildPaymentOption('Online Payment', 'Fast & Secure checkout', CupertinoIcons.creditcard_fill),
      ],
    );
  }

  Widget _buildPaymentOption(String value, String sub, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _selectedPayment == value ? Theme.of(context).primaryColor : Colors.grey.shade200, width: 2),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPayment,
        onChanged: (val) => setState(() => _selectedPayment = val!),
        title: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        secondary: Icon(icon, color: _selectedPayment == value ? Theme.of(context).primaryColor : Colors.grey),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildReviewStep(List<CartItem> items, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.product.title, style: const TextStyle(fontSize: 14))),
                        Text('\$${(item.product.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.indigo)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedAddress != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.indigo.withOpacity(0.1))),
            child: Row(
              children: [
                const Icon(CupertinoIcons.location_solid, size: 18, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(child: Text('Shipping to: ${_selectedAddress!.houseNo}, ${_selectedAddress!.city}', style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.w500))),
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

    String? orderId;
    try {
      orderId = await ref.read(ordersProvider.notifier).createOrder(
        cartItems: items,
        total: total,
        userData: user,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loader
      AnimatedPopup.show(context, message: 'Process failed. Please verify your address info.', color: Colors.redAccent);
      return;
    }

    if (!mounted) return;
    Navigator.pop(context); // close loader

    if (orderId == null) {
      AnimatedPopup.show(context, message: 'Order creation failed.', color: Colors.red);
      return;
    }

    if (_selectedPayment == 'Online Payment') {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
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
        clientId: clientId, userId: userId, token: token, amount: total, referenceId: orderId,
      );

      if (error != null) {
        AnimatedPopup.show(context, message: error, color: Colors.red);
      } else {
        ref.read(cartProvider.notifier).clearCart();
        Navigator.pop(context);
        AnimatedPopup.show(context, message: 'Redirecting to payment...');
      }
    } else {
      ref.read(cartProvider.notifier).clearCart();
      Navigator.pop(context);
      AnimatedPopup.show(context, message: 'Order placed successfully!');
    }
  }
}
