import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/loan.dart';
import '../models/app_notification.dart';
import '../repositories/book_repository.dart';
import '../repositories/loan_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/activity_log_repository.dart';
import '../repositories/settings_repository.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class LoanService {
  final LoanRepository _loans;
  final BookRepository _books;
  final NotificationRepository _notifications;
  final ActivityLogRepository _logs;
  final SettingsRepository _settings;

  LoanService(this._loans, this._books, this._notifications, this._logs, this._settings);

  Future<int> defaultLoanDays() async =>
      await _settings.getInt(AppConstants.keyLoanDays, defaultValue: 14);

  Future<int> maxActiveLoans() async =>
      await _settings.getInt(AppConstants.keyMaxActiveLoans, defaultValue: 3);

  /// Issues a book to a student. Uses a transaction to atomically:
  /// 1. Reconcile overdue loans.
  /// 2. Check eligibility + availability.
  /// 3. Decrement available_quantity.
  /// 4. Insert loan row.
  /// 5. Insert notification.
  Future<Loan> issue({
    required int userId,
    required int bookId,
    required int librarianId,
    DateTime? issueDate,
    int? overrideLoanDays,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = issueDate ?? DateTime.now();

    final loanDays = overrideLoanDays ?? await defaultLoanDays();
    final dueDate = now.add(Duration(days: loanDays));

    return db.transaction((txn) async {
      // Reconcile overdue first
      await _loans.reconcileOverdue(txn);

      // Check user exists + active
      final userRows = await txn.query('users',
          where: 'id = ? AND is_active = 1', whereArgs: [userId]);
      if (userRows.isEmpty) {
        throw LoanException('Student not found or inactive.');
      }

      // Check book + availability
      final bookRows = await txn.query('books', where: 'id = ?', whereArgs: [bookId]);
      if (bookRows.isEmpty) {
        throw LoanException('Book not found.');
      }
      final available = bookRows.first['available_quantity'] as int;
      final total = bookRows.first['total_quantity'] as int;
      final title = bookRows.first['title'] as String;
      if (available <= 0) {
        throw LoanException('No copies available for "$title".');
      }

      // Borrowing limit
      final activeCount = await _loanCountForUserInTxn(txn, userId);
      final max = await maxActiveLoans();
      if (activeCount >= max) {
        throw LoanException(
            'Student already has $activeCount active loan(s). Limit is $max.');
      }

      // Decrement available (atomic CAS).
      final affected = await _books.decrementAvailable(bookId, txn);
      if (affected == 0) {
        throw LoanException('Inventory race: book no longer available. Please retry.');
      }

      // Insert loan row.
      final loanId = await txn.insert('loans', {
        'user_id': userId,
        'book_id': bookId,
        'issued_by': librarianId,
        'issue_date': now.millisecondsSinceEpoch,
        'due_date': dueDate.millisecondsSinceEpoch,
        'return_date': null,
        'status': AppConstants.statusActive,
      });

      // Notification.
      await txn.insert('notifications', {
        'user_id': userId,
        'title': AppConstants.notifLoanIssued,
        'message': '"$title" was issued to your account. '
            'Due on ${_prettyDate(dueDate)}.',
        'created_at': now.millisecondsSinceEpoch,
        'is_read': 0,
      });

      // Activity log (outside txn is fine but keep here for atomicity).
      await txn.insert('activity_logs', {
        'user_id': librarianId,
        'action': AppConstants.actionLoanIssue,
        'details': 'Issued book #$bookId "$title" to user #$userId. '
            'Due ${_prettyDate(dueDate)}.',
        'created_at': now.millisecondsSinceEpoch,
      });

      final loan = Loan(
        id: loanId,
        userId: userId,
        bookId: bookId,
        issuedBy: librarianId,
        issueDate: now,
        dueDate: dueDate,
        status: AppConstants.statusActive,
      );
      return loan;
    });
  }

  /// Returns a loan (marks returned + increments inventory).
  Future<Loan> returnLoan({
    required int loanId,
    required int librarianId,
    DateTime? returnedAt,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = returnedAt ?? DateTime.now();

    return db.transaction((txn) async {
      final loanRows = await txn.query('loans', where: 'id = ?', whereArgs: [loanId]);
      if (loanRows.isEmpty) {
        throw LoanException('Loan not found.');
      }
      final row = loanRows.first;
      final status = row['status'] as String;
      if (status == AppConstants.statusReturned) {
        throw LoanException('This loan has already been returned.');
      }
      final userId = row['user_id'] as int;
      final bookId = row['book_id'] as int;

      // Update loan row.
      await txn.update(
        'loans',
        {
          'status': AppConstants.statusReturned,
          'return_date': now.millisecondsSinceEpoch,
        },
        where: 'id = ? AND status != ?',
        whereArgs: [loanId, AppConstants.statusReturned],
      );

      // Increment available (cap at total).
      final affected = await _books.incrementAvailable(bookId, txn);
      if (affected == 0) {
        // Already at total — soft warning; loan is still returned.
        // Don't throw; the book's inventory just can't increase further.
      }

      // Fetch book title for notification.
      final bookRows = await txn.query('books', where: 'id = ?', whereArgs: [bookId]);
      final title = bookRows.isNotEmpty ? bookRows.first['title'] as String : 'Book #$bookId';

      // Notification.
      await txn.insert('notifications', {
        'user_id': userId,
        'title': AppConstants.notifReturned,
        'message': '"$title" was returned successfully on ${_prettyDate(now)}.',
        'created_at': now.millisecondsSinceEpoch,
        'is_read': 0,
      });

      // Activity log.
      await txn.insert('activity_logs', {
        'user_id': librarianId,
        'action': AppConstants.actionLoanReturn,
        'details': 'Returned loan #$loanId (book "$title", user #$userId).',
        'created_at': now.millisecondsSinceEpoch,
      });

      final updatedRow = (await txn.query('loans', where: 'id = ?', whereArgs: [loanId])).first;
      return Loan.fromMap(updatedRow);
    });
  }

  /// Reconciles overdue status across all active loans.
  /// Call on app startup or via a periodic refresh button.
  Future<int> reconcileOverdue() async {
    final db = await DatabaseHelper.instance.database;
    return db.transaction((txn) async => _loans.reconcileOverdue(txn));
  }

  Future<List<LoanDetail>> overdueLoans() => _loans.overdueLoans();
  Future<List<LoanDetail>> activeForUser(int userId) => _loans.activeForUser(userId);
  Future<List<LoanDetail>> historyForUser(int userId) => _loans.historyForUser(userId);
  Future<List<LoanDetail>> activeForBook(int bookId) => _loans.activeForBook(bookId);
  Future<List<LoanDetail>> loansBetween(DateTime from, DateTime to) =>
      _loans.loansBetween(from, to);
  Future<List<LoanDetail>> recentLoans({int limit = 10}) =>
      _loans.recentLoans(limit: limit);

  Future<int> _loanCountForUserInTxn(Transaction txn, int userId) async {
    final rows = await txn.rawQuery(
      "SELECT COUNT(*) AS n FROM loans WHERE user_id = ? AND status IN ('active','overdue')",
      [userId],
    );
    return (rows.first['n'] as int?) ?? 0;
  }

  String _prettyDate(DateTime d) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class LoanException implements Exception {
  final String message;
  LoanException(this.message);
  @override
  String toString() => message;
}
