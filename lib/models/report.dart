import '../models/loan.dart';
import '../models/book.dart';

/// Stats computed for a dashboard.
class DashboardStats {
  final int totalBooks;
  final int availableBooks;
  final int borrowedBooks;
  final int registeredStudents;
  final int overdueLoans;
  final int activeLoans;
  final int totalLoans;
  final List<LoanDetail> recentLoans;

  const DashboardStats({
    this.totalBooks = 0,
    this.availableBooks = 0,
    this.borrowedBooks = 0,
    this.registeredStudents = 0,
    this.overdueLoans = 0,
    this.activeLoans = 0,
    this.totalLoans = 0,
    this.recentLoans = const [],
  });
}

class BookInventorySummary {
  final int totalTitles;
  final int totalCopies;
  final int availableCopies;
  final int borrowedCopies;
  final int outOfStockTitles;
  final int categories;

  const BookInventorySummary({
    this.totalTitles = 0,
    this.totalCopies = 0,
    this.availableCopies = 0,
    this.borrowedCopies = 0,
    this.outOfStockTitles = 0,
    this.categories = 0,
  });
}

class PopularBook {
  final Book book;
  final int loanCount;

  PopularBook({required this.book, required this.loanCount});
}
