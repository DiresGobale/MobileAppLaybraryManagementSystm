import 'dart:convert';

import '../models/activity_log.dart';
import '../models/app_notification.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../models/library_info.dart';
import '../models/loan.dart';
import '../models/report.dart';
import '../models/setting.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import 'api_client.dart';

// =============================================================================
//  RemoteAuthService
// =============================================================================
/// Mirrors [AuthService] but every call goes to the Node.js backend
/// `/api/auth/*` endpoints. Returns the same model objects so the Provider
/// layer doesn't need to know whether it's hitting local SQLite or the
/// remote API.
class RemoteAuthService {
  final ApiClient _api = ApiClient.instance;
  User? _currentUser;
  String? _jwt;

  User? get currentUser => _currentUser;

  Future<bool> get needsInitialAdmin async => false; // backend handles this

  Future<bool> get selfRegistrationEnabled async {
    final info = await _api.getJson('/api/public/info');
    // Backend doesn't currently expose this; default to true.
    return true;
  }

  Future<User> registerStudent({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? studentId,
    String? department,
  }) async {
    final res = await _api.postJson('/api/auth/register', {
      'fullName': fullName,
      'username': username,
      'email': email,
      'password': password,
      'studentId': studentId,
      'department': department,
    });
    _jwt = res['token'];
    await _api.saveToken(_jwt!);
    _currentUser = _userFromJson(res['user']);
    return _currentUser!;
  }

  Future<User> createUserByAdmin({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String role,
    String? studentId,
    String? department,
    required int createdBy,
  }) async {
    final res = await _api.postJson('/api/auth/users', {
      'fullName': fullName,
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'studentId': studentId,
      'department': department,
    });
    return _userFromJson(res);
  }

  Future<User?> login(String identifier, String password) async {
    final res = await _api.postJson('/api/auth/login', {
      'identifier': identifier,
      'password': password,
    });
    _jwt = res['token'];
    await _api.saveToken(_jwt!);
    _currentUser = _userFromJson(res['user']);
    return _currentUser;
  }

  Future<void> logout() async {
    try {
      await _api.postJson('/api/auth/logout', {});
    } catch (_) {
      // Backend unreachable — still clear local token.
    }
    await _api.clearToken();
    _jwt = null;
    _currentUser = null;
  }

  Future<User?> get currentUserAsync async {
    try {
      final res = await _api.getJson('/api/auth/me');
      _currentUser = _userFromJson(res);
      return _currentUser;
    } catch (_) {
      // Token might be expired — clear and return null.
      await _api.clearToken();
      return null;
    }
  }

  Future<bool> changePassword(
      int userId, String currentPassword, String newPassword) async {
    await _api.postJson('/api/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return true;
  }

  Future<User> updateProfile(int userId,
      {String? fullName, String? department, String? email}) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (department != null) body['department'] = department;
    if (email != null) body['email'] = email;
    final res = await _api.patchJson('/api/auth/profile', body);
    _currentUser = _userFromJson(res);
    return _currentUser!;
  }

  Future<void> deactivate(int userId, int byAdminId) async {
    await _api.patchJson('/api/auth/users/$userId/deactivate', {});
  }

  Future<void> reactivate(int userId, int byAdminId) async {
    await _api.patchJson('/api/auth/users/$userId/reactivate', {});
  }

  Future<void> deleteUser(int userId, int byAdminId) async {
    await _api.deleteJson('/api/auth/users/$userId');
  }

  Future<List<User>> listUsers({String? roleFilter}) async {
    final qs = roleFilter != null ? <String, dynamic>{'role': roleFilter} : null;
    final res = await _api.getJson('/api/auth/users', query: qs);
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(_userFromJson).toList();
  }

  Future<int> defaultLoanDays() async {
    try {
      final info = await _api.getJson('/api/public/info');
      return 14; // Backend default; would be exposed via /api/admin/info
    } catch (_) {
      return 14;
    }
  }

  Future<int> maxActiveLoans() async => 3;

  User _userFromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int?,
        fullName: j['full_name'] as String? ?? j['fullName'] as String? ?? '',
        username: j['username'] as String? ?? '',
        email: j['email'] as String? ?? '',
        passwordHash: '', // never sent over the wire
        passwordSalt: '',
        role: j['role'] as String? ?? Role.student,
        studentId: j['student_id'] as String? ?? j['studentId'] as String?,
        department: j['department'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch((j['created_at'] as num).toInt())
            : DateTime.now(),
        isActive: ((j['is_active'] ?? j['isActive'] ?? 1) as num) == 1,
      );
}

