import 'package:cloud_firestore/cloud_firestore.dart';

enum LoanRequestStatus { pending, approved, rejected }

extension LoanRequestStatusExtension on LoanRequestStatus {
  String get value {
    switch (this) {
      case LoanRequestStatus.pending:  return 'pending';
      case LoanRequestStatus.approved: return 'approved';
      case LoanRequestStatus.rejected: return 'rejected';
    }
  }

  static LoanRequestStatus fromString(String s) {
    switch (s) {
      case 'approved': return LoanRequestStatus.approved;
      case 'rejected': return LoanRequestStatus.rejected;
      default:         return LoanRequestStatus.pending;
    }
  }
}

class LoanRequest {
  final String id;
  final String bookId;
  final String bookTitle;
  final String requesterId;
  final String requesterName;
  final LoanRequestStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;

  LoanRequest({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.requesterId,
    required this.requesterName,
    this.status = LoanRequestStatus.pending,
    required this.requestedAt,
    this.respondedAt,
  });

  Map<String, dynamic> toFirestore() => {
    'bookId': bookId,
    'bookTitle': bookTitle,
    'requesterId': requesterId,
    'requesterName': requesterName,
    'status': status.value,
    'requestedAt': requestedAt,
    'respondedAt': respondedAt,
  };

  factory LoanRequest.fromFirestore(Map<String, dynamic> data, String id) => LoanRequest(
    id: id,
    bookId: data['bookId'] ?? '',
    bookTitle: data['bookTitle'] ?? '',
    requesterId: data['requesterId'] ?? '',
    requesterName: data['requesterName'] ?? '',
    status: LoanRequestStatusExtension.fromString(data['status'] ?? 'pending'),
    requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
  );
}
