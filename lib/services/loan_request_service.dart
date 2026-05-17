import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookshare/models/loan_request.dart';
import 'package:bookshare/models/book.dart';

class LoanRequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _requests => _db.collection('LoanRequests');
  CollectionReference get _books => _db.collection('Books');

  // ─── Member: submit a borrow request ─────────────────────────────────────
  Future<void> requestBorrow(Book book) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated');
    // Check book status to decide if a borrow request is allowed
    final bookSnap = await _books.doc(book.id).get();
    final bookData = bookSnap.data() as Map<String, dynamic>?;
    final status = (bookData != null && bookData['status'] != null)
        ? bookData['status'].toString().toLowerCase()
        : BookStatus.available.value.toLowerCase();

    if (status == BookStatus.loaned.value.toLowerCase()) {
      throw Exception('Book is currently loaned. Consider reserving it.');
    }

    if (status == BookStatus.reserved.value.toLowerCase()) {
      throw Exception('Book is reserved. Please reserve the book or wait for it to become available.');
    }

    // Check if user already has a pending request for this book
    final existing = await _requests
        .where('bookId', isEqualTo: book.id)
        .where('requesterId', isEqualTo: user.uid)
        .where('status', isEqualTo: LoanRequestStatus.pending.value)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You already have a pending request for this book.');
    }

    await _requests.add(LoanRequest(
      id: '',
      bookId: book.id,
      bookTitle: book.title,
      requesterId: user.uid,
      requesterName: user.displayName ?? user.email ?? 'Unknown',
      requestedAt: DateTime.now(),
    ).toFirestore());
  }

  // ─── Admin: stream all pending requests ──────────────────────────────────
  Stream<List<LoanRequest>> pendingRequestsStream() {
    return _requests
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LoanRequest.fromFirestore(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ─── Admin: approve request ───────────────────────────────────────────────
  Future<void> approveRequest(LoanRequest request) async {
    final requestRef = _requests.doc(request.id);
    final bookRef = _books.doc(request.bookId);

    // Use a transaction to ensure the book is still available when approving.
    try {
      await _db.runTransaction((transaction) async {
        final bookSnap = await transaction.get(bookRef);
        final requestSnap = await transaction.get(requestRef);
        if (!requestSnap.exists) {
          throw Exception('Request not found');
        }

        final requestData = requestSnap.data() as Map<String, dynamic>?;
        final requestStatus = (requestData != null && requestData['status'] != null)
            ? requestData['status'].toString()
            : LoanRequestStatus.pending.value;

        // Ensure the request is still pending (not already approved/rejected)
        if (requestStatus.toLowerCase() != LoanRequestStatus.pending.value.toLowerCase()) {
          throw Exception('Request is no longer pending');
        }
        if (!bookSnap.exists) {
          throw Exception('Book not found');
        }

        final bookData = bookSnap.data() as Map<String, dynamic>?;
        final currentStatus = (bookData != null && bookData['status'] != null)
            ? bookData['status'].toString()
            : BookStatus.available.value;

        if (currentStatus.toLowerCase() != BookStatus.available.value.toLowerCase()) {
          // Book already loaned/reserved — prevent double-approval
          throw Exception('Book is no longer available');
        }

        // Mark this request as approved and update the book to loaned atomically
        transaction.update(requestRef, {
          'status': LoanRequestStatus.approved.value,
          'respondedAt': DateTime.now(),
        });

        transaction.update(bookRef, {
          'status': BookStatus.loaned.value,
          'currentBorrowerId': request.requesterId,
          'dueDate': DateTime.now().add(const Duration(days: 14)),
        });
      });

      // After successful transaction, reject other pending requests for the same book
      final pending = await _requests
          .where('bookId', isEqualTo: request.bookId)
          .where('status', isEqualTo: LoanRequestStatus.pending.value)
          .get();

      for (final doc in pending.docs) {
        // Skip updating the one we just approved (it no longer has status 'pending')
        await _requests.doc(doc.id).update({
          'status': LoanRequestStatus.rejected.value,
          'respondedAt': DateTime.now(),
        });
      }
    } catch (e) {
      // Bubble up to caller so UI can show appropriate message
      rethrow;
    }
  }

  // ─── Admin: reject request ────────────────────────────────────────────────
  Future<void> rejectRequest(LoanRequest request) async {
    await _requests.doc(request.id).update({
      'status': LoanRequestStatus.rejected.value,
      'respondedAt': DateTime.now(),
    });
  }

  // ─── Member: check pending request for a book ────────────────────────────
  Future<bool> hasPendingRequest(String bookId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final snap = await _requests
        .where('bookId', isEqualTo: bookId)
        .where('requesterId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    return snap.docs.isNotEmpty;
  }

  // ─── Member: stream their own requests ───────────────────────────────────
  Stream<List<LoanRequest>> myRequestsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _requests
        .where('requesterId', isEqualTo: uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LoanRequest.fromFirestore(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }
}
