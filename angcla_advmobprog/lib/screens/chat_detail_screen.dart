import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/message.dart';
import '../services/chat_service.dart';
import '../widgets/custom_text.dart';

// LAB ACTIVITY 6 - ENHANCEMENT 3
// LAB ACTIVITY 6 - ENHANCEMENT 4
// Screen providing direct real-time 1-on-1 messaging between two Firebase users.
class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> receiverUser;

  const ChatDetailScreen({super.key, required this.receiverUser});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // LAB ACTIVITY 6 - ENHANCEMENT 4: Mark incoming messages as read when conversation opens
    final receiverId = widget.receiverUser['uid']?.toString() ?? '';
    if (receiverId.isNotEmpty) {
      _chatService.markMessagesAsRead(receiverId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Helper to extract a display name from receiver user data
  String _getDisplayName() {
    final firstName = widget.receiverUser['firstName']?.toString().trim() ?? '';
    final lastName = widget.receiverUser['lastName']?.toString().trim() ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    final username = widget.receiverUser['username']?.toString().trim() ?? '';
    if (username.isNotEmpty) {
      return username;
    }
    final email = widget.receiverUser['email']?.toString().trim() ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'NU User';
  }

  // Helper to extract avatar initial
  String _getInitial() {
    final name = _getDisplayName();
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'U';
  }

  // Formats Firestore Timestamp into a readable 12-hour string (e.g. 2:30 PM)
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final DateTime dt = timestamp.toDate();
    final int hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final String minute = dt.minute.toString().padLeft(2, '0');
    final String period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Sends the message via ChatService
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final receiverId = widget.receiverUser['uid']?.toString() ?? '';
    if (receiverId.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(receiverId, text);
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: CustomText(
            text:
                'Failed to send message: ${e.toString().replaceAll('Exception: ', '')}',
            fontSize: 13.sp,
            color: Colors.white,
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final receiverId = widget.receiverUser['uid']?.toString() ?? '';
    final displayName = _getDisplayName();
    final initial = _getInitial();
    final email = widget.receiverUser['email']?.toString() ?? '';

    // Guard against missing authenticated user or receiver
    if (currentUser == null || receiverId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const CustomText(text: 'Chat', fontWeight: FontWeight.bold),
        ),
        body: const Center(
          child: CustomText(text: 'Invalid conversation participants.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0038A8)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Selected user's initial avatar with NU Blue Ring and Gold Accent
            Stack(
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0038A8),
                      width: 1.5,
                    ),
                    color: const Color(0xFF0038A8).withAlpha(25),
                  ),
                  child: Center(
                    child: CustomText(
                      text: initial,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0038A8),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10.r,
                    height: 10.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB81C),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).cardColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 10.w),

            // Selected user's name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: displayName,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  CustomText(
                    text: email,
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Real-time messages stream
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _chatService.getMessages(
                  currentUser.uid,
                  receiverId,
                  descending: true,
                ),
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
                              size: 44.sp,
                              color: Colors.redAccent,
                            ),
                            SizedBox(height: 12.h),
                            CustomText(
                              text: 'Unable to load messages',
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

                  final docs = snapshot.data?.docs ?? [];

                  // LAB ACTIVITY 6 - ENHANCEMENT 4
                  // Mark newly arrived incoming messages as read while conversation is open
                  final bool hasUnreadIncoming = docs.any((doc) {
                    final data = doc.data();
                    return data['receiverId'] == currentUser.uid &&
                        data['isRead'] != true;
                  });
                  if (hasUnreadIncoming) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _chatService.markMessagesAsRead(receiverId);
                    });
                  }

                  // Empty Conversation State
                  if (docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(18.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0038A8).withAlpha(15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 44.sp,
                                color: const Color(0xFF0038A8),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            CustomText(
                              text: 'No messages yet',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(height: 6.h),
                            CustomText(
                              text:
                                  'Say hello to $displayName to start the conversation!',
                              fontSize: 13.sp,
                              color: Colors.grey[600],
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Reversed message list: newest messages anchored at the bottom
                  return ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final message = Message.fromMap(docs[index].data());
                      final bool isMe = message.senderId == currentUser.uid;

                      return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                // Message Bubble
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 10.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(
                                            0xFF0038A8,
                                          ) // NU Deep Blue
                                        : const Color(
                                            0xFFF7F5EE,
                                          ), // Light Gray with Gold Tint
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16.r),
                                      topRight: Radius.circular(16.r),
                                      bottomLeft: isMe
                                          ? Radius.circular(16.r)
                                          : Radius.circular(4.r),
                                      bottomRight: isMe
                                          ? Radius.circular(4.r)
                                          : Radius.circular(16.r),
                                    ),
                                    border: isMe
                                        ? null
                                        : Border.all(
                                            color: const Color(
                                              0xFFFFB81C,
                                            ).withAlpha(60),
                                            width: 1,
                                          ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(12),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CustomText(
                                    text: message.message,
                                    fontSize: 14.sp,
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 3.h),

                                // Timestamp and honest Firestore checkmarks
                                // LAB ACTIVITY 6 - ENHANCEMENT 4:
                                // One checkmark = message saved in Firestore
                                // Double checkmarks = message isRead is true
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomText(
                                      text: _formatTimestamp(message.timestamp),
                                      fontSize: 10.sp,
                                      color: Colors.grey[600],
                                    ),
                                    if (isMe) ...[
                                      SizedBox(width: 4.w),
                                      Icon(
                                        message.isRead
                                            ? Icons.done_all
                                            : Icons.check,
                                        size: 15.sp,
                                        color: message.isRead
                                            ? const Color(0xFFFFB81C)
                                            : const Color(0xFF0038A8),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 250.ms)
                          .slideY(begin: 0.1, end: 0, duration: 250.ms);
                    },
                  );
                },
              ),
            ),

            // Message Input Area and Gold Send Button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Input TextField
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.sp,
                            color: Colors.grey[500],
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.r),
                            borderSide: BorderSide(
                              color: Colors.grey.withAlpha(50),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.r),
                            borderSide: BorderSide(
                              color: Colors.grey.withAlpha(50),
                            ),
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
                    SizedBox(width: 8.w),

                    // Gold Send Button with Sending State
                    Material(
                      color: _isSending
                          ? Colors.grey[300]
                          : const Color(0xFFFFB81C),
                      borderRadius: BorderRadius.circular(24.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24.r),
                        onTap: _isSending ? null : _sendMessage,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _isSending ? 12.w : 14.w,
                            vertical: 10.h,
                          ),
                          child: _isSending
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12.r,
                                      height: 12.r,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF0038A8),
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    CustomText(
                                      text: 'Sending…',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0038A8),
                                    ),
                                  ],
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  color: const Color(0xFF0038A8),
                                  size: 20.sp,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
