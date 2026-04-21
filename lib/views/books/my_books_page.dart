import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookshare/models/book.dart';
import 'package:bookshare/services/Book_service.dart';
import 'package:bookshare/views/books/book_detail_screen.dart';

class MyBooksPage extends StatelessWidget {
  const MyBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bookService = BookService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: StreamBuilder<List<Book>>(
          stream: bookService.myBorrowedBooks(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final books = snapshot.data ?? [];

            if (books.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.book_outlined, size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      "You haven't borrowed any books yet",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse the Books tab to find something to read',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _BorrowedBookCard(
                book: books[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookDetailScreen(book: books[i]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BorrowedBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BorrowedBookCard({required this.book, required this.onTap});

  bool get _isOverdue => book.dueDate != null && book.dueDate!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isOverdue ? const Color(0xFFFF3B30).withOpacity(0.4) : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: book.coverUrl.isNotEmpty
                  ? Image.network(
                book.coverUrl,
                width: 80,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaceholderCover(),
              )
                  : _PlaceholderCover(),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 10),

                    // Due date
                    if (book.dueDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isOverdue
                              ? const Color(0xFFFF3B30).withOpacity(0.1)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isOverdue ? Icons.warning_amber_rounded : Icons.schedule,
                              size: 13,
                              color: _isOverdue
                                  ? const Color(0xFFFF3B30)
                                  : const Color(0xFFFF9500),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isOverdue
                                  ? 'Overdue! ${book.dueDate!.day}/${book.dueDate!.month}/${book.dueDate!.year}'
                                  : 'Due ${book.dueDate!.day}/${book.dueDate!.month}/${book.dueDate!.year}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isOverdue
                                    ? const Color(0xFFFF3B30)
                                    : const Color(0xFFFF9500),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 110,
      color: const Color(0xFFEAF2FF),
      child: const Icon(Icons.book, color: Color(0xFF007AFF), size: 32),
    );
  }
}