import '../models/book.dart';
import '../models/loan.dart';
import '../models/report.dart';
import '../repositories/book_repository.dart';
import '../repositories/loan_repository.dart';
import '../repositories/user_repository.dart';
import '../utils/constants.dart';

class ReportService {
  final BookRepository _books;
  final LoanRepository _loans;
  final UserRepository _users;

  ReportService(this._books, this._loans, this._users);

  Future<DashboardStats> dashboardStats({int recentLimit = 10}) async {
    final overdue = await _loans.countStatus(AppConstants.statusOverdue);
    final active = await _loans.countStatus(AppConstants.statusActive);
    final recent = await _loans.recentLoans(limit: recentLimit);

    return DashboardStats(
      totalBooks: await _books.countTitles(),
      availableBooks: await _books.sumAvailableCopies(),
      borrowedBooks: await _books.sumBorrowedCopies(),
      registeredStudents: await _users.countStudents(),
      overdueLoans: overdue,
      activeLoans: active,
      totalLoans: await _loans.countTotal(),
      recentLoans: recent,
    );
  }

  Future<BookInventorySummary> inventorySummary() async {
    final titles = await _books.countTitles();
    final total = await _books.sumTotalCopies();
    final available = await _books.sumAvailableCopies();
    final borrowed = total - available;
    final outOfStock = await _books.countOutOfStock();
    final categories = await _books.countCategories();
    return BookInventorySummary(
      totalTitles: titles,
      totalCopies: total,
      availableCopies: available,
      borrowedCopies: borrowed,
      outOfStockTitles: outOfStock,
      categories: categories,
    );
  }

  /// Returns the top [limit] most-borrowed titles (by loan count).
  Future<List<PopularBook>> popularBooks({int limit = 10}) async {
    final db = await _books.rawDb;
    final rows = await db.rawQuery('''
      SELECT b.*, COUNT(l.id) AS loan_count
      FROM books b
        JOIN loans l ON l.book_id = b.id
      GROUP BY b.id
      ORDER BY loan_count DESC, b.title ASC
      LIMIT ?
    ''', [limit]);
    return rows
        .map((r) => PopularBook(
              book: Book.fromMap(r),
              loanCount: r['loan_count'] as int,
            ))
        .toList();
  }

  Future<List<LoanDetail>> loansBetween(DateTime from, DateTime to) =>
      _loans.loansBetween(from, to);

  Future<List<LoanDetail>> overdueLoans() => _loans.overdueLoans();

  Future<String> toCsv(List<LoanDetail> loans) {
    final buf = StringBuffer();
    buf.writeln('loan_id,user,student_id,book_title,isbn,author,issued_by,'
        'issue_date,due_date,return_date,status');
    for (final l in loans) {
      buf.writeln([
        l.loan.id,
        _csv(l.userName),
        _csv(l.userStudentId ?? ''),
        _csv(l.bookTitle),
        _csv(l.bookIsbn),
        _csv(l.bookAuthor),
        _csv(l.librarianName ?? ''),
        l.loan.issueDate.toIso8601String(),
        l.loan.dueDate.toIso8601String(),
        l.loan.returnDate?.toIso8601String() ?? '',
        l.loan.status,
      ].join(','));
    }
    return Future.value(buf.toString());
  }

  String _csv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
