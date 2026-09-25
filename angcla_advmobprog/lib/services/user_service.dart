import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

// LAB ACTIVITY 4 - Service Layer for Authentication and Session Persistence
// Handles logging in against the DummyJSON API and storing user credentials on device.
// LAB ACTIVITY 5 - Extended to support Firebase Authentication and Account Management.
// LAB ACTIVITY 6 - Extended to maintain a Cloud Firestore user directory for live chat.
class UserService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  // LAB ACTIVITY 6 - ENHANCEMENT 1
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> data = {};

  // LAB ACTIVITY 4 - ENHANCEMENT 2
  // Sends an HTTP POST request to DummyJSON with username and password
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$host/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password.trim(),
          'expiresInMins': 60,
        }),
      );

      // ERROR HANDLING ENHANCEMENT
      // Checks if credentials are valid and server responded with HTTP 200 OK
      if (response.statusCode == 200) {
        data = jsonDecode(response.body);
        // Automatically save session to device storage upon successful login
        await saveUserData(data);
        return data;
      } else {
        // Parse server error response (e.g. "Invalid credentials")
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Invalid username or password.';
        debugPrint('UserService login error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('UserService network error: $e');
      rethrow;
    }
  }

  // LAB ACTIVITY 5 - FIREBASE PROFILE PERSISTENCE
  // Keeps non-sensitive Firebase profile details on this device after logout.
  static String _profileCacheKey(String uid) => 'firebase_profile_$uid';

  Future<void> _saveFirebaseProfileCache({
    required String firebaseUid,
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required int? age,
    required String contactNo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profileData = {
      'firebaseUid': firebaseUid,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'contactNo': contactNo,
      'username': username,
      'email': email,
      'loginType': 'firebase',
    };
    await prefs.setString(
      _profileCacheKey(firebaseUid),
      jsonEncode(profileData),
    );
  }

  Future<Map<String, dynamic>?> _getFirebaseProfileCache(
    String firebaseUid,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_profileCacheKey(firebaseUid));
    if (rawJson == null || rawJson.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return Map<String, dynamic>.from(decoded as Map);
    } catch (e) {
      debugPrint('Error reading Firebase profile cache: $e');
      return null;
    }
  }

  Future<void> _removeFirebaseProfileCache(String firebaseUid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileCacheKey(firebaseUid));
  }

  // LAB ACTIVITY 6 - ENHANCEMENT 1
  // Saves the active Firebase user's chat-profile document to Firestore (users/<uid>)
  Future<void> _saveUserToFirestore({
    required String uid,
    required String username,
    required String firstName,
    required String lastName,
    required int? age,
    required String contactNo,
    required String email,
  }) async {
    final userMap = {
      'uid': uid,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'contactNo': contactNo,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(uid)
        .set(userMap, SetOptions(merge: true));
  }

  // LAB ACTIVITY 5 - ENHANCEMENT 1
  // Signs in an existing Firebase account using email and password.
  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        // LAB ACTIVITY 5 - FIREBASE PROFILE PERSISTENCE
        // Read cached non-sensitive profile details saved on this device
        final cached = await _getFirebaseProfileCache(firebaseUser.uid);

        final resolvedUsername =
            (firebaseUser.displayName != null &&
                firebaseUser.displayName!.isNotEmpty)
            ? firebaseUser.displayName!
            : (cached?['username']?.toString().isNotEmpty == true
                  ? cached!['username'].toString()
                  : (firebaseUser.email?.contains('@') == true
                        ? firebaseUser.email!.split('@').first
                        : (firebaseUser.email ?? email.trim())));

        final resolvedFirstName = cached?['firstName']?.toString() ?? '';
        final resolvedLastName = cached?['lastName']?.toString() ?? '';
        final resolvedAge = cached?['age'] is int
            ? cached!['age'] as int
            : (cached?['age'] != null
                  ? int.tryParse(cached!['age'].toString())
                  : null);
        final resolvedContactNo = cached?['contactNo']?.toString() ?? '';

        await _saveFirebaseUserSession(
          firebaseUid: firebaseUser.uid,
          email: firebaseUser.email ?? email.trim(),
          username: resolvedUsername,
          firstName: resolvedFirstName,
          lastName: resolvedLastName,
          age: resolvedAge,
          contactNo: resolvedContactNo,
        );

        // LAB ACTIVITY 6 - ENHANCEMENT 1
        // Saves/updates the user's directory document in Firestore (users/<uid>)
        await _saveUserToFirestore(
          uid: firebaseUser.uid,
          username: resolvedUsername,
          firstName: resolvedFirstName,
          lastName: resolvedLastName,
          age: resolvedAge,
          contactNo: resolvedContactNo,
          email: firebaseUser.email ?? email.trim(),
        );
      }

      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase signIn error: ${e.code} - ${e.message}');
      throw Exception(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Unexpected signIn error: $e');
      rethrow;
    }
  }

  // LAB ACTIVITY 5 - ENHANCEMENT 1
  // Creates a new Firebase email/password account and saves its local profile details.
  Future<firebase_auth.UserCredential> createAccount({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(username.trim());

        // LAB ACTIVITY 5 - FIREBASE PROFILE PERSISTENCE
        // Cache non-sensitive registration details on this device
        await _saveFirebaseProfileCache(
          firebaseUid: firebaseUser.uid,
          email: email.trim(),
          username: username.trim(),
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          age: age,
          contactNo: contactNo.trim(),
        );

        await _saveFirebaseUserSession(
          firebaseUid: firebaseUser.uid,
          email: email.trim(),
          username: username.trim(),
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          age: age,
          contactNo: contactNo.trim(),
        );

        // LAB ACTIVITY 6 - ENHANCEMENT 1
        // Saves the new user's chat-profile document to Firestore (users/<uid>)
        await _saveUserToFirestore(
          uid: firebaseUser.uid,
          username: username.trim(),
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          age: age,
          contactNo: contactNo.trim(),
          email: email.trim(),
        );
      }

      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase createAccount error: ${e.code} - ${e.message}');
      throw Exception(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Unexpected createAccount error: $e');
      rethrow;
    }
  }

  // LAB ACTIVITY 5 - Account Management
  // Signs out from both Firebase and local device storage.
  Future<void> signOut() async {
    await logout();
  }

  // LAB ACTIVITY 5 - Account Management
  // Updates the display name on Firebase and persists the new username locally.
  Future<void> updateUsername({required String username}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No Firebase account is currently signed in.');
      }
      await user.updateDisplayName(username.trim());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username.trim());

      // LAB ACTIVITY 5 - FIREBASE PROFILE PERSISTENCE
      // Keep username in local profile cache synchronized
      final cached = await _getFirebaseProfileCache(user.uid);
      if (cached != null) {
        cached['username'] = username.trim();
        await prefs.setString(_profileCacheKey(user.uid), jsonEncode(cached));
      }

      // LAB ACTIVITY 6 - ENHANCEMENT 1
      // Keep username synchronized in the Firestore users directory
      await _firestore.collection('users').doc(user.uid).set({
        'username': username.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase updateUsername error: ${e.code} - ${e.message}');
      throw Exception(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Unexpected updateUsername error: $e');
      rethrow;
    }
  }

  // LAB ACTIVITY 5 - Account Management
  // Verifies credentials, deletes Firebase account, and clears local data.
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      final authCredential = firebase_auth.EmailAuthProvider.credential(
        email: email.trim(),
        password: password.trim(),
      );

      String targetUid = '';
      if (user != null) {
        targetUid = user.uid;
        await user.reauthenticateWithCredential(authCredential);
        await user.delete();
      } else {
        final result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
        targetUid = result.user?.uid ?? '';
        await result.user?.delete();
      }

      // LAB ACTIVITY 5 - FIREBASE PROFILE PERSISTENCE
      // Account is permanently deleted, so remove its profile cache
      if (targetUid.isNotEmpty) {
        await _removeFirebaseProfileCache(targetUid);
      }

      await logout();
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase deleteAccount error: ${e.code} - ${e.message}');
      throw Exception(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Unexpected deleteAccount error: $e');
      rethrow;
    }
  }

  // LAB ACTIVITY 5 - Account Management
  // Verifies current password before setting a new password.
  Future<void> resetPasswordFromCurrentPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      final authCredential = firebase_auth.EmailAuthProvider.credential(
        email: email.trim(),
        password: currentPassword.trim(),
      );

      if (user != null) {
        await user.reauthenticateWithCredential(authCredential);
        await user.updatePassword(newPassword.trim());
      } else {
        final result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: currentPassword.trim(),
        );
        await result.user?.updatePassword(newPassword.trim());
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase resetPassword error: ${e.code} - ${e.message}');
      throw Exception(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('Unexpected resetPassword error: $e');
      rethrow;
    }
  }

  // LAB ACTIVITY 5 - HELPER
  // Helper to persist Firebase user profile into SharedPreferences
  Future<void> _saveFirebaseUserSession({
    required String firebaseUid,
    required String email,
    String? username,
    String? firstName,
    String? lastName,
    int? age,
    String? contactNo,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final existingFirstName = prefs.getString('firstName') ?? '';
    final existingLastName = prefs.getString('lastName') ?? '';
    final existingAge = prefs.getInt('age');
    final existingContactNo = prefs.getString('contactNo') ?? '';
    final existingUsername = prefs.getString('username') ?? '';

    final resolvedUsername = (username != null && username.isNotEmpty)
        ? username
        : (existingUsername.isNotEmpty
              ? existingUsername
              : (email.contains('@') ? email.split('@').first : email));

    final resolvedFirstName = (firstName != null && firstName.isNotEmpty)
        ? firstName
        : existingFirstName;

    final resolvedLastName = (lastName != null && lastName.isNotEmpty)
        ? lastName
        : existingLastName;

    final resolvedAge = age ?? existingAge;

    final resolvedContactNo = (contactNo != null && contactNo.isNotEmpty)
        ? contactNo
        : existingContactNo;

    final userData = {
      'id': 0,
      'username': resolvedUsername,
      'email': email,
      'firstName': resolvedFirstName,
      'lastName': resolvedLastName,
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': '',
      'refreshToken': '',
      'loginType': 'firebase',
      'firebaseUid': firebaseUid,
      'age': resolvedAge,
      'contactNo': resolvedContactNo,
    };

    await prefs.remove('token');
    await saveUserData(userData);
  }

  // LAB ACTIVITY 5 - ERROR TRANSLATION
  // Converts Firebase Auth exceptions into clean, user-friendly messages.
  String _getFirebaseErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'This email already has an account.';
      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';
      case 'requires-recent-login':
        return 'Please sign in again before making this change.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'An unexpected authentication error occurred.';
    }
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 1 & 2
  // Saves user fields and access token into device SharedPreferences
  // LAB ACTIVITY 5: Also saves loginType, firebaseUid, age, and contactNo
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    // LAB ACTIVITY 5 - Save loginType, firebaseUid, age, and contactNo
    await prefs.setString('loginType', user.loginType.name);
    await prefs.setString('firebaseUid', user.firebaseUid);
    if (user.age != null) {
      await prefs.setInt('age', user.age!);
    } else {
      await prefs.remove('age');
    }
    await prefs.setString('contactNo', user.contactNo);

    // Support generic 'token' key if present in API response
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token']?.toString() ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 3
  // Retrieves raw user map from local device storage
  // LAB ACTIVITY 5: Also retrieves loginType, firebaseUid, age, and contactNo
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'loginType': prefs.getString('loginType') ?? 'dummyJson',
      'firebaseUid': prefs.getString('firebaseUid') ?? '',
      'age': prefs.getInt('age'),
      'contactNo': prefs.getString('contactNo') ?? '',
    };
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 3
  // Reads saved user data from storage and converts it into a typed User model object
  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 1
  // LAB ACTIVITY 5: Checks if Firebase user is signed in OR DummyJSON token exists
  Future<bool> isLoggedIn() async {
    if (_firebaseAuth.currentUser != null) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // LAB ACTIVITY 4 - Session Cleanup
  // LAB ACTIVITY 5: Signs out Firebase if active, then clears active session
  Future<void> logout() async {
    try {
      if (_firebaseAuth.currentUser != null) {
        await _firebaseAuth.signOut();
      }
      final prefs = await SharedPreferences.getInstance();
      // LAB ACTIVITY 5 - FIREBASE PROFILE PERSISTENCE
      // Clear active session keys and tokens, but preserve firebase_profile_* caches
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (!key.startsWith('firebase_profile_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('UserService logout error: $e');
      throw Exception('Failed to log out: $e');
    }
  }
}
