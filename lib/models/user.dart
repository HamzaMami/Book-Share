import 'package:bookshare/models/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;
  final List<String> favoriteGenres;
  final DateTime createdAt;
  final DateTime? lastSignIn;
  final bool isActive;

  User({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.favoriteGenres = const [],
    required this.createdAt,
    this.lastSignIn,
    this.isActive = true,
  });

  /// Convert User object to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role.value,
      'favoriteGenres': favoriteGenres,
      'createdAt': createdAt,
      'lastSignIn': lastSignIn,
      'isActive': isActive,
    };
  }

  /// Create User object from Firestore document
  factory User.fromFirestore(Map<String, dynamic> data, String uid) {
    return User(
      uid: uid,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      role: UserRoleExtension.fromString(data['role'] ?? 'Member'),
      favoriteGenres: List<String>.from(data['favoriteGenres'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSignIn: (data['lastSignIn'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Get user's full name
  String get fullName => '$firstName $lastName';

  @override
  String toString() {
    return 'User(uid: $uid, name: $fullName, role: ${role.value}, email: $email)';
  }
}

