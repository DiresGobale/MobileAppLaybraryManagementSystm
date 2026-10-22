import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../utils/constants.dart';

/// Reusable SQLite helper with schema creation, versioning, migrations,
/// foreign-key enforcement, and transactional helpers.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  /// Allows tests to inject an in-memory database.
  void injectForTesting(Database db) {
    _db = db;
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('admin','librarian','student')),
        student_id TEXT,
        department TEXT,
        created_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    batch.execute('CREATE INDEX idx_users_role ON users(role)');
    batch.execute('CREATE INDEX idx_users_student_id ON users(student_id)');

    batch.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        isbn TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        category_id INTEGER,
        publisher TEXT,
        publication_year INTEGER,
        edition TEXT,
        shelf_location TEXT,
        description TEXT,
        total_quantity INTEGER NOT NULL CHECK (total_quantity >= 0),
        available_quantity INTEGER NOT NULL CHECK (available_quantity >= 0),
        cover_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON UPDATE CASCADE ON DELETE SET NULL,
        CHECK (available_quantity <= total_quantity)
      )
    ''');
    batch.execute('CREATE INDEX idx_books_title ON books(title)');
    batch.execute('CREATE INDEX idx_books_author ON books(author)');
    batch.execute('CREATE INDEX idx_books_category ON books(category_id)');

    batch.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        book_id INTEGER NOT NULL,
        issued_by INTEGER NOT NULL,
        issue_date INTEGER NOT NULL,
        due_date INTEGER NOT NULL,
        return_date INTEGER,
        status TEXT NOT NULL CHECK (status IN ('active','returned','overdue')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY (book_id) REFERENCES books(id) ON UPDATE CASCADE ON DELETE RESTRICT,
        FOREIGN KEY (issued_by) REFERENCES users(id) ON UPDATE CASCADE ON DELETE RESTRICT
      )
    ''');
    batch.execute('CREATE INDEX idx_loans_user ON loans(user_id)');
    batch.execute('CREATE INDEX idx_loans_book ON loans(book_id)');
    batch.execute('CREATE INDEX idx_loans_status ON loans(status)');

    batch.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_notifications_user ON notifications(user_id)');

    batch.execute('''
      CREATE TABLE activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        action TEXT NOT NULL,
        details TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_logs_user ON activity_logs(user_id)');
    batch.execute('CREATE INDEX idx_logs_created ON activity_logs(created_at)');

    batch.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setting_key TEXT NOT NULL UNIQUE,
        setting_value TEXT NOT NULL
      )
    ''');

    // Library services catalog (for the landing page Services section)
    batch.execute('''
      CREATE TABLE library_services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_name TEXT NOT NULL DEFAULT 'menu_book',
        display_order INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    batch.execute('CREATE INDEX idx_services_order ON library_services(display_order)');

    // How-It-Works workflow steps (for the landing page How It Works section)
    batch.execute('''
      CREATE TABLE library_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        step_number INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_name TEXT NOT NULL DEFAULT 'search',
        display_order INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    batch.execute('CREATE INDEX idx_steps_order ON library_steps(display_order)');

    // Contact messages submitted by visitors via the Contact section
    batch.execute('''
      CREATE TABLE contact_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        subject TEXT NOT NULL,
        message TEXT NOT NULL,
        submitted_at INTEGER NOT NULL,
        is_handled INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute('CREATE INDEX idx_contact_submitted ON contact_messages(submitted_at)');

    await batch.commit(noResult: true);

    // Seed default categories
    await _seedCategories(db);
    // Seed default settings
    await _seedSettings(db);
    // Seed default library services + steps for the landing page
    await _seedLibraryServices(db);
    await _seedLibrarySteps(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here as cascaded `if` blocks.
    // No migrations required yet (dbVersion == 1).
  }

  Future<void> _seedCategories(Database db) async {
    final categories = [
      ('Computer Science', 'Programming, algorithms, software engineering, AI'),
      ('Engineering', 'Civil, mechanical, electrical, chemical engineering'),
      ('Business', 'Management, accounting, economics, marketing'),
      ('Medicine', 'Medicine, nursing, public health, pharmacy'),
      ('Humanities', 'History, philosophy, literature, languages'),
      ('Natural Sciences', 'Mathematics, physics, chemistry, biology'),
      ('Education', 'Pedagogy, curriculum, educational psychology'),
      ('Law', 'Constitutional, criminal, civil, international law'),
      ('Agriculture', 'Agronomy, animal science, food security'),
      ('Reference', 'Dictionaries, encyclopedias, atlases'),
    ];
    final batch = db.batch();
    for (final c in categories) {
      batch.insert('categories', {
        'name': c.$1,
        'description': c.$2,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedSettings(Database db) async {
    final batch = db.batch();
    AppConstants.defaultSettings.forEach((k, v) {
      batch.insert('settings', {
        'setting_key': k,
        'setting_value': v,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });
    await batch.commit(noResult: true);
  }

  Future<void> _seedLibraryServices(Database db) async {
    final services = <Map<String, dynamic>>[
      {
        'title': 'Book Borrowing',
        'description':
            'Borrow up to 3 books for 14 days with your student ID. Renewals '
            'available at the circulation desk.',
        'icon_name': 'menu_book',
        'display_order': 1,
      },
      {
        'title': 'Quiet Study Spaces',
        'description':
            '240 silent-study seats across three reading halls, plus 6 '
            'group-study rooms available by reservation.',
        'icon_name': 'self_improvement',
        'display_order': 2,
      },
      {
        'title': 'Research Assistance',
        'description':
            'Subject-specialist librarians offer one-on-one research '
            'consultations, citation help, and literature-review coaching.',
        'icon_name': 'psychology',
        'display_order': 3,
      },
      {
        'title': 'Inter-Library Loan',
        'description':
            'Request books and articles from partner universities across '
            'Ethiopia and the East African research consortium.',
        'icon_name': 'local_shipping',
        'display_order': 4,
      },
      {
        'title': 'Digital Resources',
        'description':
            'On-campus access to JSTOR, IEEE Xplore, HINARI, and over 40 '
            'subscribed e-journals and e-book collections.',
        'icon_name': 'devices',
        'display_order': 5,
      },
      {
        'title': 'Reference & Citation Help',
        'description':
            'Drop-in help with APA, MLA, Chicago, and IEEE citation styles. '
            'Reference management software tutorials weekly.',
        'icon_name': 'school',
        'display_order': 6,
      },
      {
        'title': 'Printing & Scanning',
        'description':
            'Black-and-white and color printing, photocopying, and document '
            'scanning at subsidized student rates.',
        'icon_name': 'print',
        'display_order': 7,
      },
      {
        'title': 'Wi-Fi & Power',
        'description':
            'Campus-wide Eduroam Wi-Fi and power outlets at every study seat '
            'for laptops and personal devices.',
        'icon_name': 'wifi',
        'display_order': 8,
      },
    ];
    final batch = db.batch();
    for (final s in services) {
      batch.insert('library_services', s, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedLibrarySteps(Database db) async {
    final steps = <Map<String, dynamic>>[
      {
        'step_number': 1,
        'title': 'Browse the Catalog',
        'description':
            'Search by title, author, ISBN, or category. Filter to see only '
            'books currently on the shelves.',
        'icon_name': 'search',
        'display_order': 1,
      },
      {
        'step_number': 2,
        'title': 'Find Your Book',
        'description':
            'Note the shelf location code (e.g. A-12) from the book detail '
            'page and locate the shelf in the reading hall.',
        'icon_name': 'menu_book',
        'display_order': 2,
      },
      {
        'step_number': 3,
        'title': 'Borrow at the Counter',
        'description':
            'Bring the book and your student ID to the circulation desk. The '
            'librarian issues the loan and stamps your due-date slip.',
        'icon_name': 'local_library',
        'display_order': 3,
      },
      {
        'step_number': 4,
        'title': 'Return on Time',
        'description':
            'Return the book on or before the due date. Overdue loans block '
            'further borrowing until resolved.',
        'icon_name': 'assignment_return',
        'display_order': 4,
      },
    ];
    final batch = db.batch();
    for (final s in steps) {
      batch.insert('library_steps', s, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  /// Convenience: runs a function inside a transaction.
  Future<T> inTransaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  /// Drops and recreates the database (used by tests only).
  Future<void> resetForTests() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('DELETE FROM activity_logs');
      await txn.execute('DELETE FROM notifications');
      await txn.execute('DELETE FROM loans');
      await txn.execute('DELETE FROM books');
      await txn.execute('DELETE FROM users');
      await txn.execute('DELETE FROM settings');
      await txn.execute('DELETE FROM categories');
      await txn.execute('DELETE FROM library_services');
      await txn.execute('DELETE FROM library_steps');
      await txn.execute('DELETE FROM contact_messages');
      await txn.execute(
          "DELETE FROM sqlite_sequence WHERE name IN ('users','books','categories','loans','notifications','activity_logs','settings','library_services','library_steps','contact_messages')");
    });
    await _seedCategories(db);
    await _seedSettings(db);
    await _seedLibraryServices(db);
    await _seedLibrarySteps(db);
  }

  /// Returns true if at least one user exists.
  Future<bool> get hasAnyUser async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM users');
    final n = Sqflite.firstIntValue(rows) ?? 0;
    return n > 0;
  }
}
