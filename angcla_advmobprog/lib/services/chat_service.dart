import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

// LAB ACTIVITY 6 - ENHANCEMENT 2
// LAB ACTIVITY 6 - ENHANCEMENT 4
// Service class handling real-time chat operations using Cloud Firestore and Firebase Auth.
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Stream of users from the 'users' collection in Firestore
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure uid is present in the map even if missing from document body
        if (!data.containsKey('uid') ||
            data['uid'] == null ||
            data['uid'].toString().isEmpty) {
          data['uid'] = doc.id;
        }
        return data;
      }).toList();
    });
  }

  // Private helper to generate a deterministic chat room ID between two users.
  // Sorting the IDs ensures both sender and receiver access the exact same chat room.
  String _getChatRoomId(String user1, String user2) {
    final List<String> ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }

  // Sends a chat message to a specific receiver inside chat_rooms/<chatRoomId>/messages
  Future<void> sendMessage(String receiverId, String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return;
    }

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('No user currently signed in.');
    }

    final Timestamp timestamp = Timestamp.now();

    // LAB ACTIVITY 6 - ENHANCEMENT 4: New messages default to isRead: false
    final Message newMessage = Message(
      senderId: currentUser.uid,
      senderEmail: currentUser.email ?? '',
      receiverId: receiverId,
      message: trimmedMessage,
      timestamp: timestamp,
      isRead: false,
    );

    final String chatRoomId = _getChatRoomId(currentUser.uid, receiverId);

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  // Returns a real-time stream of messages between two users ordered by timestamp
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(
    String userId,
    String otherUserId, {
    bool descending = false,
  }) {
    final String chatRoomId = _getChatRoomId(userId, otherUserId);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: descending)
        .snapshots();
  }

  // Alias method for compatibility with singular method naming (getMessage)
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessage(
    String userId,
    String otherUserId,
  ) {
    return getMessages(userId, otherUserId);
  }

  // LAB ACTIVITY 6 - ENHANCEMENT 4
  // Marks unread incoming messages as read when the receiver opens or views the conversation.
  // Updates only documents where receiverId matches the current user and isRead is not true.
  Future<void> markMessagesAsRead(String otherUserId) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return;

    final String chatRoomId = _getChatRoomId(currentUser.uid, otherUserId);

    // Query messages addressed to the current user in this direct chat room
    final querySnapshot = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .get();

    final batch = _firestore.batch();
    bool hasUnread = false;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['isRead'] != true) {
        batch.update(doc.reference, {'isRead': true});
        hasUnread = true;
      }
    }

    if (hasUnread) {
      await batch.commit();
    }
  }
}
