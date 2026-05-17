import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookshare/models/book.dart';
import 'package:bookshare/services/book_service.dart';
import 'package:bookshare/services/loan_request_service.dart';
import 'package:bookshare/services/role_management_service.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _bookService = BookService();
  final _loanService = LoanRequestService();
  final _roleService = RoleManagementService();
  bool _isLoading = false;
  bool _hasPendingRequest = false;
  bool _isReservedByUser = false;
  int? _reservationPosition;
  int _reservationCount = 0;
  late Book _book;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _checkPendingRequest();
    _loadReservations();
  }

  Future<void> _checkPendingRequest() async {
    final has = await _loanService.hasPendingRequest(_book.id);
    if (mounted) setState(() => _hasPendingRequest = has);
  }

  Future<void> _reloadBook() async {
    final updated = await _bookService.getBook(_book.id);
    if (updated != null && mounted) setState(() => _book = updated);
  }

  Future<void> _loadReservations() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final bookRef = FirebaseFirestore.instance.collection('Books').doc(_book.id);
      final snapshot = await bookRef.collection('reservations').orderBy('reservedAt').get();
      final docs = snapshot.docs;
      int pos = -1;
      for (int i = 0; i < docs.length; i++) {
        final uid = docs[i].data()['userId']?.toString();
        if (uid != null && uid == currentUid) {
          pos = i;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _reservationCount = docs.length;
        _reservationPosition = pos >= 0 ? pos : null;
        _isReservedByUser = _reservationPosition != null;
      });
    } catch (_) {
      // ignore errors for now
    }
  }

  Color _statusColor(BookStatus s) {
    switch (s) {
      case BookStatus.available: return const Color(0xFF34C759);
      case BookStatus.loaned:    return const Color(0xFFFF9500);
      case BookStatus.reserved:  return const Color(0xFF007AFF);
    }
  }

  Future<void> _handleRequestBorrow() async {
    setState(() => _isLoading = true);
    try {
      await _loanService.requestBorrow(_book);
      if (!mounted) return;
      setState(() => _hasPendingRequest = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Borrow request sent! Waiting for admin approval.'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
      await _loadReservations();
      await _reloadBook();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBorrowNow() async {
    setState(() => _isLoading = true);
    try {
      await _bookService.borrowBook(_book.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have borrowed the book.')),
      );
      await _reloadBook();
      await _loadReservations();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
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
              IconButton(
                icon: const Icon(Icons.list, color: Colors.black),
                onPressed: () => _showReservationQueue(),
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
                  Text(_book.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_book.author,
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),

                  if (_book.genre.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_book.genre,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
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
                                color: Color(0xFFFF9500), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_book.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('About this book',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_book.description,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
                  ],

                  const SizedBox(height: 32),

                  // ── Action button ──
                  if (isCurrentBorrower)
                    _ActionButton(
                      label: 'Return Book',
                      icon: Icons.assignment_return_outlined,
                      color: const Color(0xFFFF9500),
                      onTap: _isLoading ? null : _handleReturn,
                      loading: _isLoading,
                    )
                  else if (_hasPendingRequest)
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_top, size: 18, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Request pending approval',
                                style: TextStyle(
                                    color: Colors.grey, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    )
                  else if (_book.status == BookStatus.available)
                      _ActionButton(
                        label: 'Request to Borrow',
                        icon: Icons.book_outlined,
                        color: const Color(0xFF007AFF),
                        onTap: _isLoading ? null : _handleRequestBorrow,
                        loading: _isLoading,
                      )
                      else if (_book.status == BookStatus.loaned)
                        // If the book is loaned but the current user already reserved it,
                        // show a non-active reserved indicator instead of the Reserve button.
                        _isReservedByUser
                            ? Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    _reservationPosition != null
                                        ? 'Reserved — you are #${_reservationPosition! + 1} of $_reservationCount'
                                        : 'Already reserved',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : _ActionButton(
                                label: 'Reserve Book',
                                icon: Icons.bookmark_outline,
                                color: const Color(0xFF34C759),
                                onTap: _isLoading ? null : _handleReserve,
                                loading: _isLoading,
                              )
                    else if (_book.status == BookStatus.reserved)
                      // Reserved: show position or allow borrow if first reserver
                      _book.status == BookStatus.reserved && _isReservedByUser && _reservationPosition == 0
                          ? _ActionButton(
                              label: 'Borrow Now',
                              icon: Icons.book,
                              color: const Color(0xFF007AFF),
                              onTap: _isLoading ? null : _handleBorrowNow,
                              loading: _isLoading,
                            )
                          : !_isReservedByUser
                              ? _ActionButton(
                                  label: 'Reserve Book',
                                  icon: Icons.bookmark_outline,
                                  color: const Color(0xFF34C759),
                                  onTap: _isLoading ? null : _handleReserve,
                                  loading: _isLoading,
                                )
                              : Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _reservationPosition != null
                                          ? 'Reserved — you are #${_reservationPosition! + 1} of $_reservationCount'
                                          : 'Already reserved',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                    else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Action unavailable', style: TextStyle(color: Colors.grey)),
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

  Future<void> _showReservationQueue() async {
    final bookRef = FirebaseFirestore.instance.collection('Books').doc(_book.id);
    final snap = await bookRef.collection('reservations').orderBy('reservedAt').get();
    final docs = snap.docs;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reservation Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (docs.isEmpty) const Text('No reservations'),
            for (int i = 0; i < docs.length; i++)
              ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(docs[i].data()['userId'] ?? 'Unknown'),
                trailing: FutureBuilder<bool>(
                  future: _roleService.isCurrentUserAdmin(),
                  builder: (ctx2, snap2) {
                    if (snap2.data != true) return const SizedBox.shrink();
                    return TextButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _bookService.assignBookToUser(_book.id, docs[i].data()['userId'].toString());
                        await _reloadBook();
                        await _loadReservations();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book assigned to user.')));
                      },
                      child: const Text('Assign'),
                    );
                  },
                ),
              ),
          ],
        ),
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
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }
}
