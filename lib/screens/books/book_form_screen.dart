import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/app_header_bar.dart';

class BookFormScreen extends StatefulWidget {
  final int? bookId;
  const BookFormScreen({super.key, this.bookId});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  bool _isEdit = false;

  final _isbn = TextEditingController();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _publisher = TextEditingController();
  final _year = TextEditingController();
  final _edition = TextEditingController();
  final _shelf = TextEditingController();
  final _description = TextEditingController();
  final _totalQty = TextEditingController(text: '1');

  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = context.read<BookProvider>();
    await books.loadCategories();
    if (widget.bookId != null) {
      _isEdit = true;
      final b = await books.getBook(widget.bookId!);
      if (b != null) {
        _isbn.text = b.isbn;
        _title.text = b.title;
        _author.text = b.author;
        _publisher.text = b.publisher ?? '';
        _year.text = b.publicationYear?.toString() ?? '';
        _edition.text = b.edition ?? '';
        _shelf.text = b.shelfLocation ?? '';
        _description.text = b.description ?? '';
        _totalQty.text = b.totalQuantity.toString();
        _categoryId = b.categoryId;
      }
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _isbn.dispose();
    _title.dispose();
    _author.dispose();
    _publisher.dispose();
    _year.dispose();
    _edition.dispose();
    _shelf.dispose();
    _description.dispose();
    _totalQty.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final books = context.read<BookProvider>();
      final auth = context.read<AuthProvider>();
      final now = DateTime.now();
      final total = int.parse(_totalQty.text.trim());

      if (widget.bookId == null) {
        // New book — available = total initially
        final book = Book(
          isbn: _isbn.text.trim(),
          title: _title.text.trim(),
          author: _author.text.trim(),
          categoryId: _categoryId,
          publisher: _publisher.text.trim().isEmpty ? null : _publisher.text.trim(),
          publicationYear: int.tryParse(_year.text.trim()),
          edition: _edition.text.trim().isEmpty ? null : _edition.text.trim(),
          shelfLocation: _shelf.text.trim().isEmpty ? null : _shelf.text.trim(),
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          totalQuantity: total,
          availableQuantity: total,
          createdAt: now,
          updatedAt: now,
        );
        await books.createBook(book, actorId: auth.currentUser!.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book added to the catalog.'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        final existing = await books.getBook(widget.bookId!);
        if (existing == null) {
          throw Exception('Book not found.');
        }
        // Preserve available_quantity by computing the delta.
        final newTotal = total;
        final oldTotal = existing.totalQuantity;
        final delta = newTotal - oldTotal;
        final newAvailable = (existing.availableQuantity + delta).clamp(0, newTotal);
        final book = existing.copyWith(
          isbn: _isbn.text.trim(),
          title: _title.text.trim(),
          author: _author.text.trim(),
          categoryId: _categoryId,
          publisher: _publisher.text.trim().isEmpty ? null : _publisher.text.trim(),
          publicationYear: int.tryParse(_year.text.trim()),
          edition: _edition.text.trim().isEmpty ? null : _edition.text.trim(),
          shelfLocation: _shelf.text.trim().isEmpty ? null : _shelf.text.trim(),
          description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          totalQuantity: newTotal,
          availableQuantity: newAvailable,
          updatedAt: now,
        );
        await books.updateBook(book, actorId: auth.currentUser!.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book updated.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BookProvider>();
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppHeaderBar(
        title: _isEdit ? 'Edit Book' : 'Add New Book',
        subtitle: _isEdit ? 'Update catalog entry' : 'Create a catalog entry',
        showBack: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(_isEdit ? 'Catalog fields' : 'Required catalog fields'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _field(_isbn, 'ISBN', '978-...',
                                validator: (v) => Validators.isbn(v)),
                            _field(_title, 'Title', 'Book title',
                                validator: (v) => Validators.required(v, label: 'Title')),
                            _field(_author, 'Author', 'Primary author',
                                validator: (v) => Validators.required(v, label: 'Author')),
                            DropdownButtonFormField<int?>(
                              value: _categoryId,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined, size: 20),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('Uncategorized')),
                                ...books.categories.map((c) => DropdownMenuItem<int?>(
                                      value: c.id,
                                      child: Text(c.name),
                                    )),
                              ],
                              onChanged: (v) => setState(() => _categoryId = v),
                            ),
                            _field(_publisher, 'Publisher', 'Optional'),
                            _field(_year, 'Publication year', 'e.g. 2023',
                                keyboardType: TextInputType.number,
                                validator: (v) => Validators.year(v)),
                            _field(_edition, 'Edition', 'Optional, e.g. 3rd'),
                            _field(_shelf, 'Shelf / location code', 'e.g. A-12'),
                            _field(_description, 'Description', 'Short summary',
                                maxLines: 3),
                            _field(_totalQty, 'Total quantity', '1',
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    Validators.positiveInt(v, label: 'Total quantity')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _submit,
                            icon: _saving
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_isEdit ? 'Save Changes' : 'Add Book'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
          ),
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
        ),
      );
}
