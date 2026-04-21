import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookshare/models/book.dart';
import 'package:bookshare/services/Book_service.dart';
import 'package:bookshare/services/role_management_service.dart';


class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _bookService = BookService();
  final _roleService = RoleManagementService();
  bool _isLoading = false;
  late Book _book;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
  }

  Color _statusColor(BookStatus s) {
    switch (s) {
      case BookStatus.available: return const Color(0xFF34C759);
      case BookStatus.loaned:    return const Color(0xFFFF9500);
      case BookStatus.reserved:  return const Color(0xFF007AFF);
    }
  }

  Future<void> _handleBorrow() async {
    setState(() => _isLoading = true);
    try {
      await _bookService.borrowBook(_book.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book borrowed! Due in 14 days.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReserve() async {
    setState(() => _isLoading = true);
    try {
      await _bookService.reserveBook(_book.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book reserved! You will be notified when available.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReturn() async {
    setState(() => _isLoading = true);
    try {
      await _bookService.returnBook(_book.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book returned successfully.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${_book.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _bookService.deleteBook(_book.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentBorrower = _book.currentBorrowerId == currentUid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // App bar with cover
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              // Admin delete button
              FutureBuilder<bool>(
                future: _roleService.isCurrentUserAdmin(),
                builder: (ctx, snap) {
                  if (snap.data != true) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _handleDelete,
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFEAF2FF),
                child: _book.coverUrl.isNotEmpty
                    ? Image.network(_book.coverUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.book, size: 80, color: Color(0xFF007AFF)),
                        ))
                    : const Center(
                        child: Icon(Icons.book, size: 80, color: Color(0xFF007AFF)),
                      ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(_book.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _book.status.value,
                      style: TextStyle(
                        color: _statusColor(_book.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    _book.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Author
                  Text(
                    _book.author,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),

                  // Genre chip
                  if (_book.genre.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _book.genre,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),

                  if (_book.isbn.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('ISBN: ${_book.isbn}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],

                  if (_book.dueDate != null && isCurrentBorrower) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: Color(0xFFFF9500), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Due: ${_book.dueDate!.day}/${_book.dueDate!.month}/${_book.dueDate!.year}',
                            style: const TextStyle(
                              color: Color(0xFFFF9500),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_book.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'About this book',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _book.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Action buttons
                  if (isCurrentBorrower)
                    _ActionButton(
                      label: 'Return Book',
                      icon: Icons.assignment_return_outlined,
                      color: const Color(0xFFFF9500),
                      onTap: _isLoading ? null : _handleReturn,
                      loading: _isLoading,
                    )
                  else if (_book.status == BookStatus.available)
                    _ActionButton(
                      label: 'Borrow Book',
                      icon: Icons.book_outlined,
                      color: const Color(0xFF007AFF),
                      onTap: _isLoading ? null : _handleBorrow,
                      loading: _isLoading,
                    )
                  else if (_book.status == BookStatus.loaned)
                    _ActionButton(
                      label: 'Reserve Book',
                      icon: Icons.bookmark_outline,
                      color: const Color(0xFF34C759),
                      onTap: _isLoading ? null : _handleReserve,
                      loading: _isLoading,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('Already reserved',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: loading
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }
}
