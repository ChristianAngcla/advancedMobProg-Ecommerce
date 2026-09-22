import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// LAB ACTIVITY 4 - ENHANCEMENT 3
// Profile Screen rendering saved user data from SharedPreferences and UserService
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    // Fetch saved user data from local device storage
    _userFuture = _userService.getUser();
  }

  // CONFIRMATION MODAL ENHANCEMENT
  // Displays a clean Material 3 confirmation dialog before logging out
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
            text: 'Are you sure you want to log out of your account?',
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
            // Confirm Destructive Action
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

                // Clear session data from SharedPreferences
                await _userService.logout();

                if (!context.mounted) return;

                // Navigate back to Sign-In and clear all route history
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

  // Helper widget to build clean, consistent information cards
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey.withAlpha(40)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 22.sp, color: const Color(0xFF0038A8)),
            SizedBox(width: 14.w),
            CustomText(
              text: label,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            const Spacer(),
            CustomText(
              text: value,
              fontSize: 13.sp,
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 48.sp, color: Colors.grey),
                  SizedBox(height: 12.h),
                  CustomText(
                    text: 'Unable to load user profile.',
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              children: [
                SizedBox(height: 12.h),

                // User Avatar
                Center(
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0038A8),
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 46.r,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: user.image.isNotEmpty
                          ? NetworkImage(user.image)
                          : null,
                      child: user.image.isEmpty
                          ? Icon(Icons.person, size: 46.sp, color: Colors.grey[600])
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // Full Name
                CustomText(
                  text: user.fullName.isNotEmpty ? user.fullName : user.username,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 4.h),

                // Username handle
                CustomText(
                  text: '@${user.username}',
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                ),
                SizedBox(height: 28.h),

                // Information Cards (Email, Gender, User ID)
                _buildInfoCard(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user.email,
                ),
                _buildInfoCard(
                  icon: Icons.wc_outlined,
                  label: 'Gender',
                  value: user.gender.isNotEmpty
                      ? '${user.gender[0].toUpperCase()}${user.gender.substring(1)}'
                      : 'N/A',
                ),
                _buildInfoCard(
                  icon: Icons.badge_outlined,
                  label: 'User ID',
                  value: user.id.toString(),
                ),
                SizedBox(height: 32.h),

                // Log Out Action Button
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252), // Coral / Red
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
              ],
            ),
          );
        },
      ),
    );
  }
}
