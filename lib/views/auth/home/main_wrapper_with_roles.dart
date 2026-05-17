import 'package:flutter/material.dart';
import 'package:bookshare/views/auth/home/home_page.dart';
import 'package:bookshare/views/books/books_page.dart';
import 'package:bookshare/views/books/my_books_page.dart';
import 'package:bookshare/views/books/add_book_screen.dart';
import 'package:bookshare/views/admin/role_management_screen.dart';
import 'package:bookshare/views/admin/loan_requests_screen.dart';
import 'package:bookshare/views/admin/loans_view_screen.dart';
import 'package:bookshare/services/role_management_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainWrapperWithRoles extends StatefulWidget {
  const MainWrapperWithRoles({super.key});

  @override
  State<MainWrapperWithRoles> createState() => _MainWrapperWithRolesState();
}

class _MainWrapperWithRolesState extends State<MainWrapperWithRoles> {
  int _selectedIndex = 0;
  String _booksSearchQuery = '';
  final RoleManagementService _roleService = RoleManagementService();

  List<Widget> get _pages => [
        HomePage(
          onSearchBooks: (query) {
            setState(() {
              _booksSearchQuery = query;
              _selectedIndex = 1;
            });
          },
          onOpenBooks: () => _onItemTapped(1),
          onOpenMyLibrary: () => _onItemTapped(2),
          onAddBook: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBookScreen()),
            );
          },
        ),
        BooksPage(
          key: ValueKey<String>(_booksSearchQuery),
          initialSearchQuery: _booksSearchQuery,
        ),
        const MyBooksPage(),
        const Center(child: Text("Events Content")),
      ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  String _getTitle(int index) {
    switch (index) {
      case 0: return 'Home';
      case 1: return 'Books';
      case 2: return 'My Books';
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
              leading: const Icon(Icons.swap_horiz, color: Color(0xFF007AFF)),
              title: const Text('Borrow Requests'),
              subtitle: const Text('Pending requests from members'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoanRequestsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_books, color: Color(0xFF34C759)),
              title: const Text('Currently Loaned'),
              subtitle: const Text('Books borrowed by members'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoansViewScreen()),
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
                          final navigator = Navigator.of(context);
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            navigator.pushNamedAndRemoveUntil(
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
            label: 'Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'My Books',
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
