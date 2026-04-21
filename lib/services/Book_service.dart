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
      print('Error adding book: $e');
      rethrow;
    }
  }

  // ─── Update book ──────────────────────────────────────────────────────────
  Future<void> updateBook(String bookId, Map<String, dynamic> data) async {
    try {
      await _books.doc(bookId).update(data);
    } catch (e) {
      print('Error updating book: $e');
      rethrow;
    }
  }

  // ─── Delete book ──────────────────────────────────────────────────────────
  Future<void> deleteBook(String bookId) async {
    try {
      await _books.doc(bookId).delete();
    } catch (e) {
      print('Error deleting book: $e');
      rethrow;
    }
  }

  // ─── Borrow book ──────────────────────────────────────────────────────────
  Future<void> borrowBook(String bookId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    await _books.doc(bookId).update({
      'status': BookStatus.loaned.value,
      'currentBorrowerId': uid,
      'dueDate': DateTime.now().add(const Duration(days: 14)),
    });
  }

  // ─── Reserve book ─────────────────────────────────────────────────────────
  Future<void> reserveBook(String bookId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    // Add to reservation queue subcollection
    await _books.doc(bookId).collection('reservations').add({
      'userId': uid,
      'reservedAt': DateTime.now(),
    });

    await _books.doc(bookId).update({
      'status': BookStatus.reserved.value,
    });
  }

  // ─── Return book ──────────────────────────────────────────────────────────
  Future<void> returnBook(String bookId) async {
    await _books.doc(bookId).update({
      'status': BookStatus.available.value,
      'currentBorrowerId': null,
      'dueDate': null,
    });
  }

  // ─── Get single book ──────────────────────────────────────────────────────
  Future<Book?> getBook(String bookId) async {
    try {
      final doc = await _books.doc(bookId).get();
      if (!doc.exists) return null;
      return Book.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error fetching book: $e');
      return null;
    }
  }
}