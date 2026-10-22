import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:iulms/database/database_helper.dart';
import 'package:iulms/models/user.dart';
import 'package:iulms/providers/auth_provider.dart';
import 'package:iulms/repositories/activity_log_repository.dart';
import 'package:iulms/repositories/book_repository.dart';
import 'package:iulms/repositories/category_repository.dart';
import 'package:iulms/repositories/loan_repository.dart';
import 'package:iulms/repositories/notification_repository.dart';
import 'package:iulms/repositories/settings_repository.dart';
import 'package:iulms/repositories/user_repository.dart';
import 'package:iulms/routes/app_routes.dart';
import 'package:iulms/screens/login_screen.dart';
import 'package:iulms/services/auth_service.dart';
import 'package:iulms/services/book_service.dart';
import 'package:iulms/services/loan_service.dart';
import 'package:iulms/services/notification_service.dart';
import 'package:iulms/services/report_service.dart';
import 'package:iulms/utils/constants.dart';
import 'package:iulms/utils/hash_utils.dart';
import 'package:iulms/models/book.dart';
import 'package:iulms/models/loan.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AuthService authService;
  late User student;
  late Book book;
  late LoanProvider loanProvider;
  late BookService bookService;

  setUp(() async {
    final helper = DatabaseHelper.instance;
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, v) async {
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
        batch.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            setting_key TEXT NOT NULL UNIQUE,
            setting_value TEXT NOT NULL
          )
        ''');
        await batch.commit(noResult: true);
      },
    );
    helper.injectForTesting(db);

    final users = UserRepository(helper);
    final books = BookRepository(helper);
    final categories = CategoryRepository(helper);
    final loans = LoanRepository(helper);
    final notifs = NotificationRepository(helper);
    final logs = ActivityLogRepository(helper);
    final settings = SettingsRepository(helper);

    authService = AuthService(users, logs, settings);
    bookService = BookService(books, categories, logs);
    final loanService = LoanService(loans, books, notifs, logs, settings);
    loanProvider = LoanProvider(loanService);

    // Create a student.
    student = await authService.createUserByAdmin(
      fullName: 'Test Student',
      username: 'teststud',
      email: 'teststud@injibara.edu',
      password: 'password123',
      role: Role.student,
      studentId: 'LIB/TEST/001',
      department: 'CS',
      createdBy: 0,
    );
    // Create a librarian (for issue action).
    final librarian = await authService.createUserByAdmin(
      fullName: 'Test Librarian',
      username: 'testlib',
      email: 'testlib@injibara.edu',
      password: 'password123',
      role: Role.librarian,
      createdBy: 0,
    );
    // Create a book.
    final now = DateTime.now();
    final id = await bookService.createBook(
      Book(
        isbn: '978-WIDGET-TEST',
        title: 'Widget Testing for Flutter',
        author: 'Anonymous Tester',
        totalQuantity: 3,
        availableQuantity: 3,
        createdAt: now,
        updatedAt: now,
      ),
      actorId: librarian.id,
    );
    book = (await bookService.getBook(id))!;
  });

  testWidgets('LoginScreen shows error for non-existent account',
      (tester) async {
    final authProvider = AuthProvider(authService);
    await authProvider.bootstrap();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Type in an unknown user.
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'nobody@injibara.edu',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'doesnotmatter',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No account'), findsOneWidget);
  });

  testWidgets('LoginScreen accepts a valid student', (tester) async {
    final authProvider = AuthProvider(authService);
    await authProvider.bootstrap();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'teststud',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'password123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    // Should not show "No account" error.
    expect(find.textContaining('No account'), findsNothing);
    expect(authProvider.isLoggedIn, isTrue);
  });

  test('Book issue decrements available_quantity', () async {
    final librarian = await authService.listUsers().then((u) => u.firstWhere((x) => x.role == Role.librarian));
    await loanProvider.issue(
      userId: student.id!,
      bookId: book.id!,
      librarianId: librarian.id!,
    );
    final updated = await bookService.getBook(book.id!);
    expect(updated!.availableQuantity, equals(2));
  });

  test('Returning a loan restores available_quantity', () async {
    final librarian = await authService.listUsers().then((u) => u.firstWhere((x) => x.role == Role.librarian));
    final loan = await loanProvider.issue(
      userId: student.id!,
      bookId: book.id!,
      librarianId: librarian.id!,
    );
    expect(loan, isNotNull);
    await loanProvider.returnLoan(
      loanId: loan!.id!,
      librarianId: librarian.id!,
    );
    final updated = await bookService.getBook(book.id!);
    expect(updated!.availableQuantity, equals(3));
  });
}
