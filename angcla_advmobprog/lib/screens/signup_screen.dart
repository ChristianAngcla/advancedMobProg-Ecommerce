import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// LAB ACTIVITY 5 - ENHANCEMENT 2
// Firebase sign-up screen that collects and validates registration details.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _contactNoController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // LAB ACTIVITY 5 - ENHANCEMENT 2
  // Validates user input and creates a new account using Firebase Auth
  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.createAccount(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        contactNo: _contactNoController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created successfully.'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );

      // Navigate to Home screen and clear navigation stack
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Display friendly error message without raw Firebase code prefix
      final friendlyError = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF0038A8)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF0038A8), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0038A8), // NU Blue
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // NU Logo
                Center(
                  child: Image.asset(
                    'assets/images/nu_logo.png',
                    width: 80.w,
                    height: 80.h,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.school,
                        size: 60.sp,
                        color: const Color(0xFF0038A8),
                      );
                    },
                  ),
                ),
                SizedBox(height: 12.h),

                // Heading & Subtitle
                Center(
                  child: CustomText(
                    text: 'Create your Firebase account',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Center(
                  child: CustomText(
                    text: 'Complete your details to register.',
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24.h),

                // First Name
                CustomText(
                  text: 'First Name',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. John',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your first name';
                    }
                    if (!RegExp(r'^[a-zA-Z\s-]+$').hasMatch(value.trim())) {
                      return 'Letters, spaces, and hyphens only';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Last Name
                CustomText(
                  text: 'Last Name',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. Doe',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your last name';
                    }
                    if (!RegExp(r'^[a-zA-Z\s-]+$').hasMatch(value.trim())) {
                      return 'Letters, spaces, and hyphens only';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Age
                CustomText(
                  text: 'Age',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. 20',
                    prefixIcon: Icons.cake_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value.trim());
                    if (age == null) {
                      return 'Numbers only';
                    }
                    if (age < 1 || age > 120) {
                      return 'Must be from 1 to 120';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Contact Number
                CustomText(
                  text: 'Contact Number',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _contactNoController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. 09123456789',
                    prefixIcon: Icons.phone_android_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your contact number';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                      return 'Numbers only';
                    }
                    if (!RegExp(r'^09\d{9}$').hasMatch(value.trim())) {
                      return 'Must be exactly 11 digits and start with 09';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Username
                CustomText(
                  text: 'Username',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. johndoe',
                    prefixIcon: Icons.alternate_email,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your username';
                    }
                    if (value.trim().length < 3) {
                      return 'At least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value.trim())) {
                      return 'Allow letters, numbers, underscore, and period only';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Email Address
                CustomText(
                  text: 'Email Address',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. john.doe@example.com',
                    prefixIcon: Icons.mail_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    ).hasMatch(value.trim())) {
                      return 'Must be a valid email format';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // Password
                CustomText(
                  text: 'Password',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _buildInputDecoration(
                    hintText: 'Minimum 6 characters',
                    prefixIcon: Icons.lock_outline,
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
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.trim().length < 6) {
                      return 'Must contain at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30.h),

                // Full-width NU Blue Create Account button with gold accent
                SizedBox(
                  height: 48.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0038A8), // NU Blue
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: Color(0xFFFFB81C), // NU Gold
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _createAccount,
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person_add_alt_1,
                                color: Color(0xFFFFB81C),
                              ),
                              SizedBox(width: 8.w),
                              CustomText(
                                text: 'Create Account',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
