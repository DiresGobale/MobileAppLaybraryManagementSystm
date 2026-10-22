const { getDb } = require('../db/connection');

const CategoryModel = {
  all() {
    return getDb().prepare('SELECT * FROM categories ORDER BY name ASC').all();
  },

  findById(id) {
    return getDb().prepare('SELECT * FROM categories WHERE id = ?').get(id);
  },

  findByName(name) {
    return getDb().prepare('SELECT * FROM categories WHERE name = ?').get(name);
  },

  create({ name, description = null }) {
    return getDb().prepare('INSERT INTO categories (name, description) VALUES (?, ?)').run(name, description).lastInsertRowid;
  },

  update(id, { name, description }) {
    return getDb().prepare('UPDATE categories SET name = ?, description = ? WHERE id = ?').run(name, description, id).changes;
  },

  remove(id) {
    return getDb().prepare('DELETE FROM categories WHERE id = ?').run(id).changes;
  },

  countBooksInCategory(id) {
    return getDb().prepare('SELECT COUNT(*) AS n FROM books WHERE category_id = ?').get(id).n;
  },

  count() {
    return getDb().prepare('SELECT COUNT(*) AS n FROM categories').get().n;
  },
};

const BookModel = {
  create(b) {
    const db = getDb();
    const now = Date.now();
    const result = db.prepare(
      `INSERT INTO books
        (isbn, title, author, category_id, publisher, publication_year, edition,
         shelf_location, description, total_quantity, available_quantity, cover_path,
         created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).run(
      b.isbn, b.title, b.author, b.category_id ?? null, b.publisher ?? null,
      b.publication_year ?? null, b.edition ?? null, b.shelf_location ?? null,
      b.description ?? null, b.total_quantity, b.available_quantity, b.cover_path ?? null,
      now, now,
    );
    return result.lastInsertRowid;
  },

  update(id, fields) {
    const allowed = [
      'isbn','title','author','category_id','publisher','publication_year','edition',
      'shelf_location','description','total_quantity','available_quantity','cover_path',
    ];
    const sets = [];
    const args = [];
    for (const [k, v] of Object.entries(fields)) {
      // Skip undefined values entirely — only update fields the caller
      // explicitly provided.
      if (allowed.includes(k) && v !== undefined) {
        sets.push(`${k} = ?`);
        args.push(v);
      }
    }
    if (sets.length === 0) return 0;
    sets.push('updated_at = ?');
    args.push(Date.now());
    args.push(id);
    return getDb().prepare(`UPDATE books SET ${sets.join(', ')} WHERE id = ?`).run(...args).changes;
  },

  remove(id) {
    return getDb().prepare('DELETE FROM books WHERE id = ?').run(id).changes;
  },

  findById(id) {
    return getDb().prepare('SELECT * FROM books WHERE id = ?').get(id);
  },

  findByIdWithCategory(id) {
    return getDb().prepare(
      `SELECT b.*, c.name AS category_name
         FROM books b
         LEFT JOIN categories c ON c.id = b.category_id
        WHERE b.id = ?`,
    ).get(id);
  },

  findByIsbn(isbn) {
    return getDb().prepare('SELECT * FROM books WHERE isbn = ?').get(isbn);
  },

  search({ query = '', categoryId = null, availableOnly = false, orderBy = 'title ASC' } = {}) {
    const where = [];
    const args = [];
    if (query.trim()) {
      where.push('(b.title LIKE ? OR b.author LIKE ? OR b.isbn LIKE ? OR c.name LIKE ?)');
      const p = `%${query.trim()}%`;
      args.push(p, p, p, p);
    }
    if (categoryId) {
      where.push('b.category_id = ?');
      args.push(categoryId);
    }
    if (availableOnly) {
      where.push('b.available_quantity > 0');
    }
    const sql =
      `SELECT b.*, c.name AS category_name
         FROM books b
         LEFT JOIN categories c ON c.id = b.category_id
         ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
         ORDER BY ${orderBy}`;
    return getDb().prepare(sql).all(...args);
  },

  countTitles() {
    return getDb().prepare('SELECT COUNT(*) AS n FROM books').get().n;
  },

  sumTotalCopies() {
    return getDb().prepare('SELECT COALESCE(SUM(total_quantity),0) AS n FROM books').get().n;
  },

  sumAvailableCopies() {
    return getDb().prepare('SELECT COALESCE(SUM(available_quantity),0) AS n FROM books').get().n;
  },

  countOutOfStock() {
    return getDb().prepare('SELECT COUNT(*) AS n FROM books WHERE available_quantity = 0').get().n;
  },

  countActiveLoansForBook(bookId) {
    return getDb().prepare(
      "SELECT COUNT(*) AS n FROM loans WHERE book_id = ? AND status IN ('active','overdue')",
    ).get(bookId).n;
  },

  /**
   * Atomically decrements available_quantity for the book. Returns rows affected (0 if blocked).
   * MUST be called inside a transaction.
   */
  decrementAvailable(db, bookId) {
    const available = db.prepare('SELECT available_quantity FROM books WHERE id = ?').get(bookId).available_quantity;
    if (available <= 0) return 0;
    return db.update('books', { available_quantity: available - 1 },
      'id = ? AND available_quantity = ?', [bookId, available]).changes;
  },

  /**
   * Atomically increments available_quantity by 1 (capped at total_quantity).
   * MUST be called inside a transaction.
   */
  incrementAvailable(db, bookId) {
    const row = db.prepare('SELECT available_quantity, total_quantity FROM books WHERE id = ?').get(bookId);
    if (!row) return 0;
    if (row.available_quantity >= row.total_quantity) return 0;
    return db.update('books', { available_quantity: row.available_quantity + 1 },
      'id = ? AND available_quantity = ?', [bookId, row.available_quantity]).changes;
  },

  popularBooks({ limit = 10 } = {}) {
    return getDb().prepare(
      `SELECT b.*, COUNT(l.id) AS loan_count
         FROM books b
         JOIN loans l ON l.book_id = b.id
        GROUP BY b.id
        ORDER BY loan_count DESC, b.title ASC
        LIMIT ?`,
    ).all(limit);
  },
};

module.exports = { CategoryModel, BookModel };
