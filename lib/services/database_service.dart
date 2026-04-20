import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookshare/models/user_role.dart';
import 'package:bookshare/models/user.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Function to save user data after Sign Up
  Future<void> saveUserData(
    String uid,
    String firstName,
    String lastName,
    String email, {
    UserRole role = UserRole.member,
  }) async {
    try {
      final user = User(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _db.collection('Users').doc(uid).set(user.toFirestore());
      print("User $uid created with role: ${role.value}");
    } catch (e) {
      print("Error saving user: $e");
      rethrow;
    }
  }

  // Function to fetch a user's details
  Future<DocumentSnapshot> getUser(String uid) {
    return _db.collection('Users').doc(uid).get();
  }

  // Function to get User object from Firestore
  Future<User?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('Users').doc(uid).get();
      if (doc.exists) {
        return User.fromFirestore(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }
}
