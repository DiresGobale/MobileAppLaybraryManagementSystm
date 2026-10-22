import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/book.dart';
import '../models/category.dart';

class BookRepository {
  final DatabaseHelper _db;
  BookRepository(this._db);

  /// Exposed for services that need raw queries (e.g. popularity aggregation).
  Future<Database> get rawDb async => _db.database;

  Future<int> countCategories() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM categories');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> create(Book book) async {
    final db = await _db.database;
    return db.insert('books', book.toMap());
  }

  Future<int> update(Book book) async {
    final db = await _db.database;
    return db.update('books', book.toMap(), where: 'id = ?', whereArgs: [book.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<Book?> findById(int id) async {
    final db = await _db.database;
    final rows = await db.query('books', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Book.fromMap(rows.first);
  }

  Future<Book?> findByIsbn(String isbn) async {
    final db = await _db.database;
    final rows = await db.query('books', where: 'isbn = ?', whereArgs: [isbn], limit: 1);
    if (rows.isEmpty) return null;
    return Book.fromMap(rows.first);
  }

  Future<List<BookWithCategory>> search({
    String query = '',
    int? categoryId,
    bool availableOnly = false,
    String orderBy = 'title ASC',
  }) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (query.trim().isNotEmpty) {
      where.add('(b.title LIKE ? OR b.author LIKE ? OR b.isbn LIKE ? OR c.name LIKE ?)');
      final p = '%${query.trim()}%';
      args.addAll([p, p, p, p]);
    }
    if (categoryId != null) {
      where.add('b.category_id = ?');
      args.add(categoryId);
    }
    if (availableOnly) {
      where.add('b.available_quantity > 0');
    }

    final sql = '''
      SELECT b.*, c.name AS category_name
      FROM books b
      LEFT JOIN categories c ON c.id = b.category_id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY $orderBy
    ''';

    final rows = await db.rawQuery(sql, args);
    return rows.map(BookWithCategory.fromMap).toList();
  }

  Future<List<Book>> all() async {
    final db = await _db.database;
    final rows = await db.query('books', orderBy: 'title ASC');
    return rows.map(Book.fromMap).toList();
  }

  Future<int> countTitles() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM books');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> sumTotalCopies() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT COALESCE(SUM(total_quantity),0) AS n FROM books');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> sumAvailableCopies() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT COALESCE(SUM(available_quantity),0) AS n FROM books');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> sumBorrowedCopies() async {
    final db = await _db.database;
    final rows =
        await db.rawQuery('SELECT COALESCE(SUM(total_quantity - available_quantity),0) AS n FROM books');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countOutOfStock() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM books WHERE available_quantity = 0');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countActiveLoansForBook(int bookId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS n FROM loans WHERE book_id = ? AND status IN ('active','overdue')",
      [bookId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Atomically decrements available_quantity by 1 for the book. Returns rows affected (0 if blocked).
  Future<int> decrementAvailable(int bookId, Transaction txn) async {
    final rows = await txn.rawQuery(
      'SELECT available_quantity FROM books WHERE id = ?',
      [bookId],
    );
    final available = Sqflite.firstIntValue(rows) ?? 0;
    if (available <= 0) return 0;
    return txn.update('books', {'available_quantity': available - 1},
        where: 'id = ? AND available_quantity = ?', whereArgs: [bookId, available]);
  }

  /// Atomically increments available_quantity by 1 (capped at total_quantity).
  Future<int> incrementAvailable(int bookId, Transaction txn) async {
    final rows = await txn.rawQuery(
      'SELECT available_quantity, total_quantity FROM books WHERE id = ?',
      [bookId],
    );
    if (rows.isEmpty) return 0;
    final available = rows.first['available_quantity'] as int;
    final total = rows.first['total_quantity'] as int;
    if (available >= total) return 0;
    return txn.update('books', {'available_quantity': available + 1},
        where: 'id = ? AND available_quantity = ?', whereArgs: [bookId, available]);
  }
}

class CategoryRepository {
  final DatabaseHelper _db;
  CategoryRepository(this._db);

  Future<int> create(Category category) async {
    final db = await _db.database;
    return db.insert('categories', category.toMap());
  }

  Future<int> update(Category category) async {
    final db = await _db.database;
    return db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<Category?> findById(int id) async {
    final db = await _db.database;
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<Category?> findByName(String name) async {
    final db = await _db.database;
    final rows = await db.query('categories', where: 'name = ?', whereArgs: [name], limit: 1);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<List<Category>> all() async {
    final db = await _db.database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> count() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM categories');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countBooksInCategory(int categoryId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM books WHERE category_id = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
