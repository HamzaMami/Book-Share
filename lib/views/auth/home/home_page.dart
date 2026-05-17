import 'package:flutter/material.dart';
import 'package:bookshare/models/book.dart';
import 'package:bookshare/services/book_service.dart';
import 'package:bookshare/services/role_management_service.dart';
import 'package:bookshare/views/books/book_detail_screen.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<String> onSearchBooks;
  final VoidCallback onOpenBooks;
  final VoidCallback onOpenMyLibrary;
  final VoidCallback? onAddBook;

  const HomePage({
    super.key,
    required this.onSearchBooks,
    required this.onOpenBooks,
    required this.onOpenMyLibrary,
    this.onAddBook,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BookService _bookService = BookService();
  final RoleManagementService _roleService = RoleManagementService();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String q) {
    final query = q.trim();
    if (query.isEmpty) return;
    widget.onSearchBooks(query);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Welcome to BookShare',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find your next favorite book and keep your reading organized.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            onSubmitted: _onSearchSubmitted,
            decoration: InputDecoration(
              hintText: 'Search books, authors, genres...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF007AFF)),
              suffixIcon: IconButton(
                onPressed: () {
                  final query = _searchController.text.trim();
                  if (query.isNotEmpty) {
                    _onSearchSubmitted(query);
                  } else {
                    widget.onOpenBooks();
                  }
                },
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          FutureBuilder<bool>(
            future: _roleService.isCurrentUserAdmin(),
            builder: (context, snapshot) {
              final isAdmin = snapshot.data == true;
              return Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (isAdmin && widget.onAddBook != null) {
                          widget.onAddBook!();
                        } else {
                          widget.onOpenBooks();
                        }
                      },
                      child: _QuickActionCard(
                        icon: isAdmin ? Icons.bookmark_add_outlined : Icons.search,
                        title: isAdmin ? 'Add Book' : 'Browse Books',
                        subtitle: isAdmin ? 'Save a new title' : 'Explore all titles',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onOpenMyLibrary,
                      child: _QuickActionCard(
                        icon: Icons.menu_book_outlined,
                        title: 'My Library',
                        subtitle: 'View your books',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Featured Books',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Featured books (show up to 5 recent books)
          StreamBuilder<List<Book>>(
            stream: _bookService.booksStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final books = (snap.data ?? []).take(5).toList();
              if (books.isEmpty) return Center(child: Text('No featured books', style: TextStyle(color: Colors.grey.shade500)));
              return Column(
                children: books
                    .map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _BookTile(
                          title: b.title,
                          author: b.author,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BookDetailScreen(book: b)),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF007AFF)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final String title;
  final String author;
  final VoidCallback onTap;

  const _BookTile({required this.title, required this.author, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF2FF),
          child: Icon(Icons.book_outlined, color: Color(0xFF007AFF)),
        ),
        title: Text(title),
        subtitle: Text(author),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

