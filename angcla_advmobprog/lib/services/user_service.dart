import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

// LAB ACTIVITY 4 - Service Layer for Authentication and Session Persistence
// Handles logging in against the DummyJSON API and storing user credentials on device.
class UserService {
  Map<String, dynamic> data = {};

  // LAB ACTIVITY 4 - ENHANCEMENT 2
  // Sends an HTTP POST request to DummyJSON with username and password
  Future<Map<String, dynamic>> loginUser(String username, String password) async {
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
        final errorMessage = errorData['message'] ?? 'Invalid username or password.';
        debugPrint('UserService login error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('UserService network error: $e');
      rethrow;
    }
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 1 & 2
  // Saves user fields and access token into device SharedPreferences
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

    // Support generic 'token' key if present in API response
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token']?.toString() ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 3
  // Retrieves raw user map from local device storage
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
    };
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 3
  // Reads saved user data from storage and converts it into a typed User model object
  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 1
  // Checks if a non-empty token exists in SharedPreferences
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // LAB ACTIVITY 4 - Session Cleanup
  // Clears all SharedPreferences data on logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('UserService logout error: $e');
      throw Exception('Failed to log out: $e');
    }
  }
}
