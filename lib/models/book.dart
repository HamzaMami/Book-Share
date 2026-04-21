import 'package:cloud_firestore/cloud_firestore.dart';

enum BookStatus { available, loaned, reserved }

extension BookStatusExtension on BookStatus {
  String get value {
    switch (this) {
      case BookStatus.available: return 'Available';
      case BookStatus.loaned:    return 'Loaned';
      case BookStatus.reserved:  return 'Reserved';
    }
  }

  static BookStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'loaned':   return BookStatus.loaned;
      case 'reserved': return BookStatus.reserved;
      default:         return BookStatus.available;
    }
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String genre;
  final String isbn;
  final String coverUrl;
  final BookStatus status;
  final String addedByUid;
  final DateTime createdAt;
  final String? currentBorrowerId;
  final DateTime? dueDate;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description = '',
    this.genre = '',
    this.isbn = '',
    this.coverUrl = '',
    this.status = BookStatus.available,
    required this.addedByUid,
    required this.createdAt,
    this.currentBorrowerId,
    this.dueDate,
  });

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'author': author,
    'description': description,
    'genre': genre,
    'isbn': isbn,
    'coverUrl': coverUrl,
    'status': status.value,
    'addedByUid': addedByUid,
    'createdAt': createdAt,
    'currentBorrowerId': currentBorrowerId,
    'dueDate': dueDate,
  };

  factory Book.fromFirestore(Map<String, dynamic> data, String id) => Book(
    id: id,
    title: data['title'] ?? '',
    author: data['author'] ?? '',
    description: data['description'] ?? '',
    genre: data['genre'] ?? '',
    isbn: data['isbn'] ?? '',
    coverUrl: data['coverUrl'] ?? '',
    status: BookStatusExtension.fromString(data['status'] ?? 'Available'),
    addedByUid: data['addedByUid'] ?? '',
    createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    currentBorrowerId: data['currentBorrowerId'],
    dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
  );

  Book copyWith({
    String? title,
    String? author,
    String? description,
    String? genre,
    String? isbn,
    String? coverUrl,
    BookStatus? status,
    String? currentBorrowerId,
    DateTime? dueDate,
  }) => Book(
    id: id,
    title: title ?? this.title,
    author: author ?? this.author,
    description: description ?? this.description,
    genre: genre ?? this.genre,
    isbn: isbn ?? this.isbn,
    coverUrl: coverUrl ?? this.coverUrl,
    status: status ?? this.status,
    addedByUid: addedByUid,
    createdAt: createdAt,
    currentBorrowerId: currentBorrowerId ?? this.currentBorrowerId,
    dueDate: dueDate ?? this.dueDate,
  );
}