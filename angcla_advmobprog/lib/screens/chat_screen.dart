import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/message.dart';
import '../services/chat_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detail_screen.dart';

// LAB ACTIVITY 6 - ENHANCEMENT 1
// LAB ACTIVITY 6 - ENHANCEMENT 2
// LAB ACTIVITY 6 - ENHANCEMENT 4
// Screen displaying the list of all registered Firebase users for direct messaging.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to extract a displayable name from user document fields
  String _getDisplayName(Map<String, dynamic> user) {
    final firstName = user['firstName']?.toString().trim() ?? '';
    final lastName = user['lastName']?.toString().trim() ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    final username = user['username']?.toString().trim() ?? '';
    if (username.isNotEmpty) {
      return username;
    }
    final email = user['email']?.toString().trim() ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'NU User';
  }

  // Helper to extract the first letter initial for the user avatar
  String _getInitial(Map<String, dynamic> user) {
    final name = _getDisplayName(user);
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'U';
  }

  // LAB ACTIVITY 6 - ENHANCEMENT 4
  // Helper to format Firestore timestamp for the user card
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final DateTime dt = timestamp.toDate();
    final int hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final String minute = dt.minute.toString().padLeft(2, '0');
    final String period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Guard: NU Connect is available only for Firebase authenticated users
    if (currentUser == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(22.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0038A8).withAlpha(20),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFB81C),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.forum_outlined,
                      size: 52.sp,
                      color: const Color(0xFF0038A8),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  CustomText(
                    text: 'NU Connect is available for Firebase accounts.',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                    color: const Color(0xFF0038A8),
                  ),
                  SizedBox(height: 8.h),
                  CustomText(
                    text:
                        'Sign in with a Firebase account to chat with other users.',
                    fontSize: 13.sp,
                    textAlign: TextAlign.center,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Polished NU Connect Header
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 14.h),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withAlpha(30),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0038A8).withAlpha(20),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFFFB81C),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.forum_rounded,
                      color: const Color(0xFF0038A8),
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: 'NU Connect',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0038A8),
                        ),
                        SizedBox(height: 2.h),
                        CustomText(
                          text: 'Connect with fellow users.',
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Rounded Search Bar
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, username, or email...',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.sp,
                    color: Colors.grey[500],
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF0038A8),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: const BorderSide(
                      color: Color(0xFF0038A8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Real-time Users List from Firestore
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getUsersStream(),
                builder: (context, snapshot) {
                  // Loading State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF0038A8),
                        ),
                      ),
                    );
                  }

                  // Error State
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48.sp,
                              color: Colors.redAccent,
                            ),
                            SizedBox(height: 12.h),
                            CustomText(
                              text: 'Unable to load users',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(height: 6.h),
                            CustomText(
                              text:
                                  'Please check your connection and try again.',
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allUsers = snapshot.data ?? [];

                  // Exclude the current signed-in Firebase user
                  final otherUsers = allUsers.where((u) {
                    final uid = u['uid']?.toString() ?? '';
                    return uid.isNotEmpty && uid != currentUser.uid;
                  }).toList();

                  // Empty State: No other users in database
                  if (otherUsers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 52.sp,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 12.h),
                            CustomText(
                              text: 'No other users found',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(height: 6.h),
                            CustomText(
                              text:
                                  'Other registered Firebase users will appear here.',
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Filter users based on search query
                  final filteredUsers = otherUsers.where((u) {
                    if (_searchQuery.isEmpty) return true;
                    final firstName = (u['firstName']?.toString() ?? '')
                        .toLowerCase();
                    final lastName = (u['lastName']?.toString() ?? '')
                        .toLowerCase();
                    final fullName = '$firstName $lastName'.trim();
                    final username = (u['username']?.toString() ?? '')
                        .toLowerCase();
                    final email = (u['email']?.toString() ?? '').toLowerCase();

                    return fullName.contains(_searchQuery) ||
                        firstName.contains(_searchQuery) ||
                        lastName.contains(_searchQuery) ||
                        username.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();

                  // No Search Results State
                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48.sp,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 12.h),
                            CustomText(
                              text: 'No users matching "$_searchQuery"',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(height: 6.h),
                            CustomText(
                              text:
                                  'Try searching by name, username, or email.',
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // User Cards List with Smooth Animations and Live Previews
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final otherUserId = user['uid']?.toString() ?? '';
                      final displayName = _getDisplayName(user);
                      final initial = _getInitial(user);
                      final email = user['email']?.toString() ?? '';

                      return Card(
                        elevation: 1,
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 6.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          side: BorderSide(color: Colors.grey.withAlpha(30)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatDetailScreen(receiverUser: user),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            child:
                                // LAB ACTIVITY 6 - ENHANCEMENT 4:
                                // Live message stream per direct chat room for latest preview and unread count
                                StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>
                                >(
                                  stream: _chatService.getMessages(
                                    currentUser.uid,
                                    otherUserId,
                                    descending: true,
                                  ),
                                  builder: (context, msgSnapshot) {
                                    final docs = msgSnapshot.data?.docs ?? [];
                                    String previewText = 'No messages yet';
                                    String latestTime = '';
                                    int unreadCount = 0;

                                    if (docs.isNotEmpty) {
                                      final latestData = docs.first.data();
                                      final latestMsg = Message.fromMap(
                                        latestData,
                                      );
                                      final bool isSentByMe =
                                          latestMsg.senderId == currentUser.uid;

                                      previewText = isSentByMe
                                          ? 'You: ${latestMsg.message}'
                                          : latestMsg.message;
                                      latestTime = _formatTimestamp(
                                        latestMsg.timestamp,
                                      );

                                      // Actual Firestore unread messages where receiverId is currentUser
                                      unreadCount = docs.where((doc) {
                                        final d = doc.data();
                                        return d['receiverId'] ==
                                                currentUser.uid &&
                                            d['isRead'] != true;
                                      }).length;
                                    }

                                    return Row(
                                      children: [
                                        // Initial-based Avatar with NU Blue Ring and Gold Accent
                                        Stack(
                                          children: [
                                            Container(
                                              width: 48.r,
                                              height: 48.r,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF0038A8,
                                                  ),
                                                  width: 2,
                                                ),
                                                color: const Color(
                                                  0xFF0038A8,
                                                ).withAlpha(25),
                                              ),
                                              child: Center(
                                                child: CustomText(
                                                  text: initial,
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF0038A8,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                width: 12.r,
                                                height: 12.r,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFFB81C,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Theme.of(
                                                      context,
                                                    ).cardColor,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 14.w),

                                        // Name, Email, and Real Latest-Message Preview
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: CustomText(
                                                      text: displayName,
                                                      fontSize: 15.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (latestTime
                                                      .isNotEmpty) ...[
                                                    SizedBox(width: 6.w),
                                                    CustomText(
                                                      text: latestTime,
                                                      fontSize: 11.sp,
                                                      color: unreadCount > 0
                                                          ? const Color(
                                                              0xFF0038A8,
                                                            )
                                                          : Colors.grey[500],
                                                      fontWeight:
                                                          unreadCount > 0
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              SizedBox(height: 2.h),
                                              CustomText(
                                                text: email,
                                                fontSize: 11.sp,
                                                color: Colors.grey[500],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 3.h),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: CustomText(
                                                      text: previewText,
                                                      fontSize: 13.sp,
                                                      color: unreadCount > 0
                                                          ? const Color(
                                                              0xFF0038A8,
                                                            )
                                                          : Colors.grey[600],
                                                      fontWeight:
                                                          unreadCount > 0
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (unreadCount > 0)
                                                    Container(
                                                      margin: EdgeInsets.only(
                                                        left: 6.w,
                                                      ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 7.w,
                                                            vertical: 2.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFFFB81C,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10.r,
                                                            ),
                                                      ),
                                                      child: CustomText(
                                                        text: unreadCount > 99
                                                            ? '99+'
                                                            : '$unreadCount',
                                                        fontSize: 11.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: const Color(
                                                          0xFF0038A8,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Arrow Icon
                                        Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey[400],
                                          size: 22.sp,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0, duration: 300.ms);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
