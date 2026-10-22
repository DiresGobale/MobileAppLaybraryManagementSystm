import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book.dart';
import '../../models/loan.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/loan_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../utils/date_utils.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_overlay.dart' as overlay;

class IssueLoanScreen extends StatefulWidget {
  const IssueLoanScreen({super.key});

  @override
  State<IssueLoanScreen> createState() => _IssueLoanScreenState();
}

class _IssueLoanScreenState extends State<IssueLoanScreen> {
  final _searchCtrl = TextEditingController();
  List<BookWithCategory> _bookResults = [];
  BookWithCategory? _selectedBook;
  User? _selectedUser;
  String? _selectedUserQuery;
  List<User> _userResults = [];
  int _loanDays = 14;
  bool _searching = false;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLoanDays());
  }

  Future<void> _initLoanDays() async {
    final auth = context.read<AuthProvider>();
    final days = await auth.defaultLoanDays();
    setState(() => _loanDays = days);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && _selectedBook == null) {
      _loadBook(args);
    }
  }

  Future<void> _loadBook(int bookId) async {
    final books = context.read<BookProvider>();
    final b = await books.getBook(bookId);
    if (b != null) {
      // find the matching BookWithCategory from existing list or build a synthetic one
      await books.refresh();
      final match = books.items.firstWhere(
        (i) => i.book.id == bookId,
        orElse: () => BookWithCategory(book: b, categoryName: null),
      );
      setState(() => _selectedBook = match);
    }
  }

  Future<void> _searchBooks(String query) async {
    final books = context.read<BookProvider>();
    setState(() => _searching = true);
    final results = await books.search(query: query, availableOnly: true);
    setState(() {
      _bookResults = results;
      _searching = false;
    });
  }

  Future<void> _searchUsers(String query) async {
    final auth = context.read<AuthProvider>();
    final users = await auth.listUsers(roleFilter: Role.student);
    setState(() {
      _selectedUserQuery = query;
      _userResults = users
          .where((u) =>
              u.fullName.toLowerCase().contains(query.toLowerCase()) ||
              (u.studentId?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              u.username.toLowerCase().contains(query.toLowerCase()) ||
              u.email.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedBook == null || _selectedUser == null) return;
    setState(() => _working = true);
    final loans = context.read<LoanProvider>();
    final auth = context.read<AuthProvider>();
    final librarianId = auth.currentUser!.id!;
    final result = await loans.issue(
      userId: _selectedUser!.id!,
      bookId: _selectedBook!.book.id!,
      librarianId: librarianId,
      overrideLoanDays: _loanDays,
    );
    setState(() => _working = false);
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Issued "${_selectedBook!.book.title}" to ${_selectedUser!.fullName}. '
              'Due ${DateUtilsX.formatDate(result.dueDate)}.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } else if (loans.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loans.error!), backgroundColor: AppTheme.danger),
      );
      loans.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: const AppHeaderBar(
        title: 'Issue Book',
        subtitle: 'Lend a book to a student',
        showBack: true,
      ),
      body: overlay.LoadingOverlay(
        loading: _working,
        message: 'Processing loan…',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('1. Select book'),
              if (_selectedBook == null) ...[
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search title, ISBN, or author',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : (_searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _bookResults = []);
                                },
                              )
                            : null),
                  ),
                  onSubmitted: (v) => _searchBooks(v),
                ),
                const SizedBox(height: 8),
                if (_bookResults.isEmpty && _searchCtrl.text.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: EmptyState(
                      icon: Icons.search_rounded,
                      title: 'Search to find an available book',
                      message: 'Start typing a title, ISBN, or author above.',
                    ),
                  )
                else if (_bookResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No available books match',
                      message: 'Try a different query.',
                    ),
                  )
                else
                  for (final b in _bookResults) _bookOption(b),
              ] else
                _selectedBookCard(_selectedBook!),
              const SizedBox(height: 16),
              _sectionTitle('2. Select student'),
              if (_selectedUser == null) ...[
                TextField(
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search by name, Student ID, username, or email',
                    prefixIcon: Icon(Icons.person_search_rounded, size: 20),
                  ),
                  onChanged: (v) {
                    if (v.length >= 2) _searchUsers(v);
                    else setState(() => _userResults = []);
                  },
                ),
                const SizedBox(height: 8),
                if (_userResults.isEmpty && _selectedUserQuery != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: EmptyState(
                      icon: Icons.person_off_outlined,
                      title: 'No matching students',
                      message: 'Check the spelling or register the student first.',
                    ),
                  )
                else
                  for (final u in _userResults.take(5)) _userOption(u),
              ] else
                _selectedUserCard(_selectedUser!),
              const SizedBox(height: 16),
              _sectionTitle('3. Loan period (days)'),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: 30,
                      divisions: 29,
                      value: _loanDays.toDouble(),
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _loanDays = v.round()),
                    ),
                  ),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_loanDays d',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'PT Serif',
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedBook != null && _selectedUser != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.45)),
                    ),
                    child: Text(
                      'Due on ${DateUtilsX.formatDate(DateTime.now().add(Duration(days: _loanDays)))}',
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontFamily: 'PT Serif',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedBook != null && _selectedUser != null && !_working
                      ? _submit
                      : null,
                  icon: const Icon(Icons.local_library_rounded),
                  label: const Text('Issue Book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6, top: 8),
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

  Widget _bookOption(BookWithCategory b) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.menu_book_rounded, color: AppTheme.primary, size: 22),
          title: Text(b.book.title),
          subtitle: Text('${b.book.author} · ${b.book.isbn}',
              style: const TextStyle(fontFamily: 'PT Serif', fontSize: 12, color: AppTheme.slate)),
          trailing: Text(
            '${b.book.availableQuantity} left',
            style: const TextStyle(
                color: AppTheme.success, fontFamily: 'PT Serif', fontSize: 12, fontWeight: FontWeight.w700),
          ),
          onTap: () => setState(() => _selectedBook = b),
        ),
      );

  Widget _userOption(User u) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.person_outline_rounded, color: AppTheme.burgundy, size: 22),
          title: Text(u.fullName),
          subtitle: Text(
            '${u.studentId ?? '—'} · ${u.email}',
            style: const TextStyle(fontFamily: 'PT Serif', fontSize: 12, color: AppTheme.slate),
          ),
          onTap: () => setState(() => _selectedUser = u),
        ),
      );

  Widget _selectedBookCard(BookWithCategory b) => Card(
        color: AppTheme.primary.withOpacity(0.06),
        child: ListTile(
          leading: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 22),
          title: Text(b.book.title),
          subtitle: Text(b.book.author),
          trailing: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.danger),
            onPressed: () => setState(() => _selectedBook = null),
          ),
        ),
      );

  Widget _selectedUserCard(User u) => Card(
        color: AppTheme.burgundy.withOpacity(0.06),
        child: ListTile(
          leading: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 22),
          title: Text(u.fullName),
          subtitle: Text('${u.studentId ?? '—'} · ${u.email}'),
          trailing: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.danger),
            onPressed: () => setState(() => _selectedUser = null),
          ),
        ),
      );
}
