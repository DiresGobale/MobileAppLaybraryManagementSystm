const { BookModel } = require('../models/bookModel');
const LoanModel = require('../models/loanModel');
const UserModel = require('../models/userModel');
const { ActivityLogModel } = require('../models/auxModels');
const { toCsv } = require('../utils/csv');

class ReportService {
  dashboardStats({ recentLimit = 10 } = {}) {
    const overdue = LoanModel.countStatus('overdue');
    const active = LoanModel.countStatus('active');
    const recent = LoanModel.recent({ limit: recentLimit });
    return {
      totalBooks: BookModel.countTitles(),
      availableBooks: BookModel.sumAvailableCopies(),
      borrowedBooks: BookModel.sumTotalCopies() - BookModel.sumAvailableCopies(),
      registeredStudents: UserModel.countStudents(),
      overdueLoans: overdue,
      activeLoans: active,
      totalLoans: LoanModel.countTotal(),
      activityToday: ActivityLogModel.countToday(),
      recentLoans: recent,
    };
  }

  inventorySummary() {
    const titles = BookModel.countTitles();
    const total = BookModel.sumTotalCopies();
    const available = BookModel.sumAvailableCopies();
    return {
      totalTitles: titles,
      totalCopies: total,
      availableCopies: available,
      borrowedCopies: total - available,
      outOfStockTitles: BookModel.countOutOfStock(),
      categories: 0, // populated by controller via CategoryModel.count
    };
  }

  popularBooks({ limit = 10 } = {}) {
    return BookModel.popularBooks({ limit });
  }

  loansBetween(from, to) {
    return LoanModel.loansBetween(from, to);
  }

  overdueLoans() {
    return LoanModel.search({ status: 'overdue', orderBy: 'l.due_date ASC' });
  }

  toLoansCsv(loans) {
    const rows = loans.map((l) => ({
      loan_id: l.id,
      user: l.user_name,
      student_id: l.user_student_id || '',
      book_title: l.book_title,
      isbn: l.book_isbn,
      author: l.book_author,
      issued_by: l.librarian_name || '',
      issue_date: new Date(l.issue_date).toISOString(),
      due_date: new Date(l.due_date).toISOString(),
      return_date: l.return_date ? new Date(l.return_date).toISOString() : '',
      status: l.status,
    }));
    return toCsv(rows, [
      'loan_id','user','student_id','book_title','isbn','author','issued_by',
      'issue_date','due_date','return_date','status',
    ]);
  }
}

module.exports = new ReportService();
