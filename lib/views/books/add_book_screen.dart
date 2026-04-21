import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookshare/models/book.dart';
import 'package:bookshare/services/Book_service.dart';
import 'package:bookshare/components/default_button.dart';
import 'package:bookshare/components/default_form_field.dart';


class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookService = BookService();

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _isbnController = TextEditingController();
  final _coverUrlController = TextEditingController();

  String _selectedGenre = 'Fiction';
  bool _isLoading = false;

  final List<String> _genres = [
    'Fiction', 'Non-Fiction', 'Science', 'History',
    'Biography', 'Technology', 'Philosophy', 'Art',
    'Children', 'Other',
  ];

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final book = Book(
        id: '',
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        genre: _selectedGenre,
        isbn: _isbnController.text.trim(),
        coverUrl: _coverUrlController.text.trim(),
        addedByUid: uid,
        createdAt: DateTime.now(),
      );

      await _bookService.addBook(book);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book added successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add book: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _isbnController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Add New Book',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover preview
              Center(
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.book, size: 48, color: Color(0xFF007AFF)),
                ),
              ),
              const SizedBox(height: 24),

              _SectionLabel('Book Info'),
              const SizedBox(height: 12),

              DefaultFormField(
                controller: _titleController,
                type: TextInputType.text,
                label: 'Title',
                prefix: const Icon(Icons.title, size: 20),
                validate: (v) => (v == null || v.isEmpty) ? 'Title is required.' : null,
                onChange: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              DefaultFormField(
                controller: _authorController,
                type: TextInputType.text,
                label: 'Author',
                prefix: const Icon(Icons.person_outline, size: 20),
                validate: (v) => (v == null || v.isEmpty) ? 'Author is required.' : null,
                onChange: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Genre dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGenre,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _genres
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGenre = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              DefaultFormField(
                controller: _descriptionController,
                type: TextInputType.multiline,
                label: 'Description (optional)',
                prefix: const Icon(Icons.notes, size: 20),
                validate: (_) => null,
                onChange: (_) {},
              ),
              const SizedBox(height: 24),

              _SectionLabel('Additional Details'),
              const SizedBox(height: 12),

              DefaultFormField(
                controller: _isbnController,
                type: TextInputType.number,
                label: 'ISBN (optional)',
                prefix: const Icon(Icons.qr_code, size: 20),
                validate: (_) => null,
                onChange: (_) {},
              ),
              const SizedBox(height: 16),

              DefaultFormField(
                controller: _coverUrlController,
                type: TextInputType.url,
                label: 'Cover Image URL (optional)',
                prefix: const Icon(Icons.image_outlined, size: 20),
                validate: (_) => null,
                onChange: (_) {},
              ),
              const SizedBox(height: 32),

              DefaultButton(
                text: 'Add Book',
                pressed: _handleSubmit,
                activated: _titleController.text.isNotEmpty &&
                    _authorController.text.isNotEmpty &&
                    !_isLoading,
                loading: _isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF007AFF),
        letterSpacing: 0.8,
      ),
    );
  }
}
