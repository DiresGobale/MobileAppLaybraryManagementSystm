const { getDb } = require('../db/connection');
const { AppError } = require('../middleware/errorHandler');
const LoanModel = require('../models/loanModel');
const { BookModel } = require('../models/bookModel');
const UserModel = require('../models/userModel');
const { NotificationModel, ActivityLogModel, SettingModel } = require('../models/auxModels');
const { ACTION_KEYS, LOAN_STATUS, SETTINGS_KEYS } = require('../config/constants');

class LoanService {
  defaultLoanDays() {
    return SettingModel.getInt(SETTINGS_KEYS.LOAN_DAYS, 14);
  }

  maxActiveLoans() {
    return SettingModel.getInt(SETTINGS_KEYS.MAX_ACTIVE_LOANS, 3);
  }

  /**
   * Issues a book to a student. Uses a synchronous better-sqlite3 transaction
   * to atomically: (1) reconcile overdue loans, (2) check user/book eligibility,
   * (3) decrement available_quantity (CAS), (4) insert loan row,
   * (5) insert notification, (6) log activity.
   */
  issue({ userId, bookId, librarianId, overrideLoanDays = null }) {
    const db = getDb();
    const now = Date.now();
    const loanDays = overrideLoanDays ?? this.defaultLoanDays();
    const dueDate = now + loanDays * 24 * 60 * 60 * 1000;

    const issueInTx = db.transaction(() => {
      // 1. Reconcile overdue
      db.prepare(
        "UPDATE loans SET status = 'overdue' WHERE status = 'active' AND due_date < ?",
      ).run(now);

      // 2. Check user exists + active
      const user = db.prepare('SELECT * FROM users WHERE id = ? AND is_active = 1').get(userId);
      if (!user) {
        throw new AppError('Student not found or inactive.', 404, 'USER_NOT_FOUND');
      }

      // 3. Check book + availability
      const book = db.prepare('SELECT * FROM books WHERE id = ?').get(bookId);
      if (!book) throw new AppError('Book not found.', 404, 'BOOK_NOT_FOUND');
      if (book.available_quantity <= 0) {
        throw new AppError(`No copies available for "${book.title}".`, 409, 'NO_COPIES');
      }

      // 4. Borrowing limit
      const activeCount = db.prepare(
        "SELECT COUNT(*) AS n FROM loans WHERE user_id = ? AND status IN ('active','overdue')",
      ).get(userId).n;
      const max = this.maxActiveLoans();
      if (activeCount >= max) {
        throw new AppError(
          `Student already has ${activeCount} active loan(s). Limit is ${max}.`,
          409, 'LIMIT_EXCEEDED',
        );
      }

      // 5. Decrement available (CAS)
      const affected = db.prepare(
        `UPDATE books SET available_quantity = available_quantity - 1
          WHERE id = ? AND available_quantity > 0`,
      ).run(bookId).changes;
      if (affected === 0) {
        throw new AppError('Inventory race: book no longer available.', 409, 'RACE');
      }

      // 6. Insert loan row
      const loanId = db.prepare(
        `INSERT INTO loans (user_id, book_id, issued_by, issue_date, due_date, status)
         VALUES (?, ?, ?, ?, ?, ?)`,
      ).run(userId, bookId, librarianId, now, dueDate, LOAN_STATUS.ACTIVE).lastInsertRowid;

      // 7. Insert notification for the student
      db.prepare(
        'INSERT INTO notifications (user_id, title, message, created_at, is_read) VALUES (?, ?, ?, ?, 0)',
      ).run(
        userId,
        'Book Issued',
        `"${book.title}" was issued to your account. Due on ${new Date(dueDate).toLocaleDateString()}.`,
        now,
      );

      // 8. Activity log
      db.prepare(
        'INSERT INTO activity_logs (user_id, action, details, created_at) VALUES (?, ?, ?, ?)',
      ).run(
        librarianId,
        ACTION_KEYS.LOAN_ISSUE,
        `Issued book #${bookId} "${book.title}" to user #${userId}. Due ${new Date(dueDate).toISOString()}.`,
        now,
      );

      return loanId;
    });

    const loanId = issueInTx();
    return LoanModel.findById(loanId);
  }

  /**
   * Returns a loan. Same transactional approach: update loan status, increment
   * inventory, insert notification, log activity. Refuses to return an already
   * returned loan.
   */
  returnLoan({ loanId, librarianId }) {
    const db = getDb();
    const now = Date.now();

    const returnInTx = db.transaction(() => {
      const loan = db.prepare('SELECT * FROM loans WHERE id = ?').get(loanId);
      if (!loan) throw new AppError('Loan not found.', 404, 'LOAN_NOT_FOUND');
      if (loan.status === LOAN_STATUS.RETURNED) {
        throw new AppError('This loan has already been returned.', 409, 'ALREADY_RETURNED');
      }

      const book = db.prepare('SELECT * FROM books WHERE id = ?').get(loan.book_id);
      const title = book ? book.title : `Book #${loan.book_id}`;

      // Update loan row (only if not already returned).
      const affected = db.prepare(
        `UPDATE loans SET status = 'returned', return_date = ?
          WHERE id = ? AND status != 'returned'`,
      ).run(now, loanId).changes;
      if (affected === 0) {
        throw new AppError('Loan already returned.', 409, 'ALREADY_RETURNED');
      }

      // Increment inventory (cap at total).
      db.prepare(
        `UPDATE books SET available_quantity = MIN(available_quantity + 1, total_quantity)
          WHERE id = ?`,
      ).run(loan.book_id);

      // Notification for the student.
      db.prepare(
        'INSERT INTO notifications (user_id, title, message, created_at, is_read) VALUES (?, ?, ?, ?, 0)',
      ).run(
        loan.user_id,
        'Book Returned',
        `"${title}" was returned successfully on ${new Date(now).toLocaleDateString()}.`,
        now,
      );

      // Activity log.
      db.prepare(
        'INSERT INTO activity_logs (user_id, action, details, created_at) VALUES (?, ?, ?, ?)',
      ).run(
        librarianId,
        ACTION_KEYS.LOAN_RETURN,
        `Returned loan #${loanId} (book "${title}", user #${loan.user_id}).`,
        now,
      );

      return loan;
    });

    returnInTx();
    return LoanModel.findById(loanId);
  }

  reconcileOverdue() {
    return LoanModel.reconcileOverdue();
  }

  overdueLoans() {
    this.reconcileOverdue();
    return LoanModel.search({ status: 'overdue', orderBy: 'l.due_date ASC' });
  }

  activeForUser(userId) {
    this.reconcileOverdue();
    return LoanModel.activeForUser(userId);
  }

  historyForUser(userId) {
    return LoanModel.historyForUser(userId);
  }

  activeForBook(bookId) {
    this.reconcileOverdue();
    return LoanModel.activeForBook(bookId);
  }

  loansBetween(from, to) {
    return LoanModel.loansBetween(from, to);
  }

  recent({ limit = 10 } = {}) {
    return LoanModel.recent({ limit });
  }

  countStatus(status) {
    return LoanModel.countStatus(status);
  }

  countTotal() {
    return LoanModel.countTotal();
  }
}

module.exports = new LoanService();
