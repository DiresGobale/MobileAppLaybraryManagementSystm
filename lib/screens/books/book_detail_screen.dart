import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book.dart';
import '../../models/category.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/loan_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_overlay.dart' as overlay;

class BookDetailScreen extends StatefulWidget {
  final int bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book;
  Category? _category;
  List<dynamic> _activeLoans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = context.read<BookProvider>();
    final loans = context.read<LoanProvider>();
    final book = await books.getBook(widget.bookId);
    Category? cat;
    if (book?.categoryId != null) {
      // If the provider has already loaded categories, look it up locally;
      // otherwise ask the BookProvider for a fresh list and search it.
      var list = books.categories;
      if (list.isEmpty) {
        await books.loadCategories();
        list = books.categories;
      }
      try {
        cat = list.firstWhere((c) => c.id == book!.categoryId);
      } catch (_) {
        cat = null;
      }
    }
    final active = await loans.activeForBook(widget.bookId);
    setState(() {
      _book = book;
      _category = cat;
      _activeLoans = active;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    final canManage = user.canManageBooks;
    final canIssue = user.canIssueBooks;
    final isStudent = user.isStudent;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: const AppHeaderBar(
        title: 'Book Details',
        showBack: true,
      ),
      body: overlay.LoadingOverlay(
        loading: _loading,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _book == null
                ? const EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'Book not found',
                    message: 'This book may have been removed.',
                  )
                : _body(context, _book!, user, canManage, canIssue, isStudent),
      ),
    );
  }

  Widget _body(BuildContext context, Book b, User user, bool canManage,
      bool canIssue, bool isStudent) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 90,
                  height: 124,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.6), width: 1.4),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: AppTheme.accent, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.title,
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.author,
                        style: const TextStyle(
                          fontFamily: 'PT Serif',
                          fontSize: 13,
                          color: AppTheme.slate,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _availability(b),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _sectionTitle('About this book'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              b.description?.trim().isNotEmpty == true
                  ? b.description!
                  : 'No description provided for this title. Contact the library if you need additional catalog information.',
              style: const TextStyle(
                fontFamily: 'PT Serif',
                fontSize: 13.5,
                color: AppTheme.ink,
                height: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _sectionTitle('Catalog details'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row('ISBN', b.isbn),
                _row('Category', _category?.name ?? 'Uncategorized'),
                _row('Publisher', b.publisher ?? '—'),
                _row('Publication year', b.publicationYear?.toString() ?? '—'),
                _row('Edition', b.edition ?? '—'),
                _row('Shelf location', b.shelfLocation ?? '—'),
                _row('Total copies', b.totalQuantity.toString()),
                _row('Available copies', b.availableQuantity.toString()),
                _row('Currently borrowed', b.borrowedCount.toString()),
                _row('Added on', DateUtilsX.formatDate(b.createdAt)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (canIssue && _activeLoans.isNotEmpty) ...[
          _sectionTitle('Active loans for this book (${_activeLoans.length})'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: _activeLoans.map((l) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primary, size: 20),
                  title: Text(l.userName),
                  subtitle: Text('Due ${DateUtilsX.formatDate(l.loan.dueDate)}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.warning,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'On loan',
                      style: TextStyle(color: Colors.white, fontFamily: 'PT Serif', fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            if (canManage) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.bookForm,
                    arguments: b.id,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger, width: 1.2),
                  ),
                  onPressed: () => _confirmDelete(b),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                ),
              ),
            ] else if (isStudent && b.isAvailable)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _contactLibrarian(context),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Request at counter'),
                ),
              ),
            if (canIssue && b.isAvailable) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(context, AppRoutes.issueLoan, arguments: b.id);
                    _load();
                  },
                  icon: const Icon(Icons.local_library_rounded, size: 18),
                  label: const Text('Issue'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.slate,
                  fontFamily: 'PT Serif',
                  fontSize: 12.5,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontFamily: 'PT Serif',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _availability(Book b) {
    final isAvail = b.isAvailable;
    final color = isAvail ? AppTheme.success : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.45), width: 1),
      ),
      child: Text(
        isAvail
            ? '${b.availableQuantity} of ${b.totalQuantity} available'
            : 'Currently out of stock',
        style: TextStyle(
          color: color,
          fontFamily: 'PT Serif',
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Book b) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete book',
      message: 'Are you sure you want to permanently delete "${b.title}"? '
          'Books with active loans cannot be deleted.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (confirmed != true) return;
    try {
      final books = context.read<BookProvider>();
      final auth = context.read<AuthProvider>();
      await books.deleteBook(b.id!, actorId: auth.currentUser!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${b.title}"'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
      );
    }
  }

  void _contactLibrarian(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Please visit the circulation desk to borrow this book. Students cannot self-issue books.'),
        backgroundColor: AppTheme.primary,
        duration: Duration(seconds: 4),
      ),
    );
  }
}
