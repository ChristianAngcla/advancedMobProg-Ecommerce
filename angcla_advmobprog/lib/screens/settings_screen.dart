import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // LAB ACTIVITY 5 - ENHANCEMENT 3
  // Provides the required Settings logout action and clears the active session.
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              const Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 8.w),
              CustomText(
                text: 'Log Out',
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          content: CustomText(
            text: 'Are you sure you want to log out?',
            fontSize: 14.sp,
            color: Colors.grey[700],
          ),
          actions: [
            // Cancel Action
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: CustomText(
                text: 'Cancel',
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            // Confirm Logout Action
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog

                // Call UserService().logout() to sign out Firebase or DummyJSON
                await UserService().logout();

                if (!context.mounted) return;

                // Navigate to /signin and remove all previous screens
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/signin',
                  (route) => false,
                );
              },
              child: CustomText(
                text: 'Log Out',
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Enhancement 3: watch ThemeProvider so the switch updates when theme changes
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Settings',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // Enhancement 3: Add settings page to move the dark/light mode switch
                  SwitchListTile(
                    title: CustomText(
                      text: themeProvider.isDark ? 'Dark Mode' : 'Light Mode',
                      fontSize: 16.sp,
                    ),
                    value: themeProvider.isDark,
                    onChanged: (_) {
                      // Enhancement 3: toggle light/dark theme via Provider
                      themeProvider.toggleTheme();
                    },
                  ),
                ],
              ),
            ),

            // LAB ACTIVITY 5 - ENHANCEMENT 3
            // Clearly visible red Log Out button near the bottom of the screen
            Padding(
              padding: EdgeInsets.all(16.w),
              child: SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5252), // Red
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 1,
                  ),
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, size: 18),
                  label: CustomText(
                    text: 'Log Out',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
