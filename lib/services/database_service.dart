import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Function to save user data after Sign Up
  Future<void> saveUserData(
    String uid,
    String firstName,
    String lastName,
    String email,
  ) async {
    try {
      await _db.collection('Users').doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': 'Member', // Default role
        'favoriteGenres': [],
        'passwordHash': '', // Usually handled by Firebase Auth
      });
    } catch (e) {
      print("Error saving user: $e");
    }
  }

  // Function to fetch a user's details
  Future<DocumentSnapshot> getUser(String uid) {
    return _db.collection('Users').doc(uid).get();
  }
}
