import 'package:cloud_firestore/cloud_firestore.dart';

// LAB ACTIVITY 6 - ENHANCEMENT 2
// LAB ACTIVITY 6 - ENHANCEMENT 4
// Data model representing a chat message stored in Cloud Firestore.
class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final bool isRead;

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  // Factory constructor to deserialize a Firestore document map into a Message object
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId']?.toString() ?? '',
      senderEmail: map['senderEmail']?.toString() ?? '',
      receiverId: map['receiverId']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? map['timestamp'] as Timestamp
          : Timestamp.now(),
      // Safely read isRead, treating missing older-message values as false
      isRead: map['isRead'] == true,
    );
  }

  // Converts this Message object into a map for saving into Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}

// Alias for compatibility with Lab Activity 6 reference snippet naming
typedef MessageModel = Message;
