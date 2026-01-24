import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // 🔹 Sign in user
      final user = await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user == null) {
        _showErrorDialog(
          'Login Error',
          'Login failed. Please check credentials.',
        );
        return;
      }

      // 🔹 Realtime Database reference
      final dbRef = FirebaseDatabase.instance.ref('users/${user.uid}');
      final snapshot = await dbRef.get();

      if (!snapshot.exists) {
        // User not found, create default
        await dbRef.set({
          'email': user.email,
          'role': 'user', // default role
          'createdAt': ServerValue.timestamp,
          'lastLogin': ServerValue.timestamp,
        });
      } else {
        // Update last login
        await dbRef.update({'lastLogin': ServerValue.timestamp});
      }

      // 🔹 Fetch role (case-insensitive)
      final role =
          snapshot.child('role').value?.toString().toLowerCase() ?? 'user';
      final isAdmin = role == 'admin';

      print("Role from DB: $role"); // 🔹 Debug
      print("isAdmin: $isAdmin"); // 🔹 Debug

      // 🔹 Navigate to HomeScreen with role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(isAdmin: isAdmin)),
      );
    } catch (e) {
      log("Login exception: $e");
      _showErrorDialog('Login Error', 'Something went wrong.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('Error', 'enterYourEmail'.tr());
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.sendPasswordResetEmail(_emailController.text.trim());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('emailSent'.tr())));
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Stack(
        children: [
          /// Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage(''), fit: BoxFit.cover),
            ),
          ),

          /// Blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          /// Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login to continue',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 30),

                      /// Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _inputField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              validator: (v) =>
                                  v!.contains('@') ? null : 'Invalid email',
                            ),
                            const SizedBox(height: 16),
                            _inputField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscure: !_isPasswordVisible,
                              suffix: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                }),
                              ),
                              validator: (v) =>
                                  v!.length < 6 ? 'Min 6 characters' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// Login Button
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: Colors.blueAccent,
                                ),
                                child: Text(
                                  'Login',
                                  style: TextStyle(fontSize: 18.sp),
                                ),
                              ),
                            ),

                      SizedBox(height: 12.h),

                      SizedBox(height: 12.h),
                      TextButton(
                        onPressed: _resetPassword,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),

                      SizedBox(height: 20.h),
                      const Divider(color: Colors.white38),

                      SizedBox(height: 15.h),
                      SignInButton(
                        Buttons.Google,
                        text: 'Sign in with Google',
                        onPressed: () => authService.signInWithGoogle(context),
                      ),

                      if (Platform.isIOS) ...[
                        SizedBox(height: 10.h),
                        SignInButton(
                          Buttons.Apple,
                          text: 'Sign in with Apple',
                          onPressed: () => authService.signInWithApple(),
                        ),
                      ],

                      SizedBox(height: 20.h),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Don't have an account? Sign up",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
