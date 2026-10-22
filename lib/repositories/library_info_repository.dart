import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/library_info.dart';
import '../utils/constants.dart';

/// Repository for the landing page (About/Services/How It Works/Contact).
///
/// All About + Contact content lives in the `settings` table as key/value
/// pairs (see [AppConstants.keyLibraryMission] etc). Services + steps live
/// in their own `library_services` and `library_steps` tables so admins
/// can add/reorder/deactivate them via the editor screen.
class LibraryInfoRepository {
  final DatabaseHelper _db;
  LibraryInfoRepository(this._db);

  // ---------------- Services ----------------
  Future<List<LibraryService>> services({bool activeOnly = true}) async {
    final db = await _db.database;
    final where = activeOnly ? 'WHERE is_active = 1' : '';
    final rows = await db.rawQuery(
      'SELECT * FROM library_services $where ORDER BY display_order ASC, id ASC',
    );
    return rows.map(LibraryService.fromMap).toList();
  }

  Future<int> upsertService(LibraryService s) async {
    final db = await _db.database;
    if (s.id == null) {
      return db.insert('library_services', s.toMap());
    }
    await db.update('library_services', s.toMap(),
        where: 'id = ?', whereArgs: [s.id]);
    return s.id!;
  }

  Future<int> deleteService(int id) async {
    final db = await _db.database;
    return db.delete('library_services', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Steps ----------------
  Future<List<LibraryStep>> steps({bool activeOnly = true}) async {
    final db = await _db.database;
    final where = activeOnly ? 'WHERE is_active = 1' : '';
    final rows = await db.rawQuery(
      'SELECT * FROM library_steps $where ORDER BY display_order ASC, id ASC',
    );
    return rows.map(LibraryStep.fromMap).toList();
  }

  Future<int> upsertStep(LibraryStep s) async {
    final db = await _db.database;
    if (s.id == null) {
      return db.insert('library_steps', s.toMap());
    }
    await db.update('library_steps', s.toMap(),
        where: 'id = ?', whereArgs: [s.id]);
    return s.id!;
  }

  Future<int> deleteStep(int id) async {
    final db = await _db.database;
    return db.delete('library_steps', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Contact messages ----------------
  Future<int> submitContactMessage(ContactMessage m) async {
    final db = await _db.database;
    return db.insert('contact_messages', m.toMap());
  }

  Future<List<ContactMessage>> contactMessages({bool unhandledOnly = false}) async {
    final db = await _db.database;
    final where = unhandledOnly ? 'WHERE is_handled = 0' : '';
    final rows = await db.rawQuery(
      'SELECT * FROM contact_messages $where ORDER BY submitted_at DESC',
    );
    return rows.map(ContactMessage.fromMap).toList();
  }

  Future<int> markContactHandled(int id) async {
    final db = await _db.database;
    return db.update('contact_messages', {'is_handled': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteContactMessage(int id) async {
    final db = await _db.database;
    return db.delete('contact_messages', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Aggregated library info ----------------
  Future<LibraryContactInfo> fetchContactInfo() async {
    final db = await _db.database;
    final rows = await db.query('settings');
    final m = {for (final r in rows) r['setting_key'] as String: r['setting_value'] as String};
    return LibraryContactInfo(
      libraryName: m[AppConstants.keyLibraryName] ?? 'Injibara University Library',
      tagline: m[AppConstants.keyLibraryTagline] ?? 'Knowledge · Heritage · Discovery',
      mission: m[AppConstants.keyLibraryMission] ?? '',
      vision: m[AppConstants.keyLibraryVision] ?? '',
      history: m[AppConstants.keyLibraryHistory] ?? '',
      email: m[AppConstants.keyContactEmail] ?? '',
      phone: m[AppConstants.keyContactPhone] ?? '',
      address: m[AppConstants.keyContactAddress] ?? '',
      hours: m[AppConstants.keyContactHours] ?? '',
      facebook: m[AppConstants.keyContactFacebook],
      twitter: m[AppConstants.keyContactTwitter],
      instagram: m[AppConstants.keyContactInstagram],
    );
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _db.database;
    await db.insert('settings', {
      'setting_key': key,
      'setting_value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
