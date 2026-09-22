import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// LAB ACTIVITY 4 - ENHANCEMENT 1
// Splash Screen with persistent authentication check.
// Displays the app logo and determines if the user is already logged in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // UI ENHANCEMENT: Subtle fade-in animation for branding entrance
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    // Start persistent authentication check
    _checkAuthentication();
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 1
  // Checks SharedPreferences to determine if user has a stored login session
  Future<void> _checkAuthentication() async {
    // Artificial 1.5s delay to showcase splash branding as requested in PDF
    await Future.delayed(const Duration(milliseconds: 1500));

    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final userData = await _userService.getUserData();
      if (!mounted) return;
      // User is authenticated: proceed straight to Home
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: userData,
      );
    } else {
      // No active session: redirect to Sign In screen
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // NUBD Exchange Branding Logo
              Image.asset(
                'assets/images/nu_logo.png',
                width: 140.w,
                height: 140.h,
                fit: BoxFit.contain,

                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.shopping_bag_outlined,
                    size: 80.sp,
                    color: const Color(0xFF0038A8),
                  );
                },
              ),
              SizedBox(height: 20.h),
              // App Title with Typography Hierarchy
              CustomText(
                text: 'NUBD Exchange',
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: 'Your Campus Marketplace',
                fontSize: 13.sp,
                color: Colors.grey[600],
              ),
              SizedBox(height: 36.h),
              // Loading Spinner in NU Blue
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0038A8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
