/// Defines the user roles in the BookShare application
enum UserRole {
  admin,
  member,
  visitor,
}

extension UserRoleExtension on UserRole {
  /// Get the string representation of the role
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.member:
        return 'Member';
      case UserRole.visitor:
        return 'Visitor';
    }
  }

  /// Parse a string to UserRole
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'member':
        return UserRole.member;
      case 'visitor':
        return UserRole.visitor;
      default:
        return UserRole.member; // Default role
    }
  }

  /// Get role permissions
  List<String> get permissions {
    switch (this) {
      case UserRole.admin:
        return [
          'view_books',
          'add_books',
          'edit_books',
          'delete_books',
          'manage_users',
          'manage_events',
          'view_analytics',
          'manage_admins',
        ];
      case UserRole.member:
        return [
          'view_books',
          'add_books',
          'edit_own_books',
          'delete_own_books',
          'create_events',
          'manage_own_events',
          'favorite_books',
        ];
      case UserRole.visitor:
        return [
          'view_books',
          'view_events',
          'favorite_books',
        ];
    }
  }

  /// Check if role has a specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}

