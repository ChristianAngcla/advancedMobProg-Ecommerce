import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// LAB ACTIVITY 4 - ENHANCEMENT 2
// Sign-In Screen with form validation, API authentication, and persistent storage.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 2
  // Authentication handler: validates form, calls UserService.loginUser, and navigates on success
  void _login() async {
    // Validate text inputs before sending network request
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Call UserService to authenticate against DummyJSON POST /auth/login
      final response = await _userService.loginUser(
        _usernameController.text,
        _passwordController.text,
      );

      // 2. Persistent storage: UserService.loginUser automatically saves to SharedPreferences
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // 3. Navigate to Home screen upon successful authentication
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: response,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // ERROR HANDLING ENHANCEMENT
      // Display a human-friendly message instead of raw technical exceptions
      String userFriendlyMessage = 'Invalid username or password. Please try again.';
      final rawError = e.toString();

      if (rawError.contains('SocketException') || rawError.contains('ClientException')) {
        userFriendlyMessage = 'Unable to reach server. Please check your internet connection.';
      } else if (rawError.contains('Invalid credentials')) {
        userFriendlyMessage = 'Incorrect username or password.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // UI ENHANCEMENT: Generous horizontal padding for responsive layout
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // NUBD Exchange Branding Logo
                  Center(
                    child: Image.asset(
                      'assets/images/nu_logo.png',
                      width: 100.w,
                      height: 100.h,
                      fit: BoxFit.contain,

                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.school,
                          size: 70.sp,
                          color: const Color(0xFF0038A8),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Header Typography
                  Center(
                    child: CustomText(
                      text: 'Welcome',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Center(
                    child: CustomText(
                      text: 'Sign in to your NUBD Exchange account',
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Username Input Field
                  CustomText(
                    text: 'Username',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 6.h),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. emilys',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 18.h),

                  // Password Input Field with Visibility Toggle
                  CustomText(
                    text: 'Password',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 6.h),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      // UI ENHANCEMENT: Eye toggle button for password visibility
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 28.h),

                  // Log In Action Button
                  SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0038A8), // NU Blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? SizedBox(
                              width: 22.w,
                              height: 22.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : CustomText(
                              text: 'Log in',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                    ),
                  ),

                  SizedBox(height: 20.h),
                  // Helpful tip for student testing
                  Center(
                    child: CustomText(
                      text: 'Test account: emilys / emilyspass',
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