// =============================================================================
//  RemoteBookService
// =============================================================================
class RemoteBookService {
  final ApiClient _api = ApiClient.instance;

  Future<Book?> getBook(int id) async {
    final res = await _api.getJson('/api/books/$id');
    return _bookFromJson(res);
  }

  Future<Book?> findByIsbn(String isbn) async {
    final res = await _api.getJson('/api/books', query: {'q': isbn});
    if (res is List && res.isNotEmpty) return _bookFromJson(res.first);
    return null;
  }

  Future<List<BookWithCategory>> search({
    String query = '',
    int? categoryId,
    bool availableOnly = false,
  }) async {
    final q = <String, dynamic>{
      'q': query,
      if (categoryId != null) 'categoryId': categoryId,
      if (availableOnly) 'availableOnly': 'true',
    };
    final res = await _api.getJson('/api/books', query: q);
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(_bookWithCategoryFromJson).toList();
  }

  Future<int> createBook(Book book, {int? actorId}) async {
    final res = await _api.postJson('/api/books', _bookToJson(book));
    return (res['id'] as num).toInt();
  }

  Future<int> updateBook(Book book, {int? actorId}) async {
    await _api.patchJson('/api/books/${book.id}', _bookToJson(book));
    return 1;
  }

  Future<void> deleteBook(int id, {int? actorId}) async {
    await _api.deleteJson('/api/books/$id');
  }

  Future<List<Category>> categories() async {
    final res = await _api.getJson('/api/books/categories/all');
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(_categoryFromJson).toList();
  }

  Future<int> createCategory(Category category) async {
    final res = await _api.postJson('/api/books/categories', {
      'name': category.name,
      'description': category.description,
    });
    return (res['id'] as num).toInt();
  }

  Future<int> updateCategory(Category category) async {
    await _api.patchJson('/api/books/categories/${category.id}', {
      'name': category.name,
      'description': category.description,
    });
    return 1;
  }

  Future<void> deleteCategory(int id) async {
    await _api.deleteJson('/api/books/categories/$id');
  }

  Future<Map<String, int>> inventoryStats() async {
    final res = await _api.getJson('/api/books/public/inventory');
    return {
      'titles': (res['titles'] as num?)?.toInt() ?? 0,
      'totalCopies': (res['totalCopies'] as num?)?.toInt() ?? 0,
      'availableCopies': (res['availableCopies'] as num?)?.toInt() ?? 0,
      'borrowedCopies': (res['borrowedCopies'] as num?)?.toInt() ?? 0,
      'outOfStockTitles': (res['outOfStockTitles'] as num?)?.toInt() ?? 0,
      'categories': (res['categories'] as num?)?.toInt() ?? 0,
    };
  }

  Book _bookFromJson(Map<String, dynamic> j) => Book(
        id: j['id'] as int?,
        isbn: j['isbn'] as String? ?? '',
        title: j['title'] as String? ?? '',
        author: j['author'] as String? ?? '',
        categoryId: j['category_id'] as int?,
        publisher: j['publisher'] as String?,
        publicationYear: (j['publication_year'] as num?)?.toInt(),
        edition: j['edition'] as String?,
        shelfLocation: j['shelf_location'] as String?,
        description: j['description'] as String?,
        totalQuantity: (j['total_quantity'] as num?)?.toInt() ?? 0,
        availableQuantity: (j['available_quantity'] as num?)?.toInt() ?? 0,
        coverPath: j['cover_path'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch((j['created_at'] as num).toInt())
            : DateTime.now(),
        updatedAt: j['updated_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch((j['updated_at'] as num).toInt())
            : DateTime.now(),
      );

  BookWithCategory _bookWithCategoryFromJson(Map<String, dynamic> j) =>
      BookWithCategory(book: _bookFromJson(j), categoryName: j['category_name'] as String?);

  Map<String, dynamic> _bookToJson(Book b) => {
        if (b.id != null) 'id': b.id,
        'isbn': b.isbn,
        'title': b.title,
        'author': b.author,
        'category_id': b.categoryId,
        'publisher': b.publisher,
        'publication_year': b.publicationYear,
        'edition': b.edition,
        'shelf_location': b.shelfLocation,
        'description': b.description,
        'total_quantity': b.totalQuantity,
        'available_quantity': b.availableQuantity,
        'cover_path': b.coverPath,
      };

  Category _categoryFromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int?,
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
      );
}

// =============================================================================
//  RemoteLoanService
// =============================================================================
class RemoteLoanService {
  final ApiClient _api = ApiClient.instance;

