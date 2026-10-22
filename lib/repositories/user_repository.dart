import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/user.dart';

class UserRepository {
  final DatabaseHelper _db;
  UserRepository(this._db);

  Future<User?> findById(int id) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<User?> findByUsername(String username) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'username = ? COLLATE NOCASE',
      whereArgs: [username],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<User?> findByEmail(String email) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'email = ? COLLATE NOCASE',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<User?> findByStudentId(String studentId) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'student_id = ? COLLATE NOCASE',
      whereArgs: [studentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<int> create(User user) async {
    final db = await _db.database;
    return db.insert('users', user.toMap());
  }

  Future<int> update(User user) async {
    final db = await _db.database;
    return db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deactivate(int userId) async {
    final db = await _db.database;
    return db.update('users', {'is_active': 0}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<int> reactivate(int userId) async {
    final db = await _db.database;
    return db.update('users', {'is_active': 1}, where: 'id = ?', whereArgs: [userId]);
  }

  /// Hard delete of a user — only allowed by admins when the user has no
  /// active loans. Activity logs referencing this user keep their user_id
  /// but the JOIN returns NULL (handled by ON DELETE SET NULL on activity_logs;
  /// loans have ON DELETE RESTRICT so this throws if loans exist).
  Future<int> delete(int userId) async {
    final db = await _db.database;
    return db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<List<User>> all({String? roleFilter}) async {
    final db = await _db.database;
    if (roleFilter != null) {
      return (await db.query('users', where: 'role = ?', whereArgs: [roleFilter]))
          .map(User.fromMap)
          .toList();
    }
    return (await db.query('users', orderBy: 'created_at DESC')).map(User.fromMap).toList();
  }

  Future<int> countStudents() async {
    final db = await _db.database;
    final rows = await db.rawQuery("SELECT COUNT(*) AS n FROM users WHERE role = 'student'");
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countByRole(String role) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM users WHERE role = ? AND is_active = 1',
      [role],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> countAll() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM users');
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
