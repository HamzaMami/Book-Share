import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookshare/models/book.dart';

class BookService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _books => _db.collection('Books');

  // ─── Stream all books (real-time) ────────────────────────────────────────
  Stream<List<Book>> booksStream() {
    return _books
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => Book.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // ─── Stream books borrowed by a specific user ────────────────────────────
  Stream<List<Book>> myBorrowedBooks(String uid) {
    return _books
        .where('currentBorrowerId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => Book.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // ─── Search books by title or author ─────────────────────────────────────
  Stream<List<Book>> searchBooks(String query) {
    if (query.isEmpty) return booksStream();
    final lower = query.toLowerCase();
    return booksStream().map((books) => books
        .where((b) =>
    b.title.toLowerCase().contains(lower) ||
        b.author.toLowerCase().contains(lower) ||
        b.genre.toLowerCase().contains(lower))
        .toList());
  }

  // ─── Add book (admin only — enforced in Firestore rules too) ─────────────
  Future<void> addBook(Book book) async {
    try {
      await _books.add(book.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // ─── Update book ──────────────────────────────────────────────────────────
  Future<void> updateBook(String bookId, Map<String, dynamic> data) async {
    try {
      await _books.doc(bookId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Delete book ──────────────────────────────────────────────────────────
  Future<void> deleteBook(String bookId) async {
    try {
      await _books.doc(bookId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ─── Borrow book ──────────────────────────────────────────────────────────
  Future<void> borrowBook(String bookId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final bookRef = _books.doc(bookId);
    final bookSnap = await bookRef.get();
    if (!bookSnap.exists) throw Exception('Book not found');

    final bookData = bookSnap.data() as Map<String, dynamic>?;
    final currentStatus = (bookData != null && bookData['status'] != null)
        ? bookData['status'].toString().toLowerCase()
        : BookStatus.available.value.toLowerCase();

    // If available, allow borrow
    if (currentStatus == BookStatus.available.value.toLowerCase()) {
      await bookRef.update({
        'status': BookStatus.loaned.value,
        'currentBorrowerId': uid,
        'dueDate': DateTime.now().add(const Duration(days: 14)),
      });
      return;
    }

    // If reserved, only allow the first reserver to borrow directly
    if (currentStatus == BookStatus.reserved.value.toLowerCase()) {
      final resQuery = await bookRef.collection('reservations').orderBy('reservedAt').limit(1).get();
      if (resQuery.docs.isEmpty) {
        throw Exception('No reservations found');
      }

      final firstRes = resQuery.docs.first;
      final firstUserId = firstRes.data()['userId']?.toString();
      if (firstUserId != uid) {
        throw Exception('Book reserved by another user');
      }

      // Assign book to this user and remove reservation
      await _db.runTransaction((tx) async {
        tx.update(bookRef, {
          'status': BookStatus.loaned.value,
          'currentBorrowerId': uid,
          'dueDate': DateTime.now().add(const Duration(days: 14)),
        });
        tx.delete(firstRes.reference);
      });
      return;
    }

    throw Exception('Book is not available for borrowing');
  }

  // ─── Reserve book ─────────────────────────────────────────────────────────
  Future<void> reserveBook(String bookId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final bookRef = _books.doc(bookId);
    final reservationsRef = bookRef.collection('reservations');

    // Prevent duplicate reservations by the same user
    final existing = await reservationsRef.where('userId', isEqualTo: uid).limit(1).get();
    if (existing.docs.isNotEmpty) {
      throw Exception('You already reserved this book.');
    }

    // Add reservation
    await reservationsRef.add({
      'userId': uid,
      'reservedAt': DateTime.now(),
    });

    // Only mark the book as reserved if it's currently available
    final bookSnap = await bookRef.get();
    final currentStatus = (bookSnap.exists && (bookSnap.data() as Map<String, dynamic>?)?['status'] != null)
        ? (bookSnap.data() as Map<String, dynamic>)['status'].toString()
        : BookStatus.available.value;

    if (currentStatus.toLowerCase() == BookStatus.available.value.toLowerCase()) {
      await bookRef.update({'status': BookStatus.reserved.value});
    }
  }

  // ─── Return book ──────────────────────────────────────────────────────────
  Future<void> returnBook(String bookId) async {
    final bookRef = _books.doc(bookId);

    // Get earliest reservation (if any)
    final resQuery = await bookRef.collection('reservations').orderBy('reservedAt').limit(1).get();

    if (resQuery.docs.isEmpty) {
      // No reservations — simply mark book available
      await bookRef.update({
        'status': BookStatus.available.value,
        'currentBorrowerId': null,
        'dueDate': null,
      });
      return;
    }

    final nextRes = resQuery.docs.first;
    final nextUserId = nextRes.data()['userId']?.toString();

    if (nextUserId == null || nextUserId.isEmpty) {
      // Defensive: if reservation malformed, remove it and mark available
      await nextRes.reference.delete();
      await bookRef.update({
        'status': BookStatus.available.value,
        'currentBorrowerId': null,
        'dueDate': null,
      });
      return;
    }

    // Assign the book to the next reserver atomically
    try {
      await _db.runTransaction((tx) async {
        final bSnap = await tx.get(bookRef);
        if (!bSnap.exists) throw Exception('Book not found');

        // Update book to loaned for the next user
        tx.update(bookRef, {
          'status': BookStatus.loaned.value,
          'currentBorrowerId': nextUserId,
          'dueDate': DateTime.now().add(const Duration(days: 14)),
        });

        // Remove the reservation doc
        tx.delete(nextRes.reference);
      });
    } catch (e) {
      // If transaction fails, fallback to marking book available
      await bookRef.update({
        'status': BookStatus.available.value,
        'currentBorrowerId': null,
        'dueDate': null,
      });
      rethrow;
    }
  }

  // ─── Get single book ──────────────────────────────────────────────────────
  Future<Book?> getBook(String bookId) async {
    try {
      final doc = await _books.doc(bookId).get();
      if (!doc.exists) return null;
      return Book.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Admin helper: assign a book to a specific user (atomically)
  Future<void> assignBookToUser(String bookId, String userId) async {
    final bookRef = _books.doc(bookId);
    final requestsRef = _db.collection('LoanRequests');

    await _db.runTransaction((tx) async {
      final bSnap = await tx.get(bookRef);
      if (!bSnap.exists) throw Exception('Book not found');

      final bookData = bSnap.data() as Map<String, dynamic>?;
      final currentStatus = (bookData != null && bookData['status'] != null)
          ? bookData['status'].toString().toLowerCase()
          : BookStatus.available.value.toLowerCase();

      if (currentStatus == BookStatus.loaned.value.toLowerCase()) {
        throw Exception('Book already loaned');
      }

      // Assign the book
      tx.update(bookRef, {
        'status': BookStatus.loaned.value,
        'currentBorrowerId': userId,
        'dueDate': DateTime.now().add(const Duration(days: 14)),
      });

      // Remove reservations for this user (if any)
      final resSnap = await bookRef.collection('reservations').where('userId', isEqualTo: userId).get();
      for (final r in resSnap.docs) {
        tx.delete(r.reference);
      }

      // Optionally, reject pending LoanRequests for this book
      final pendingReqs = await requestsRef.where('bookId', isEqualTo: bookId).where('status', isEqualTo: 'pending').get();
      for (final rq in pendingReqs.docs) {
        // If this request belongs to the assigned user, mark approved; otherwise reject
        if ((rq.data()['requesterId'] ?? '') == userId) {
          tx.update(rq.reference, {
            'status': 'approved',
            'respondedAt': DateTime.now(),
          });
        } else {
          tx.update(rq.reference, {
            'status': 'rejected',
            'respondedAt': DateTime.now(),
          });
        }
      }
    });
  }
}