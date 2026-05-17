import 'package:flutter/material.dart';
import 'package:bookshare/models/loan_request.dart';
import 'package:bookshare/services/loan_request_service.dart';

class LoanRequestsScreen extends StatelessWidget {
  const LoanRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LoanRequestService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Borrow Requests',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<LoanRequest>>(
        stream: service.pendingRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No pending requests',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _RequestCard(request: requests[i], service: service),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final LoanRequest request;
  final LoanRequestService service;

  const _RequestCard({required this.request, required this.service});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _isLoading = false;

  Future<void> _approve() async {
    setState(() => _isLoading = true);
    try {
      await widget.service.approveRequest(widget.request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request approved! Book is now loaned.'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isLoading = true);
    try {
      await widget.service.rejectRequest(widget.request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final date = '${req.requestedAt.day}/${req.requestedAt.month}/${req.requestedAt.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.book_outlined, color: Color(0xFF007AFF), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(req.bookTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(req.requesterName,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const Spacer(),
              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(date, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 14),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _approve,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
