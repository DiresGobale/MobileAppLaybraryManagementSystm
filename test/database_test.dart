import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import 'package:iulms/database/database_helper.dart';
import 'package:iulms/repositories/book_repository.dart';
import 'package:iulms/repositories/category_repository.dart';
import 'package:iulms/repositories/loan_repository.dart';
import 'package:iulms/repositories/notification_repository.dart';
import 'package:iulms/repositories/activity_log_repository.dart';
import 'package:iulms/repositories/settings_repository.dart';
import 'package:iulms/repositories/user_repository.dart';
import 'package:iulms/services/auth_service.dart';
import 'package:iulms/services/book_service.dart';
import 'package:iulms/services/loan_service.dart';
import 'package:iulms/utils/constants.dart';
import 'package:iulms/models/book.dart';
import 'package:iulms/models/user.dart';
import 'package:iulms/utils/hash_utils.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper helper;
  late UserRepository users;
  late BookRepository books;
  late CategoryRepository categories;
  late LoanRepository loans;
  late NotificationRepository notifs;
  late ActivityLogRepository logs;
  late SettingsRepository settings;

  setUp(() async {
    helper = DatabaseHelper.instance;
    // Use an in-memory database for tests.
    final db = await openDatabase(
      // Use the same path as production so the same schema works.
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
        // Seed default settings.
        AppConstants.defaultSettings.forEach((k, v) async {
          await db.insert('settings',
              {'setting_key': k, 'setting_value': v},
              conflictAlgorithm: ConflictAlgorithm.replace);
        });
      },
    );
    helper.injectForTesting(db);

    users = UserRepository(helper);
    books = BookRepository(helper);
    categories = CategoryRepository(helper);
    loans = LoanRepository(helper);
    notifs = NotificationRepository(helper);
    logs = ActivityLogRepository(helper);
    settings = SettingsRepository(helper);
  });

  group('HashUtils', () {
    test('hash is deterministic with salt', () {
      final salt = HashUtils.generateSalt();
      final a = HashUtils.hashPassword('hello', salt);
      final b = HashUtils.hashPassword('hello', salt);
      expect(a, equals(b));
      expect(a.length, 64);
    });

    test('different salts produce different hashes', () {
      expect(HashUtils.hashPassword('hello', 'saltA') !=
          HashUtils.hashPassword('hello', 'saltB'), isTrue);
    });

    test('verifyPassword matches', () {
      final salt = HashUtils.generateSalt();
      final hash = HashUtils.hashPassword('p@ssword', salt);
      expect(HashUtils.verifyPassword('p@ssword', salt, hash), isTrue);
      expect(HashUtils.verifyPassword('wrong', salt, hash), isFalse);
    });
  });

  group('AuthService', () {
    test('creates and logs in user', () async {
      final auth = AuthService(users, logs, settings);
      final u = await auth.createUserByAdmin(
        fullName: 'Selam Bekele',
        username: 'selam',
        email: 'selam@injibara.edu',
        password: 'secret',
        role: Role.student,
        studentId: 'LIB/2025/001',
        department: 'Computer Science',
        createdBy: 0,
      );
      expect(u.id, greaterThan(0));
      final loggedIn = await auth.login('selam', 'secret');
      expect(loggedIn, isNotNull);
      expect(loggedIn!.id, equals(u.id));
    });

    test('rejects duplicate username', () async {
      final auth = AuthService(users, logs, settings);
      await auth.createUserByAdmin(
        fullName: 'Almaz',
        username: 'almaz',
        email: 'almaz@injibara.edu',
        password: 'secret',
        role: Role.student,
        studentId: 'LIB/2025/002',
        department: 'Biology',
        createdBy: 0,
      );
      expect(
        () => auth.createUserByAdmin(
          fullName: 'Other Almaz',
          username: 'almaz',
          email: 'almaz2@injibara.edu',
          password: 'secret',
          role: Role.student,
          studentId: 'LIB/2025/003',
          department: 'Biology',
          createdBy: 0,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('login with wrong password fails', () async {
      final auth = AuthService(users, logs, settings);
      await auth.createUserByAdmin(
        fullName: 'Dawit',
        username: 'dawit',
        email: 'dawit@injibara.edu',
        password: 'correctpw',
        role: Role.librarian,
        createdBy: 0,
      );
      expect(() => auth.login('dawit', 'wrong'), throwsA(isA<AuthException>()));
    });
  });

  group('BookService', () {
    late BookService bookService;
    late AuthService authService;
    late User librarian;
    late User student;

    setUp(() async {
      authService = AuthService(users, logs, settings);
      bookService = BookService(books, categories, logs);
      librarian = await authService.createUserByAdmin(
        fullName: 'Librarian',
        username: 'lib1',
        email: 'lib1@injibara.edu',
        password: 'secret',
        role: Role.librarian,
        createdBy: 0,
      );
      student = await authService.createUserByAdmin(
        fullName: 'Student One',
        username: 'stud1',
        email: 'stud1@injibara.edu',
        password: 'secret',
        role: Role.student,
        studentId: 'LIB/2025/100',
        department: 'CS',
        createdBy: 0,
      );
    });

    test('creates and retrieves a book', () async {
      final now = DateTime.now();
      final b = Book(
        isbn: '978-1-2345-6789-0',
        title: 'Introduction to Algorithms',
        author: 'Cormen, Leiserson, Rivest, Stein',
        totalQuantity: 5,
        availableQuantity: 5,
        createdAt: now,
        updatedAt: now,
      );
      final id = await bookService.createBook(b, actorId: librarian.id);
      expect(id, greaterThan(0));
      final found = await bookService.findByIsbn('978-1-2345-6789-0');
      expect(found?.title, equals('Introduction to Algorithms'));
    });

    test('rejects duplicate ISBN', () async {
      final now = DateTime.now();
      final b = Book(
        isbn: '978-DUP',
        title: 'A',
        author: 'X',
        totalQuantity: 1,
        availableQuantity: 1,
        createdAt: now,
        updatedAt: now,
      );
      await bookService.createBook(b, actorId: librarian.id);
      expect(
        () => bookService.createBook(b.copyWith(), actorId: librarian.id),
        throwsA(isA<BookException>()),
      );
    });

    test('prevents deletion when book has active loans', () async {
      final now = DateTime.now();
      final b = Book(
        isbn: '978-LOAN',
        title: 'B',
        author: 'Y',
        totalQuantity: 1,
        availableQuantity: 1,
        createdAt: now,
        updatedAt: now,
      );
      final id = await bookService.createBook(b, actorId: librarian.id);

      final loanService = LoanService(loans, books, notifs, logs, settings);
      await loanService.issue(
        userId: student.id!,
        bookId: id,
        librarianId: librarian.id!,
      );

      expect(
        () => bookService.deleteBook(id, actorId: librarian.id),
        throwsA(isA<BookException>()),
      );
    });
  });

  group('LoanService', () {
    late BookService bookService;
    late LoanService loanService;
    late User librarian;
    late User student;
    late Book book;

    setUp(() async {
      final authService = AuthService(users, logs, settings);
      bookService = BookService(books, categories, logs);
      loanService = LoanService(loans, books, notifs, logs, settings);
      librarian = await authService.createUserByAdmin(
        fullName: 'Librarian',
        username: 'lib_loan',
        email: 'libloan@injibara.edu',
        password: 'secret',
        role: Role.librarian,
        createdBy: 0,
      );
      student = await authService.createUserByAdmin(
        fullName: 'Student Two',
        username: 'stud_loan',
        email: 'studloan@injibara.edu',
        password: 'secret',
        role: Role.student,
        studentId: 'LIB/2025/200',
        department: 'CS',
        createdBy: 0,
      );
      final now = DateTime.now();
      final bookId = await bookService.createBook(
        Book(
          isbn: '978-LOANSVC',
          title: 'Loan Service Test',
          author: 'Tester',
          totalQuantity: 2,
          availableQuantity: 2,
          createdAt: now,
          updatedAt: now,
        ),
        actorId: librarian.id,
      );
      book = (await bookService.getBook(bookId))!;
    });

    test('issue decrements available_quantity atomically', () async {
      await loanService.issue(
        userId: student.id!,
        bookId: book.id!,
        librarianId: librarian.id!,
      );
      final updated = await bookService.getBook(book.id!);
      expect(updated!.availableQuantity, equals(1));
    });

    test('return increments available_quantity and sets status', () async {
      final loan = await loanService.issue(
        userId: student.id!,
        bookId: book.id!,
        librarianId: librarian.id!,
      );
      final returned = await loanService.returnLoan(
        loanId: loan.id!,
        librarianId: librarian.id!,
      );
      expect(returned.status, equals(AppConstants.statusReturned));
      final updated = await bookService.getBook(book.id!);
      expect(updated!.availableQuantity, equals(2));
    });

    test('cannot return same loan twice', () async {
      final loan = await loanService.issue(
        userId: student.id!,
        bookId: book.id!,
        librarianId: librarian.id!,
      );
      await loanService.returnLoan(
        loanId: loan.id!,
        librarianId: librarian.id!,
      );
      expect(
        () => loanService.returnLoan(
          loanId: loan.id!,
          librarianId: librarian.id!,
        ),
        throwsA(isA<LoanException>()),
      );
    });

    test('cannot issue when out of stock', () async {
      // Issue all 2 copies to the same student (would hit borrowing limit)
      // Instead, make a second student and split the copies.
      final authService = AuthService(users, logs, settings);
      final student2 = await authService.createUserByAdmin(
        fullName: 'Student Three',
        username: 'stud_loan_3',
        email: 'studloan3@injibara.edu',
        password: 'secret',
        role: Role.student,
        studentId: 'LIB/2025/300',
        department: 'CS',
        createdBy: 0,
      );
      await loanService.issue(
        userId: student.id!,
        bookId: book.id!,
        librarianId: librarian.id!,
      );
      await loanService.issue(
        userId: student2.id!,
        bookId: book.id!,
        librarianId: librarian.id!,
      );
      // Now the book is out of stock.
      expect(
        () => loanService.issue(
          userId: student2.id!,
          bookId: book.id!,
          librarianId: librarian.id!,
        ),
        throwsA(isA<LoanException>()),
      );
    });

    test('borrowing limit enforced per student', () async {
      // Default max is 3 — create 3 distinct books.
      final now = DateTime.now();
      for (var i = 1; i <= 3; i++) {
        await bookService.createBook(
          Book(
            isbn: '978-LIM-$i',
            title: 'Limit $i',
            author: 'Author $i',
            totalQuantity: 1,
            availableQuantity: 1,
            createdAt: now,
            updatedAt: now,
          ),
          actorId: librarian.id,
        );
      }
      // Now issue 3 (should be fine), then a 4th should fail.
      final ids = (await bookService.search()).map((e) => e.book.id!).toList();
      for (final id in ids.take(3)) {
        await loanService.issue(
          userId: student.id!,
          bookId: id,
          librarianId: librarian.id!,
        );
      }
      if (ids.length > 3) {
        expect(
          () => loanService.issue(
            userId: student.id!,
            bookId: ids[3],
            librarianId: librarian.id!,
          ),
          throwsA(isA<LoanException>()),
        );
      }
    });

    test('reconcileOverdue marks active past-due loans', () async {
      // Issue with a 0-day override so due_date is in the past.
      final loan = await loanService.issue(
        userId: student.id!,
        bookId: book.id!,
        librarianId: librarian.id!,
        overrideLoanDays: 0,
      );
      // Issue date = now, due date = now + 0; reconcile should mark it overdue
      // on the next call.
      await Future.delayed(const Duration(milliseconds: 5));
      await loanService.reconcileOverdue();
      final reloaded = await loans.findById(loan.id!);
      expect(reloaded!.status, equals(AppConstants.statusOverdue));
    });
  });
}
