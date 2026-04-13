import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../home/presentation/screens/main_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showCustomDialog(String title, String message, bool isError) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10.0, offset: Offset(0.0, 10.0))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isError ? Colors.red.shade50 : Colors.green.shade50, shape: BoxShape.circle),
                child: Icon(
                  isError ? Iconsax.info_circle_copy : Iconsax.tick_circle_copy,
                  color: isError ? Colors.red : Colors.green,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24.0),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12.0),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15.0, color: Colors.black54)),
              const SizedBox(height: 32.0),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: isError ? Colors.red : Colors.green, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(isError ? "Try Again" : "Okay", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        final error = ref.read(authProvider).error ?? 'Unexpected error occurred.';
        _showCustomDialog("Login Failed!", error, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final primaryColor = const Color(0xFF2874F0);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 320,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.8)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1), border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1)),
                          child: const Icon(Iconsax.bag_2_copy, size: 64, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        const Text('Welcome Back', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 6),
                        Text('Sign in to continue your journey', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -40),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))]),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Sign In', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Iconsax.sms_copy, color: primaryColor, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => (value == null || value.isEmpty) ? 'Email is required' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Iconsax.lock_copy, color: primaryColor, size: 20),
                            suffixIcon: IconButton(icon: Icon(_isPasswordVisible ? Iconsax.eye_copy : Iconsax.eye_slash_copy, color: Colors.grey, size: 20), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Password is required' : null,
                        ),
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: Text('Forgot Password?', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)))),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
                            child: authState.isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Don't have an account?", style: TextStyle(color: Colors.black54, fontSize: 15)), TextButton(onPressed: () {}, child: Text('Sign Up', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)))]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
