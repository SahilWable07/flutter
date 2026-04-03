import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'edit_profile_screen.dart';
import 'address_screen.dart';
import 'wishlist_screen.dart';

// Import Auth to access the user session and login screen for logout
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsyncValue = ref.watch(userInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: userInfoAsyncValue.when(
        data: (user) {
          final String firstName = user['first_name'] ?? 'User';
          final String lastName = user['last_name'] ?? '';
          final String name = '$firstName $lastName'.trim();
          final String email = user['email'] ?? 'No email';
          final String phone = user['phone'] ?? 'No phone';

          return _buildProfileBody(context, ref, name, email, phone);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildProfileBody(BuildContext context, WidgetRef ref, String name, String email, String phone) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.indigo,
              child: Icon(CupertinoIcons.person_solid, size: 50, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Center(
          child: Text(email, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ),
        Center(
          child: Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
          const SizedBox(height: 32),
          _buildProfileItem(context, icon: CupertinoIcons.location, title: 'Shipping Addresses', onTap: () {
            Navigator.push(context, _buildSlideTransition(const AddressScreen()));
          }),
          _buildProfileItem(context, icon: CupertinoIcons.creditcard, title: 'Payment Methods', onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Methods coming soon!')));
          }),
          _buildProfileItem(context, icon: CupertinoIcons.heart, title: 'Wishlist', onTap: () {
             Navigator.push(context, _buildSlideTransition(const WishlistScreen()));
          }),
          _buildProfileItem(context, icon: CupertinoIcons.settings, title: 'Settings', onTap: () {
             Navigator.push(context, _buildSlideTransition(const EditProfileScreen()));
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                // 1. Clear session
                ref.read(authProvider.notifier).logout();
                
                // 2. Erase routing history and push back to LoginScreen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          )
        ],
      );
  }

  Widget _buildProfileItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200)
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: const Icon(CupertinoIcons.chevron_right, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  PageRouteBuilder _buildSlideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.fastOutSlowIn));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
