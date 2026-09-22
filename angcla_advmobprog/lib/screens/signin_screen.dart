import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// LAB ACTIVITY 4 - ENHANCEMENT 2
// Sign-In Screen with form validation, API authentication, and persistent storage.
// LAB ACTIVITY 5 - ENHANCEMENT 4
// Uses one normal login form and chooses Firebase or DummyJSON from the entered account identifier.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 2
  // LAB ACTIVITY 5 - ENHANCEMENT 4
  // Uses one normal login form and chooses Firebase or DummyJSON from the entered account identifier.
  void _login() async {
    // Validate text inputs before sending network request
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();
    final isEmail = identifier.contains('@');

    try {
      if (isEmail) {
        // Firebase Auth signInWithEmailAndPassword
        await _userService.signIn(email: identifier, password: password);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Navigate to Home screen upon successful Firebase login
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // DummyJSON POST /auth/login
        final response = await _userService.loginUser(identifier, password);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Navigate to Home screen upon successful DummyJSON login
        Navigator.pushReplacementNamed(context, '/home', arguments: response);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // ERROR HANDLING ENHANCEMENT
      // Display human-friendly error messages
      String userFriendlyMessage = e.toString().replaceFirst('Exception: ', '');
      final rawError = e.toString();

      if (!isEmail) {
        if (rawError.contains('SocketException') ||
            rawError.contains('ClientException')) {
          userFriendlyMessage =
              'Unable to reach server. Please check your internet connection.';
        } else if (rawError.contains('Invalid credentials')) {
          userFriendlyMessage = 'Incorrect username or password.';
        }
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

                  // Username or Email Address Input Field
                  CustomText(
                    text: 'Username or Email Address',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 6.h),
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'e.g. emilys or user@example.com',
                      helperText:
                          'Use your DummyJSON username or Firebase email address.',
                      helperMaxLines: 2,
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
                        return 'Please enter your username or email address';
                      }
                      final trimmed = value.trim();
                      if (trimmed.contains('@')) {
                        if (!RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        ).hasMatch(trimmed)) {
                          return 'Please enter a valid email format';
                        }
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
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
                      final identifier = _identifierController.text.trim();
                      if (identifier.contains('@') && value.trim().length < 6) {
                        return 'Password must contain at least 6 characters';
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : CustomText(
                              text: 'Sign In',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                    ),
                  ),

                  // Create Firebase Account option visible for all users
                  SizedBox(height: 20.h),
                  Center(
                    child: CustomText(
                      text: 'New user?',
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Center(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF0038A8),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: CustomText(
                        text: 'Create a Firebase account',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0038A8),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),
                  // Test account hint
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
