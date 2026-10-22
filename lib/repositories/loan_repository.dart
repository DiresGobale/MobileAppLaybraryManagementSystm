import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/loan.dart';

class LoanRepository {
  final DatabaseHelper _db;
  LoanRepository(this._db);

  Future<int> create(Loan loan) async {
    final db = await _db.database;
    return db.insert('loans', loan.toMap());
  }

  Future<int> update(Loan loan) async {
    final db = await _db.database;
    return db.update('loans', loan.toMap(), where: 'id = ?', whereArgs: [loan.id]);
  }

  Future<Loan?> findById(int id) async {
    final db = await _db.database;
    final rows = await db.query('loans', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Loan.fromMap(rows.first);
  }

  Future<List<LoanDetail>> searchLoans({
    int? userId,
    int? bookId,
    String? status,
    String orderBy = 'l.issue_date DESC',
  }) async {
    final db = await _db.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (userId != null) {
      where.add('l.user_id = ?');
      args.add(userId);
    }
    if (bookId != null) {
      where.add('l.book_id = ?');
      args.add(bookId);
    }
    if (status != null) {
      where.add('l.status = ?');
      args.add(status);
    }

    final sql = '''
      SELECT
        l.*,
        b.title AS book_title,
        b.isbn AS book_isbn,
        b.author AS book_author,
        u.full_name AS user_name,
        u.student_id AS user_student_id,
        lb.full_name AS librarian_name
      FROM loans l
        JOIN books b ON b.id = l.book_id
                JOIN users u ON u.id = l.user_id
        LEFT JOIN users lb ON lb.id = l.issued_by
        ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY $orderBy
    ''';
    final rows = await db.rawQuery(sql, args);
    return rows.map(LoanDetail.fromMap).toList();
  }

  Future<List<LoanDetail>> recentLoans({int limit = 10}) async {
    final db = await _db.database;
    final sql = '''
      SELECT
        l.*,
        b.title AS book_title,
        b.isbn AS book_isbn,
        b.author AS book_author,
        u.full_name AS user_name,
        u.student_id AS user_student_id,
        lb.full_name AS librarian_name
      FROM loans l
        JOIN books b ON b.id = l.book_id
        JOIN users u ON u.id = l.user_id
        LEFT JOIN users lb ON lb.id = l.issued_by
      ORDER BY l.issue_date DESC
      LIMIT ?
    ''';
    final rows = await db.rawQuery(sql, [limit]);
    return rows.map(LoanDetail.fromMap).toList();
  }

  Future<int> countActiveForUser(int userId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS n FROM loans WHERE user_id = ? AND status IN ('active','overdue')",
      [userId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countStatus(String status) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM loans WHERE status = ?',
      [status],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countTotal() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM loans');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Marks active loans with past due_date as 'overdue' atomically.
  /// Returns the number of loans transitioned.
  Future<int> reconcileOverdue(Transaction txn) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return txn.update(
      'loans',
      {'status': 'overdue'},
      where: "status = 'active' AND due_date < ?",
      whereArgs: [now],
    );
  }

  Future<List<LoanDetail>> overdueLoans() async {
    return searchLoans(status: 'overdue', orderBy: 'l.due_date ASC');
  }

  Future<List<LoanDetail>> activeForUser(int userId) async {
    return searchLoans(userId: userId, status: 'active', orderBy: 'l.due_date ASC');
  }

  Future<List<LoanDetail>> historyForUser(int userId) async {
    return searchLoans(userId: userId, orderBy: 'l.issue_date DESC');
  }

  Future<List<LoanDetail>> activeForBook(int bookId) async {
    return searchLoans(bookId: bookId, status: 'active', orderBy: 'l.due_date ASC');
  }

  Future<List<LoanDetail>> loansBetween(DateTime from, DateTime to) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        l.*,
        b.title AS book_title,
        b.isbn AS book_isbn,
        b.author AS book_author,
        u.full_name AS user_name,
        u.student_id AS user_student_id,
        lb.full_name AS librarian_name
      FROM loans l
        JOIN books b ON b.id = l.book_id
        JOIN users u ON u.id = l.user_id
        LEFT JOIN users lb ON lb.id = l.issued_by
      WHERE l.issue_date >= ? AND l.issue_date <= ?
      ORDER BY l.issue_date DESC
      ''',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return rows.map(LoanDetail.fromMap).toList();
  }
}

class NotificationRepository {
  final DatabaseHelper _db;
  NotificationRepository(this._db);

  Future<int> create(AppNotification n) async {
    final db = await _db.database;
    return db.insert('notifications', n.toMap());
  }

  Future<List<AppNotification>> forUser(int userId, {bool unreadOnly = false}) async {
    final db = await _db.database;
    final where = unreadOnly ? 'user_id = ? AND is_read = 0' : 'user_id = ?';
    final rows = await db.query(
      'notifications',
      where: where,
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<int> markRead(int id) async {
    final db = await _db.database;
    return db.update('notifications', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> markAllRead(int userId) async {
    final db = await _db.database;
    return db.update('notifications', {'is_read': 1},
        where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<int> countUnread(int userId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }
}

class ActivityLogRepository {
  final DatabaseHelper _db;
  ActivityLogRepository(this._db);

  Future<int> create(ActivityLog log) async {
    final db = await _db.database;
    return db.insert('activity_logs', log.toMap());
  }

  Future<List<ActivityLog>> recent({int limit = 20}) async {
    final db = await _db.database;
    final rows = await db.query('activity_logs', orderBy: 'created_at DESC', limit: limit);
    return rows.map(ActivityLog.fromMap).toList();
  }

  /// Returns all activity logs joined with the actor's full_name so the
  /// Activity Log screen can show "who did what" without a second query.
  Future<List<Map<String, dynamic>>> recentWithUser({int limit = 200, int? actorId}) async {
    final db = await _db.database;
    final where = actorId == null ? '' : 'WHERE l.user_id = ?';
    final args = actorId == null ? <dynamic>[] : [actorId];
    final rows = await db.rawQuery('''
      SELECT l.*, u.full_name AS actor_name, u.username AS actor_username, u.role AS actor_role
      FROM activity_logs l
        LEFT JOIN users u ON u.id = l.user_id
      $where
      ORDER BY l.created_at DESC
      LIMIT ?
    ''', [...args, limit]);
    return rows;
  }

  /// Count today's actions — used in admin dashboard KPIs.
  Future<int> countToday() async {
    final db = await _db.database;
    final startOfDay = DateTime.now();
    final midnight = DateTime(startOfDay.year, startOfDay.month, startOfDay.day).millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM activity_logs WHERE created_at >= ?',
      [midnight],
    );
    return rows.isNotEmpty ? (rows.first['n'] as int? ?? 0) : 0;
  }
}

class SettingsRepository {
  final DatabaseHelper _db;
  SettingsRepository(this._db);

  Future<String?> get(String key) async {
    final db = await _db.database;
    final rows = await db.query('settings',
        where: 'setting_key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['setting_value'] as String;
  }

  Future<void> set(String key, String value) async {
    final db = await _db.database;
    await db.insert('settings', {
      'setting_key': key,
      'setting_value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String>> all() async {
    final db = await _db.database;
    final rows = await db.query('settings');
    return {
      for (final r in rows) r['setting_key'] as String: r['setting_value'] as String,
    };
  }

  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final v = await get(key);
    return int.tryParse(v ?? '') ?? defaultValue;
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final v = await get(key);
    if (v == null) return defaultValue;
    return v == 'true' || v == '1';
  }
}
