import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// LAB ACTIVITY 4 - ENHANCEMENT 3
// Profile Screen rendering saved user data from SharedPreferences and UserService
// LAB ACTIVITY 5 - ENHANCEMENT 3
// Displays profile details and account actions based on the user's login type.
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

  // LAB ACTIVITY 5 - Helper to refresh user profile data after changes
  void _refreshProfile() {
    setState(() {
      _userFuture = _userService.getUser();
    });
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

                // Clear session data from SharedPreferences and sign out Firebase
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

  // LAB ACTIVITY 5 - FIREBASE ACTION
  // Material 3 dialog allowing a Firebase user to update their username
  void _showEditUsernameDialog(BuildContext context, String currentUsername) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: currentUsername);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Row(
                children: [
                  const Icon(Icons.edit_outlined, color: Color(0xFF0038A8)),
                  SizedBox(width: 8.w),
                  CustomText(
                    text: 'Edit Username',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'New Username',
                    prefixIcon: const Icon(
                      Icons.alternate_email,
                      color: Color(0xFF0038A8),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: Color(0xFF0038A8),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    if (value.trim().length < 3) {
                      return 'At least 3 characters required';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value.trim())) {
                      return 'Letters, numbers, underscore, and period only';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: CustomText(
                    text: 'Cancel',
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0038A8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _userService.updateUsername(
                              username: controller.text.trim(),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            _refreshProfile();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Username updated successfully.',
                                ),
                                backgroundColor: Colors.green[700],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            final msg = e.toString().replaceFirst(
                              'Exception: ',
                              '',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : CustomText(
                          text: 'Save',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // LAB ACTIVITY 5 - FIREBASE ACTION
  // Material 3 dialog allowing a Firebase user to change their password
  void _showChangePasswordDialog(BuildContext context, String email) {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Row(
                children: [
                  const Icon(Icons.lock_reset, color: Color(0xFF0038A8)),
                  SizedBox(width: 8.w),
                  CustomText(
                    text: 'Change Password',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF0038A8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: Color(0xFF0038A8),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your current password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF0038A8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: Color(0xFF0038A8),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a new password';
                        }
                        if (value.trim().length < 6) {
                          return 'Must contain at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: CustomText(
                    text: 'Cancel',
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0038A8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _userService.resetPasswordFromCurrentPassword(
                              email: email,
                              currentPassword: currentPasswordController.text
                                  .trim(),
                              newPassword: newPasswordController.text.trim(),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Password updated successfully.',
                                ),
                                backgroundColor: Colors.green[700],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            final msg = e.toString().replaceFirst(
                              'Exception: ',
                              '',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : CustomText(
                          text: 'Update',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // LAB ACTIVITY 5 - FIREBASE ACTION
  // Destructive confirmation dialog requiring password before account deletion
  void _showDeleteAccountDialog(BuildContext context, String email) {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                  ),
                  SizedBox(width: 8.w),
                  CustomText(
                    text: 'Delete Account',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text:
                          'Deleting your Firebase account is permanent and cannot be undone. All stored profile details will be deleted.',
                      fontSize: 13.sp,
                      color: Colors.grey[800],
                    ),
                    SizedBox(height: 16.h),
                    CustomText(
                      text: 'Enter your password to confirm:',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.redAccent,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your password to confirm';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: CustomText(
                    text: 'Cancel',
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _userService.deleteAccount(
                              email: email,
                              password: passwordController.text.trim(),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Account deleted successfully.',
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            );
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/signin',
                              (route) => false,
                            );
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            final msg = e.toString().replaceFirst(
                              'Exception: ',
                              '',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : CustomText(
                          text: 'Delete Permanently',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                ),
              ],
            );
          },
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
            CustomText(text: value, fontSize: 13.sp, color: Colors.grey[700]),
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
                  Icon(
                    Icons.person_off_outlined,
                    size: 48.sp,
                    color: Colors.grey,
                  ),
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
                          ? (user.username.isNotEmpty
                                ? Text(
                                    user.username[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 34.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0038A8),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 46.sp,
                                    color: Colors.grey[600],
                                  ))
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // Full Name
                CustomText(
                  text: user.fullName.isNotEmpty
                      ? user.fullName
                      : user.username,
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
                SizedBox(height: 24.h),

                // LAB ACTIVITY 5 - ENHANCEMENT 3
                // Displays profile details and account actions based on the user's login type.
                _buildInfoCard(
                  icon: Icons.shield_outlined,
                  label: 'Account Type',
                  value: user.loginSourceLabel,
                ),

                if (user.isFirebaseUser) ...[
                  _buildInfoCard(
                    icon: Icons.alternate_email,
                    label: 'Username',
                    value: user.username,
                  ),
                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                  _buildInfoCard(
                    icon: Icons.person_outline,
                    label: 'First Name',
                    value: user.firstName.isNotEmpty ? user.firstName : 'N/A',
                  ),
                  _buildInfoCard(
                    icon: Icons.badge_outlined,
                    label: 'Last Name',
                    value: user.lastName.isNotEmpty ? user.lastName : 'N/A',
                  ),
                  _buildInfoCard(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: user.age != null ? user.age.toString() : 'N/A',
                  ),
                  _buildInfoCard(
                    icon: Icons.phone_android_outlined,
                    label: 'Contact Number',
                    value: user.contactNo.isNotEmpty ? user.contactNo : 'N/A',
                  ),
                ] else ...[
                  _buildInfoCard(
                    icon: Icons.badge_outlined,
                    label: 'User ID',
                    value: user.id.toString(),
                  ),
                  _buildInfoCard(
                    icon: Icons.alternate_email,
                    label: 'Username',
                    value: user.username,
                  ),
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
                ],

                // Firebase-only Account Action Buttons
                if (user.isFirebaseUser) ...[
                  SizedBox(height: 12.h),

                  // Edit Username
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF0038A8),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () =>
                          _showEditUsernameDialog(context, user.username),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF0038A8),
                      ),
                      label: CustomText(
                        text: 'Edit Username',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0038A8),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Change Password
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF0038A8),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () =>
                          _showChangePasswordDialog(context, user.email),
                      icon: const Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: Color(0xFF0038A8),
                      ),
                      label: CustomText(
                        text: 'Change Password',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0038A8),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Delete Account
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () =>
                          _showDeleteAccountDialog(context, user.email),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      label: CustomText(
                        text: 'Delete Account',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 24.h),

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
