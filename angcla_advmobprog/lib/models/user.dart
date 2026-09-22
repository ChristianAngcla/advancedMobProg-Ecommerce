// LAB ACTIVITY 4 - ENHANCEMENT 3
// Data Model representing the authenticated User.
// Converts raw JSON responses from DummyJSON into safe, strongly-typed Dart objects.

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
  });

  // Helper getter to display full name conveniently in the UI
  String get fullName => '$firstName $lastName'.trim();

  // Deserialization: Converts raw JSON map into a User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      // Supports both 'accessToken' (DummyJSON v2) and 'token' (DummyJSON legacy)
      accessToken: json['accessToken']?.toString() ?? json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
    );
  }

  // Serialization: Converts a User object back into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'image': image,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'token': accessToken,
    };
  }
}
