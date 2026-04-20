import 'package:flutter/material.dart';
import 'package:bookshare/models/user.dart';
import 'package:bookshare/models/user_role.dart';
import 'package:bookshare/services/role_management_service.dart';
import 'package:bookshare/components/default_button.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final RoleManagementService _roleService = RoleManagementService();
  List<User> _allUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoading = true);
    try {
      final admins = await _roleService.getAllAdmins();
      final members = await _roleService.getAllMembers();
      final visitors = await _roleService.getAllVisitors();

      setState(() {
        _allUsers = [...admins, ...members, ...visitors];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeUserRole(User user, UserRole newRole) async {
    try {
      await _roleService.assignRoleToUser(user.uid, newRole);
      await _loadAllUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.fullName} role changed to ${newRole.value}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing role: $e')),
        );
      }
    }
  }

  Future<void> _deactivateUser(User user) async {
    try {
      await _roleService.deactivateUser(user.uid);
      await _loadAllUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.fullName} has been deactivated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deactivating user: $e')),
        );
      }
    }
  }

  Future<void> _activateUser(User user) async {
    try {
      await _roleService.activateUser(user.uid);
      await _loadAllUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.fullName} has been activated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error activating user: $e')),
        );
      }
    }
  }

  void _showRoleChangeDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${user.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Admin'),
              onTap: () {
                _changeUserRole(user, UserRole.admin);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Member'),
              onTap: () {
                _changeUserRole(user, UserRole.member);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Visitor'),
              onTap: () {
                _changeUserRole(user, UserRole.visitor);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _allUsers.length,
              itemBuilder: (context, index) {
                final user = _allUsers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(user.fullName),
                    subtitle: Text('${user.email}\nRole: ${user.role.value}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Change Role'),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 500),
                            () => _showRoleChangeDialog(user),
                          ),
                        ),
                        PopupMenuItem(
                          child: Text(
                            user.isActive ? 'Deactivate' : 'Activate',
                            style: TextStyle(
                              color: user.isActive ? Colors.red : Colors.green,
                            ),
                          ),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 500),
                            () {
                              if (user.isActive) {
                                _deactivateUser(user);
                              } else {
                                _activateUser(user);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(user.role),
                      child: Text(
                        user.firstName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _loadAllUsers,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.member:
        return Colors.green;
      case UserRole.visitor:
        return Colors.orange;
    }
  }
}

