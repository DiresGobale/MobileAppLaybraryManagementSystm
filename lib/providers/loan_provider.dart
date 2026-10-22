import 'package:flutter/foundation.dart';

import '../models/loan.dart';
import '../services/loan_service.dart';

class LoanProvider extends ChangeNotifier {
  final dynamic _service; // LoanService or RemoteLoanService
  LoanProvider(this._service);

  List<LoanDetail> _activeLoans = [];
  List<LoanDetail> _historyLoans = [];
  List<LoanDetail> _overdueLoans = [];
  List<LoanDetail> _recentLoans = [];
  bool _loading = false;
  String? _error;

  List<LoanDetail> get activeLoans => _activeLoans;
  List<LoanDetail> get historyLoans => _historyLoans;
  List<LoanDetail> get overdueLoans => _overdueLoans;
  List<LoanDetail> get recentLoans => _recentLoans;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> reconcileOverdue() async {
    await _service.reconcileOverdue();
  }

  Future<void> loadActiveForUser(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.reconcileOverdue();
      _activeLoans = await _service.activeForUser(userId);
      _historyLoans = await _service.historyForUser(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadOverdue() async {
    _loading = true;
    notifyListeners();
    try {
      await _service.reconcileOverdue();
      _overdueLoans = await _service.overdueLoans();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecent({int limit = 10}) async {
    try {
      _recentLoans = await _service.recentLoans(limit: limit);
    } finally {
      notifyListeners();
    }
  }

  Future<Loan?> issue({
    required int userId,
    required int bookId,
    required int librarianId,
    int? overrideLoanDays,
  }) async {
    try {
      final loan = await _service.issue(
        userId: userId,
        bookId: bookId,
        librarianId: librarianId,
        overrideLoanDays: overrideLoanDays,
      );
      _error = null;
      notifyListeners();
      return loan;
    } on LoanException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<Loan?> returnLoan({required int loanId, required int librarianId}) async {
    try {
      final loan = await _service.returnLoan(loanId: loanId, librarianId: librarianId);
      _error = null;
      notifyListeners();
      return loan;
    } on LoanException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<List<LoanDetail>> activeForUser(int userId) =>
      _service.activeForUser(userId);

  /// Active loans for a specific book — used by BookDetailScreen.
  Future<List<LoanDetail>> activeForBook(int bookId) =>
      _service.activeForBook(bookId);

  Future<List<LoanDetail>> loansBetween(DateTime from, DateTime to) =>
      _service.loansBetween(from, to);

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
