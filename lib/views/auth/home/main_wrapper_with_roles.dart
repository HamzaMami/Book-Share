import 'package:flutter/material.dart';
import 'package:bookshare/views/auth/home/home_page.dart';
import 'package:bookshare/views/admin/role_management_screen.dart';
import 'package:bookshare/services/role_management_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainWrapperWithRoles extends StatefulWidget {
  const MainWrapperWithRoles({super.key});

  @override
  State<MainWrapperWithRoles> createState() => _MainWrapperWithRolesState();
}

class _MainWrapperWithRolesState extends State<MainWrapperWithRoles> {
  int _selectedIndex = 0;
  final RoleManagementService _roleService = RoleManagementService();

  late final List<Widget> _pages = [
    const HomePage(),
    const Center(child: Text("My Books Content")),
    const Center(child: Text("Favorites Content")),
    const Center(child: Text("Events Content")),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  String _getTitle(int index) {
    switch (index) {
      case 0: return 'Home';
      case 1: return 'My Books';
      case 2: return 'Favorites';
      case 3: return 'Events';
      default: return 'BookShare';
    }
  }

  void _handleAdminMenuPress() async {
    bool isAdmin = await _roleService.isCurrentUserAdmin();
    if (!mounted) return;

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have admin access.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Users & Roles'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analytics - Coming Soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings - Coming Soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Close'),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          _getTitle(_selectedIndex),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          FutureBuilder<bool>(
            future: _roleService.isCurrentUserAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: Colors.red),
                  tooltip: 'Admin Panel',
                  onPressed: _handleAdminMenuPress,
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (sheetContext) => Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              child: Text(
                                (currentUser?.displayName ?? 'U')[0].toUpperCase(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentUser?.displayName ?? 'User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currentUser?.email ?? '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      FutureBuilder<String>(
                        future: _roleService
                            .getUserRole(currentUser?.uid ?? '')
                            .then((role) => role.name[0].toUpperCase() + role.name.substring(1)),
                        builder: (context, snapshot) {
                          return ListTile(
                            leading: const Icon(Icons.badge),
                            title: const Text('Your Role'),
                            subtitle: Text(snapshot.data ?? 'Loading...'),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () => Navigator.pop(sheetContext),
                      ),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Help & Support'),
                        onTap: () => Navigator.pop(sheetContext),
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Logout', style: TextStyle(color: Colors.red)),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/signin',
                                  (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'My Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
        ],
      ),
    );
  }
}