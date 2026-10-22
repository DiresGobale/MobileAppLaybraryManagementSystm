import '../models/book.dart';
import '../models/category.dart';
import '../repositories/book_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/activity_log_repository.dart';
import '../utils/constants.dart';

class BookService {
  final BookRepository _books;
  final CategoryRepository _categories;
  final ActivityLogRepository _logs;

  BookService(this._books, this._categories, this._logs);

  // ---- Books ----
  Future<Book?> getBook(int id) => _books.findById(id);

  Future<Book?> findByIsbn(String isbn) => _books.findByIsbn(isbn);

  Future<List<BookWithCategory>> search({
    String query = '',
    int? categoryId,
    bool availableOnly = false,
  }) =>
      _books.search(query: query, categoryId: categoryId, availableOnly: availableOnly);

  Future<int> createBook(Book book, {int? actorId}) async {
    if (await _books.findByIsbn(book.isbn) != null) {
      throw BookException('A book with this ISBN already exists.');
    }
    if (book.totalQuantity < 0) {
      throw BookException('Total quantity cannot be negative.');
    }
    if (book.availableQuantity > book.totalQuantity) {
      throw BookException('Available quantity cannot exceed total quantity.');
    }
    final id = await _books.create(book);
    await _logs.create(ActivityLog(
      userId: actorId,
      action: AppConstants.actionBookAdd,
      details: 'Added book: ${book.title} (ISBN ${book.isbn})',
      createdAt: DateTime.now(),
    ));
    return id;
  }

  Future<int> updateBook(Book book, {int? actorId}) async {
    final existing = await _books.findById(book.id!);
    if (existing == null) throw BookException('Book not found.');
    if (book.availableQuantity > book.totalQuantity) {
      throw BookException('Available quantity cannot exceed total quantity.');
    }
    // If user is changing ISBN, ensure new one doesn't collide.
    if (book.isbn != existing.isbn) {
      final dup = await _books.findByIsbn(book.isbn);
      if (dup != null && dup.id != existing.id) {
        throw BookException('A book with this ISBN already exists.');
      }
    }
    final n = await _books.update(book);
    await _logs.create(ActivityLog(
      userId: actorId,
      action: AppConstants.actionBookEdit,
      details: 'Updated book #${book.id}: ${book.title}',
      createdAt: DateTime.now(),
    ));
    return n;
  }

  Future<void> deleteBook(int id, {int? actorId}) async {
    final activeLoans = await _books.countActiveLoansForBook(id);
    if (activeLoans > 0) {
      throw BookException('Cannot delete: $activeLoans active loan(s) reference this book. '
          'Resolve the loans first.');
    }
    final book = await _books.findById(id);
    if (book == null) throw BookException('Book not found.');
    await _books.delete(id);
    await _logs.create(ActivityLog(
      userId: actorId,
      action: AppConstants.actionBookDelete,
      details: 'Deleted book #$id: ${book.title}',
      createdAt: DateTime.now(),
    ));
  }

  // ---- Categories ----
  Future<List<Category>> categories() => _categories.all();

  Future<int> createCategory(Category category) async {
    if (category.name.trim().isEmpty) {
      throw BookException('Category name cannot be empty.');
    }
    if (await _categories.findByName(category.name.trim()) != null) {
      throw BookException('Category name already exists.');
    }
    return _categories.create(category.copyWith(name: category.name.trim()));
  }

  Future<int> updateCategory(Category category) async {
    if (category.name.trim().isEmpty) {
      throw BookException('Category name cannot be empty.');
    }
    return _categories.update(category.copyWith(name: category.name.trim()));
  }

  Future<void> deleteCategory(int id) async {
    final count = await _categories.countBooksInCategory(id);
    if (count > 0) {
      throw BookException('Cannot delete: $count book(s) still in this category. '
          'Reassign books first.');
    }
    await _categories.delete(id);
  }

  Future<Map<String, int>> inventoryStats() async => {
        'titles': await _books.countTitles(),
        'totalCopies': await _books.sumTotalCopies(),
        'availableCopies': await _books.sumAvailableCopies(),
        'borrowedCopies': await _books.sumBorrowedCopies(),
        'outOfStockTitles': await _books.countOutOfStock(),
        'categories': await _categories.count(),
      };
}

class BookException implements Exception {
  final String message;
  BookException(this.message);
  @override
  String toString() => message;
}
