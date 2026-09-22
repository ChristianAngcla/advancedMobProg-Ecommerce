// LAB ACTIVITY 4 - ENHANCEMENT 3
// Data Model representing the authenticated User.
// Converts raw JSON responses from DummyJSON into safe, strongly-typed Dart objects.

// LAB ACTIVITY 5 - ENHANCEMENT 2
// Identifies whether the active account came from DummyJSON or Firebase.
enum LoginType { dummyJson, firebase }

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
  final LoginType loginType;
  final String firebaseUid;
  final int? age;
  final String contactNo;

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
    this.loginType = LoginType.dummyJson,
    this.firebaseUid = '',
    this.age,
    this.contactNo = '',
  });

  // Helper getter to display full name conveniently in the UI
  String get fullName => '$firstName $lastName'.trim();

  bool get isFirebaseUser => loginType == LoginType.firebase;

  String get loginSourceLabel =>
      isFirebaseUser ? 'Firebase account' : 'DummyJSON demo account';

  // Deserialization: Converts raw JSON map into a User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      // Supports both 'accessToken' (DummyJSON v2) and 'token' (DummyJSON legacy)
      accessToken:
          json['accessToken']?.toString() ?? json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      loginType: json['loginType']?.toString() == 'firebase'
          ? LoginType.firebase
          : LoginType.dummyJson,
      firebaseUid:
          json['firebaseUid']?.toString() ?? json['uid']?.toString() ?? '',
      age: json['age'] is int
          ? json['age'] as int
          : int.tryParse(json['age']?.toString() ?? ''),
      contactNo:
          json['contactNo']?.toString() ?? json['phone']?.toString() ?? '',
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
      'loginType': loginType.name,
      'firebaseUid': firebaseUid,
      'age': age,
      'contactNo': contactNo,
    };
  }
}