  Future<int> defaultLoanDays() async => 14;
  Future<int> maxActiveLoans() async => 3;

  Future<Loan> issue({
    required int userId,
    required int bookId,
    required int librarianId,
    int? overrideLoanDays,
  }) async {
    final res = await _api.postJson('/api/loans/issue', {
      'userId': userId,
      'bookId': bookId,
      if (overrideLoanDays != null) 'overrideLoanDays': overrideLoanDays,
    });
    return _loanFromJson(res);
  }

  Future<Loan> returnLoan({required int loanId, required int librarianId}) async {
    final res = await _api.postJson('/api/loans/return', {'loanId': loanId});
    return _loanFromJson(res);
  }

  Future<int> reconcileOverdue() async {
    // Backend reconciles on every loan query — no separate call needed.
    return 0;
  }

  Future<List<LoanDetail>> overdueLoans() async {
    final res = await _api.getJson('/api/loans/overdue');
    return _loanDetailList(res);
  }

  Future<List<LoanDetail>> activeForUser(int userId) async {
    final res = await _api.getJson('/api/loans/my');
    final map = res as Map<String, dynamic>;
    final active = map['active'] as List? ?? [];
    return _loanDetailList(active);
  }

  Future<List<LoanDetail>> historyForUser(int userId) async {
    final res = await _api.getJson('/api/loans/my');
    final map = res as Map<String, dynamic>;
    final history = map['history'] as List? ?? [];
    return _loanDetailList(history);
  }

  Future<List<LoanDetail>> activeForBook(int bookId) async {
    final res = await _api.getJson('/api/loans/book/$bookId');
    return _loanDetailList(res);
  }

  Future<List<LoanDetail>> loansBetween(DateTime from, DateTime to) async {
    final res = await _api.getJson('/api/reports/loans', query: {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    });
    return _loanDetailList(res);
  }

  Future<List<LoanDetail>> recentLoans({int limit = 10}) async {
    final res = await _api.getJson('/api/loans', query: {'limit': limit});
    return _loanDetailList(res);
  }

  Loan _loanFromJson(Map<String, dynamic> j) => Loan(
        id: j['id'] as int?,
        userId: (j['user_id'] as num).toInt(),
        bookId: (j['book_id'] as num).toInt(),
        issuedBy: (j['issued_by'] as num).toInt(),
        issueDate: DateTime.fromMillisecondsSinceEpoch((j['issue_date'] as num).toInt()),
        dueDate: DateTime.fromMillisecondsSinceEpoch((j['due_date'] as num).toInt()),
        returnDate: j['return_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch((j['return_date'] as num).toInt())
            : null,
        status: j['status'] as String? ?? AppConstants.statusActive,
      );

  List<LoanDetail> _loanDetailList(dynamic res) {
    if (res is! List) return [];
    return res.cast<Map<String, dynamic>>().map(_loanDetailFromJson).toList();
  }

  LoanDetail _loanDetailFromJson(Map<String, dynamic> j) => LoanDetail(
        loan: _loanFromJson(j),
        bookTitle: j['book_title'] as String? ?? '',
        bookIsbn: j['book_isbn'] as String? ?? '',
        bookAuthor: j['book_author'] as String? ?? '',
        userName: j['user_name'] as String? ?? '',
        userStudentId: j['user_student_id'] as String?,
        librarianName: j['librarian_name'] as String?,
      );
}

// =============================================================================
//  RemoteNotificationService
// =============================================================================
class RemoteNotificationService {
  final ApiClient _api = ApiClient.instance;

  Future<List<AppNotification>> forUser(int userId, {bool unreadOnly = false}) async {
    final res = await _api.getJson('/api/notifications', query: {
      if (unreadOnly) 'unreadOnly': 'true',
    });
    final map = res as Map<String, dynamic>;
    final list = map['items'] as List? ?? [];
    return list.cast<Map<String, dynamic>>().map(_notificationFromJson).toList();
  }

