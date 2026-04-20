import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookshare/models/user_role.dart';
import 'package:bookshare/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class RoleManagementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Assign a role to a user (Admin only)
  Future<void> assignRoleToUser(String uid, UserRole role) async {
    try {
      await _db.collection('Users').doc(uid).update({
        'role': role.value,
      });
      print('Role ${role.value} assigned to user $uid');
    } catch (e) {
      print("Error assigning role: $e");
      rethrow;
    }
  }

  /// Get user's role
  Future<UserRole> getUserRole(String uid) async {
    try {
      final doc = await _db.collection('Users').doc(uid).get();
      if (doc.exists) {
        final roleString = doc.data()?['role'] ?? 'Member';
        return UserRoleExtension.fromString(roleString);
      }
      return UserRole.visitor; // Default to visitor if user not found
    } catch (e) {
      print("Error getting user role: $e");
      return UserRole.visitor;
    }
  }

  /// Get user by UID
  Future<User?> getUserById(String uid) async {
    try {
      final doc = await _db.collection('Users').doc(uid).get();
      if (doc.exists) {
        return User.fromFirestore(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      print("Error getting user: $e");
      return null;
    }
  }

  /// Check if user has a specific permission
  Future<bool> userHasPermission(String uid, String permission) async {
    try {
      final role = await getUserRole(uid);
      return role.hasPermission(permission);
    } catch (e) {
      print("Error checking permission: $e");
      return false;
    }
  }

  /// Get all users with a specific role (Admin only)
  Future<List<User>> getUsersByRole(UserRole role) async {
    try {
      final query = await _db
          .collection('Users')
          .where('role', isEqualTo: role.value)
          .get();

      return query.docs
          .map((doc) => User.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Error fetching users by role: $e");
      return [];
    }
  }

  /// Update user's last sign-in time
  Future<void> updateLastSignIn(String uid) async {
    try {
      await _db.collection('Users').doc(uid).update({
        'lastSignIn': DateTime.now(),
      });
    } catch (e) {
      print("Error updating last sign-in: $e");
    }
  }

  /// Deactivate a user account
  Future<void> deactivateUser(String uid) async {
    try {
      await _db.collection('Users').doc(uid).update({
        'isActive': false,
      });
    } catch (e) {
      print("Error deactivating user: $e");
      rethrow;
    }
  }

  /// Activate a user account
  Future<void> activateUser(String uid) async {
    try {
      await _db.collection('Users').doc(uid).update({
        'isActive': true,
      });
    } catch (e) {
      print("Error activating user: $e");
      rethrow;
    }
  }

  /// Get all admins
  Future<List<User>> getAllAdmins() async {
    return getUsersByRole(UserRole.admin);
  }

  /// Get all members
  Future<List<User>> getAllMembers() async {
    return getUsersByRole(UserRole.member);
  }

  /// Get all visitors
  Future<List<User>> getAllVisitors() async {
    return getUsersByRole(UserRole.visitor);
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final role = await getUserRole(currentUser.uid);
      return role == UserRole.admin;
    } catch (e) {
      print("Error checking if user is admin: $e");
      return false;
    }
  }

  /// Promote user to admin (Super admin only)
  Future<void> promoteToAdmin(String uid) async {
    return assignRoleToUser(uid, UserRole.admin);
  }

  /// Demote admin to member
  Future<void> demoteAdminToMember(String uid) async {
    return assignRoleToUser(uid, UserRole.member);
  }

  /// Convert member to visitor
  Future<void> convertToVisitor(String uid) async {
    return assignRoleToUser(uid, UserRole.visitor);
  }
}

