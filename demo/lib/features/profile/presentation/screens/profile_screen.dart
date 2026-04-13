import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'edit_profile_screen.dart';
import 'address_screen.dart';
import 'wishlist_screen.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/glass_container.dart';

// Import Auth to access the user session and login screen for logout
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../providers/user_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../order/presentation/providers/order_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoAsyncValue = ref.watch(userInfoProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: GlassContainer(
            borderRadius: 16,
            child: AppBar(
              title: const Text('My Profile'),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.m, 110, AppSpacing.m, 120),
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 4),
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF6366F1),
                  child: Icon(CupertinoIcons.person_solid, size: 50, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, size: 16, color: Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Center(
          child: Text(name, style: Theme.of(context).textTheme.headlineMedium),
        ),
        Center(
          child: Text(email, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Account Settings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.m),
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
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () async {
              ref.invalidate(userInfoProvider);
              ref.invalidate(cartProvider);
              ref.invalidate(ordersProvider);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, size: 20),
                SizedBox(width: 12),
                Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildProfileItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
        trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
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
        final curve = Curves.fastEaseInToSlowEaseOut;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