  Future<int> countUnread(int userId) async {
    final res = await _api.getJson('/api/notifications');
    final map = res as Map<String, dynamic>;
    return (map['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(int id) async {
    await _api.patchJson('/api/notifications/$id/read', {});
  }

  Future<void> markAllRead(int userId) async {
    await _api.patchJson('/api/notifications/read-all', {});
  }

  Future<int> delete(int id) async {
    await _api.deleteJson('/api/notifications/$id');
    return 1;
  }

  AppNotification _notificationFromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as int?,
        userId: (j['user_id'] as num).toInt(),
        title: j['title'] as String? ?? '',
        message: j['message'] as String? ?? '',
        createdAt: j['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch((j['created_at'] as num).toInt())
            : DateTime.now(),
        isRead: ((j['is_read'] ?? 0) as num) == 1,
      );
}

// =============================================================================
//  RemoteReportService
// =============================================================================
class RemoteReportService {
  final ApiClient _api = ApiClient.instance;

  Future<DashboardStats> dashboardStats({int recentLimit = 10}) async {
    final res = await _api.getJson('/api/reports/dashboard');
    final recent = (res['recentLoans'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((j) => LoanDetail(
              loan: Loan(
                id: j['id'] as int?,
                userId: (j['user_id'] as num).toInt(),
                bookId: (j['book_id'] as num).toInt(),
                issuedBy: (j['issued_by'] as num).toInt(),
                issueDate: DateTime.fromMillisecondsSinceEpoch((j['issue_date'] as num).toInt()),
                dueDate: DateTime.fromMillisecondsSinceEpoch((j['due_date'] as num).toInt()),
                returnDate: j['return_date'] != null
                    ? DateTime.fromMillisecondsSinceEpoch((j['return_date'] as num).toInt())
                    : null,
                status: j['status'] as String? ?? AppConstants.statusActive,
              ),
              bookTitle: j['book_title'] as String? ?? '',
              bookIsbn: j['book_isbn'] as String? ?? '',
              bookAuthor: j['book_author'] as String? ?? '',
              userName: j['user_name'] as String? ?? '',
              userStudentId: j['user_student_id'] as String?,
              librarianName: j['librarian_name'] as String?,
            ))
        .toList();
    return DashboardStats(
      totalBooks: (res['totalBooks'] as num?)?.toInt() ?? 0,
      availableBooks: (res['availableBooks'] as num?)?.toInt() ?? 0,
      borrowedBooks: (res['borrowedBooks'] as num?)?.toInt() ?? 0,
      registeredStudents: (res['registeredStudents'] as num?)?.toInt() ?? 0,
      overdueLoans: (res['overdueLoans'] as num?)?.toInt() ?? 0,
      activeLoans: (res['activeLoans'] as num?)?.toInt() ?? 0,
      totalLoans: (res['totalLoans'] as num?)?.toInt() ?? 0,
      recentLoans: recent,
    );
  }

  Future<BookInventorySummary> inventorySummary() async {
    final res = await _api.getJson('/api/reports/inventory');
    return BookInventorySummary(
      totalTitles: (res['totalTitles'] as num?)?.toInt() ?? 0,
      totalCopies: (res['totalCopies'] as num?)?.toInt() ?? 0,
      availableCopies: (res['availableCopies'] as num?)?.toInt() ?? 0,
      borrowedCopies: (res['borrowedCopies'] as num?)?.toInt() ?? 0,
      outOfStockTitles: (res['outOfStockTitles'] as num?)?.toInt() ?? 0,
      categories: (res['categories'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<PopularBook>> popularBooks({int limit = 10}) async {
    final res = await _api.getJson('/api/reports/popular', query: {'limit': limit});
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map((j) => PopularBook(
      book: Book(
        id: j['id'] as int?,
        isbn: j['isbn'] as String? ?? '',
        title: j['title'] as String? ?? '',
        author: j['author'] as String? ?? '',
        totalQuantity: (j['total_quantity'] as num?)?.toInt() ?? 0,
        availableQuantity: (j['available_quantity'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      loanCount: (j['loan_count'] as num?)?.toInt() ?? 0,
    )).toList();
  }

  Future<List<LoanDetail>> loansBetween(DateTime from, DateTime to) async {
    final res = await _api.getJson('/api/reports/loans', query: {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    });
    if (res is! List) return [];
    return res.cast<Map<String, dynamic>>().map((j) => LoanDetail(
      loan: Loan(
        id: j['id'] as int?,
        userId: (j['user_id'] as num).toInt(),
        bookId: (j['book_id'] as num).toInt(),
        issuedBy: (j['issued_by'] as num).toInt(),
        issueDate: DateTime.fromMillisecondsSinceEpoch((j['issue_date'] as num).toInt()),
        dueDate: DateTime.fromMillisecondsSinceEpoch((j['due_date'] as num).toInt()),
        returnDate: j['return_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch((j['return_date'] as num).toInt())
            : null,
        status: j['status'] as String? ?? AppConstants.statusActive,
      ),
      bookTitle: j['book_title'] as String? ?? '',
      bookIsbn: j['book_isbn'] as String? ?? '',
      bookAuthor: j['book_author'] as String? ?? '',
      userName: j['user_name'] as String? ?? '',
      userStudentId: j['user_student_id'] as String?,
      librarianName: j['librarian_name'] as String?,
    )).toList();
  }

  Future<List<LoanDetail>> overdueLoans() async {
    final res = await _api.getJson('/api/reports/overdue');
    if (res is! List) return [];
    return res.cast<Map<String, dynamic>>().map((j) => LoanDetail(
      loan: Loan(
        id: j['id'] as int?,
        userId: (j['user_id'] as num).toInt(),
        bookId: (j['book_id'] as num).toInt(),
        issuedBy: (j['issued_by'] as num).toInt(),
        issueDate: DateTime.fromMillisecondsSinceEpoch((j['issue_date'] as num).toInt()),
        dueDate: DateTime.fromMillisecondsSinceEpoch((j['due_date'] as num).toInt()),
        returnDate: j['return_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch((j['return_date'] as num).toInt())
            : null,
        status: j['status'] as String? ?? AppConstants.statusOverdue,
      ),
      bookTitle: j['book_title'] as String? ?? '',
      bookIsbn: j['book_isbn'] as String? ?? '',
      bookAuthor: j['book_author'] as String? ?? '',
      userName: j['user_name'] as String? ?? '',
      userStudentId: j['user_student_id'] as String?,
      librarianName: j['librarian_name'] as String?,
    )).toList();
  }

  Future<String> toCsv(List<LoanDetail> loans) async {
    // The backend has its own CSV endpoint — call it directly with the date range.
    // For an ad-hoc list, fall back to client-side CSV.
    final buf = StringBuffer()
      ..writeln('loan_id,user,student_id,book_title,isbn,author,issued_by,'
          'issue_date,due_date,return_date,status');
    for (final l in loans) {
      buf.writeln([
        l.loan.id, _csv(l.userName), _csv(l.userStudentId ?? ''),
        _csv(l.bookTitle), _csv(l.bookIsbn), _csv(l.bookAuthor),
        _csv(l.librarianName ?? ''), l.loan.issueDate.toIso8601String(),
        l.loan.dueDate.toIso8601String(),
        l.loan.returnDate?.toIso8601String() ?? '', l.loan.status,
      ].join(','));
    }
    return buf.toString();
  }

  String _csv(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}

// =============================================================================
//  RemoteLibraryInfoService
// =============================================================================
class RemoteLibraryInfoService {
  final ApiClient _api = ApiClient.instance;

  Future<List<LibraryService>> services() async {
    final res = await _api.getJson('/api/public/info');
    final list = ((res as Map)['services'] as List? ?? []).cast<Map<String, dynamic>>();
    return list.map(_serviceFromJson).toList();
  }

  Future<List<LibraryStep>> steps() async {
    final res = await _api.getJson('/api/public/info');
    final list = ((res as Map)['steps'] as List? ?? []).cast<Map<String, dynamic>>();
    return list.map(_stepFromJson).toList();
  }

  Future<LibraryContactInfo> contactInfo() async {
    final res = await _api.getJson('/api/public/info');
    final info = (res as Map)['info'] as Map<String, dynamic>;
    return LibraryContactInfo(
      libraryName: info['libraryName'] as String? ?? 'Injibara University Library',
      tagline: info['tagline'] as String? ?? '',
      mission: info['mission'] as String? ?? '',
      vision: info['vision'] as String? ?? '',
      history: info['history'] as String? ?? '',
      email: info['email'] as String? ?? '',
      phone: info['phone'] as String? ?? '',
      address: info['address'] as String? ?? '',
      hours: info['hours'] as String? ?? '',
      facebook: info['facebook'] as String?,
      twitter: info['twitter'] as String?,
      instagram: info['instagram'] as String?,
    );
  }

  Future<int> saveService(LibraryService s, {int? actorId, bool isNew = false}) async {
    if (isNew) {
      final res = await _api.postJson('/api/admin/services', {
        'title': s.title, 'description': s.description,
        'icon_name': s.iconName, 'display_order': s.displayOrder,
      });
      return (res['id'] as num).toInt();
    }
    await _api.patchJson('/api/admin/services/${s.id}', {
      'title': s.title, 'description': s.description,
      'icon_name': s.iconName, 'display_order': s.displayOrder,
      'is_active': s.isActive,
    });
    return s.id!;
  }

  Future<void> deleteService(int id, {int? actorId, String? title}) async {
    await _api.deleteJson('/api/admin/services/$id');
  }

  Future<int> saveStep(LibraryStep s, {int? actorId, bool isNew = false}) async {
    if (isNew) {
      final res = await _api.postJson('/api/admin/steps', {
        'step_number': s.stepNumber, 'title': s.title, 'description': s.description,
        'icon_name': s.iconName, 'display_order': s.displayOrder,
      });
      return (res['id'] as num).toInt();
    }
    await _api.patchJson('/api/admin/steps/${s.id}', {
      'step_number': s.stepNumber, 'title': s.title, 'description': s.description,
      'icon_name': s.iconName, 'display_order': s.displayOrder,
      'is_active': s.isActive,
    });
    return s.id!;
  }

  Future<void> deleteStep(int id, {int? actorId, String? title}) async {
    await _api.deleteJson('/api/admin/steps/$id');
  }

  Future<int> submitContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final res = await _api.postJson('/api/public/contact', {
      'name': name, 'email': email, 'subject': subject, 'message': message,
    });
    return (res['id'] as num).toInt();
  }

  Future<List<ContactMessage>> inbox({bool unhandledOnly = false}) async {
    final res = await _api.getJson('/api/admin/contact-inbox', query: {
      if (unhandledOnly) 'unhandledOnly': 'true',
    });
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map((j) => ContactMessage(
      id: j['id'] as int?,
      name: j['name'] as String,
      email: j['email'] as String,
      subject: j['subject'] as String,
      message: j['message'] as String,
      submittedAt: DateTime.fromMillisecondsSinceEpoch((j['submitted_at'] as num).toInt()),
      isHandled: ((j['is_handled'] ?? 0) as num) == 1,
    )).toList();
  }

  Future<void> markContactHandled(int id, {int? actorId}) async {
    await _api.patchJson('/api/admin/contact-inbox/$id/handled', {});
  }

  Future<void> deleteContactMessage(int id, {int? actorId}) async {
    await _api.deleteJson('/api/admin/contact-inbox/$id');
  }

  Future<void> setSetting(String key, String value, {int? actorId}) async {
    await _api.patchJson('/api/admin/info', {key: value});
  }

  LibraryService _serviceFromJson(Map<String, dynamic> j) => LibraryService(
    id: j['id'] as int?,
    title: j['title'] as String,
    description: j['description'] as String,
    iconName: j['icon_name'] as String? ?? 'menu_book',
    displayOrder: (j['display_order'] as num?)?.toInt() ?? 0,
    isActive: ((j['is_active'] ?? 1) as num) == 1,
  );

  LibraryStep _stepFromJson(Map<String, dynamic> j) => LibraryStep(
    id: j['id'] as int?,
    stepNumber: (j['step_number'] as num?)?.toInt() ?? 1,
    title: j['title'] as String,
    description: j['description'] as String,
    iconName: j['icon_name'] as String? ?? 'search',
    displayOrder: (j['display_order'] as num?)?.toInt() ?? 0,
    isActive: ((j['is_active'] ?? 1) as num) == 1,
  );
}
