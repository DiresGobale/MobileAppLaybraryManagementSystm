const { getDb } = require('../db/connection');

const LoanModel = {
  create(l) {
    return getDb().prepare(
      `INSERT INTO loans (user_id, book_id, issued_by, issue_date, due_date, return_date, status)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
    ).run(
      l.user_id, l.book_id, l.issued_by, l.issue_date, l.due_date, l.return_date ?? null, l.status,
    ).lastInsertRowid;
  },

  update(id, fields) {
    const allowed = ['return_date', 'status'];
    const sets = [];
    const args = [];
    for (const [k, v] of Object.entries(fields)) {
      if (allowed.includes(k)) {
        sets.push(`${k} = ?`);
        args.push(v);
      }
    }
    if (sets.length === 0) return 0;
    args.push(id);
    return getDb().prepare(`UPDATE loans SET ${sets.join(', ')} WHERE id = ?`).run(...args).changes;
  },

  findById(id) {
    return getDb().prepare('SELECT * FROM loans WHERE id = ?').get(id);
  },

  search({ userId, bookId, status, orderBy = 'l.issue_date DESC' } = {}) {
    const where = [];
    const args = [];
    if (userId) {
      where.push('l.user_id = ?');
      args.push(userId);
    }
    if (bookId) {
      where.push('l.book_id = ?');
      args.push(bookId);
    }
    if (status) {
      where.push('l.status = ?');
      args.push(status);
    }
    const sql =
      `SELECT l.*, b.title AS book_title, b.isbn AS book_isbn, b.author AS book_author,
              u.full_name AS user_name, u.student_id AS user_student_id,
              lb.full_name AS librarian_name
         FROM loans l
         JOIN books b ON b.id = l.book_id
         JOIN users u ON u.id = l.user_id
         LEFT JOIN users lb ON lb.id = l.issued_by
         ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
         ORDER BY ${orderBy}`;
    return getDb().prepare(sql).all(...args);
  },

  recent({ limit = 10 } = {}) {
    return getDb().prepare(
      `SELECT l.*, b.title AS book_title, b.isbn AS book_isbn, b.author AS book_author,
              u.full_name AS user_name, u.student_id AS user_student_id,
              lb.full_name AS librarian_name
         FROM loans l
         JOIN books b ON b.id = l.book_id
         JOIN users u ON u.id = l.user_id
         LEFT JOIN users lb ON lb.id = l.issued_by
        ORDER BY l.issue_date DESC
        LIMIT ?`,
    ).all(limit);
  },

  activeForUser(userId) {
    return this.search({ userId, status: 'active', orderBy: 'l.due_date ASC' });
  },

  historyForUser(userId) {
    return this.search({ userId, orderBy: 'l.issue_date DESC' });
  },

  activeForBook(bookId) {
    return this.search({ bookId, status: 'active', orderBy: 'l.due_date ASC' });
  },

  countActiveForUser(userId) {
    return getDb().prepare(
      "SELECT COUNT(*) AS n FROM loans WHERE user_id = ? AND status IN ('active','overdue')",
    ).get(userId).n;
  },

  countStatus(status) {
    return getDb().prepare('SELECT COUNT(*) AS n FROM loans WHERE status = ?').get(status).n;
  },

  countTotal() {
    return getDb().prepare('SELECT COUNT(*) AS n FROM loans').get().n;
  },

  loansBetween(from, to) {
    return getDb().prepare(
      `SELECT l.*, b.title AS book_title, b.isbn AS book_isbn, b.author AS book_author,
              u.full_name AS user_name, u.student_id AS user_student_id,
              lb.full_name AS librarian_name
         FROM loans l
         JOIN books b ON b.id = l.book_id
         JOIN users u ON u.id = l.user_id
         LEFT JOIN users lb ON lb.id = l.issued_by
        WHERE l.issue_date >= ? AND l.issue_date <= ?
        ORDER BY l.issue_date DESC`,
    ).all(from, to);
  },

  /**
   * Marks active loans whose due_date has passed as 'overdue'.
   * Returns number of rows changed.
   */
  reconcileOverdue() {
    const now = Date.now();
    return getDb().prepare(
      "UPDATE loans SET status = 'overdue' WHERE status = 'active' AND due_date < ?",
    ).run(now).changes;
  },
};

module.exports = LoanModel;
