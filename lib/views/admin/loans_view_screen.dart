import 'package:flutter/material.dart';
import 'package:bookshare/models/book.dart';
import 'package:bookshare/services/book_service.dart';

class LoansViewScreen extends StatefulWidget {
  const LoansViewScreen({super.key});

  @override
  State<LoansViewScreen> createState() => _LoansViewScreenState();
}

class _LoansViewScreenState extends State<LoansViewScreen> {
  final BookService _bookService = BookService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Currently Loaned Books',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<Book>>(
        stream: _bookService.booksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allBooks = snapshot.data ?? [];
          // Filter only loaned books
          final loanedBooks = allBooks.where((b) => b.status == BookStatus.loaned).toList();

          if (loanedBooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.library_books, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No books currently loaned',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: loanedBooks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _LoanedBookCard(book: loanedBooks[i]),
          );
        },
      ),
    );
  }
}

class _LoanedBookCard extends StatelessWidget {
  final Book book;

  const _LoanedBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final daysRemaining = book.dueDate != null 
        ? book.dueDate!.difference(DateTime.now()).inDays 
        : -1;
    
    final isOverdue = daysRemaining < 0;
    final isDueSoon = daysRemaining <= 3 && daysRemaining >= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue 
              ? Colors.red.shade300 
              : isDueSoon 
                  ? Colors.orange.shade300 
                  : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Title and Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOverdue 
                      ? Colors.red.shade100 
                      : isDueSoon 
                          ? Colors.orange.shade100 
                          : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOverdue 
                      ? 'OVERDUE' 
                      : isDueSoon 
                          ? 'DUE SOON' 
                          : 'ACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOverdue 
                        ? Colors.red.shade700 
                        : isDueSoon 
                            ? Colors.orange.shade700 
                            : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Borrower Info
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Borrowed By',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  book.currentBorrowerId ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Due Date Info
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isOverdue 
                    ? Colors.red 
                    : isDueSoon 
                        ? Colors.orange 
                        : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  book.dueDate != null
                      ? 'Due: ${book.dueDate!.toString().split(' ')[0]} (${isOverdue ? 'Overdue by ${-daysRemaining} days' : '$daysRemaining days remaining'})'
                      : 'No due date set',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverdue 
                        ? Colors.red 
                        : isDueSoon 
                            ? Colors.orange 
                            : Colors.blue,
                    fontWeight: isDueSoon || isOverdue ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}




