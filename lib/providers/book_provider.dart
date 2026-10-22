import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/category.dart';
import '../services/book_service.dart';

class BookProvider extends ChangeNotifier {
  // BookService (local SQLite) OR RemoteBookService (HTTP). Both duck-typed.
  final dynamic _service;
  // In local mode: CategoryRepository. In remote mode: null (use _service.categories()).
  final dynamic _categories;
  BookProvider(this._service, [this._categories]);

  List<BookWithCategory> _items = [];
  List<Category> _categoriesList = [];
  bool _loading = false;
  String? _error;

  List<BookWithCategory> get items => _items;
  List<Category> get categories => _categoriesList;
  bool get isLoading => _loading;
  String? get error => _error;

  String _query = '';
  int? _categoryId;
  bool _availableOnly = false;

  String get query => _query;
  int? get categoryId => _categoryId;
  bool get availableOnly => _availableOnly;

  Future<void> loadCategories() async {
    // Local mode: use the CategoryRepository directly.
    // Remote mode: _categories is null — use the book service's categories() method.
    if (_categories != null) {
      _categoriesList = await _categories.all();
    } else {
      _categoriesList = await _service.categories();
    }
    notifyListeners();
  }

  /// Ad-hoc search without changing the provider's filter state. Used by the
  /// Issue Loan screen to lookup available books.
  Future<List<BookWithCategory>> search({
    String query = '',
    int? categoryId,
    bool availableOnly = false,
  }) =>
      _service.search(query: query, categoryId: categoryId, availableOnly: availableOnly);

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (_categoriesList.isEmpty) {
        if (_categories != null) {
          _categoriesList = await _categories.all();
        } else {
          _categoriesList = await _service.categories();
        }
      }
      _items = await _service.search(
        query: _query,
        categoryId: _categoryId,
        availableOnly: _availableOnly,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setQuery(String q) {
    _query = q;
    refresh();
  }

  void setCategory(int? id) {
    _categoryId = id;
    refresh();
  }

  void setAvailableOnly(bool v) {
    _availableOnly = v;
    refresh();
  }

  Future<int> createBook(Book book, {int? actorId}) async {
    final id = await _service.createBook(book, actorId: actorId);
    await refresh();
    return id;
  }

  Future<int> updateBook(Book book, {int? actorId}) async {
    final n = await _service.updateBook(book, actorId: actorId);
    await refresh();
    return n;
  }

  Future<void> deleteBook(int id, {int? actorId}) async {
    await _service.deleteBook(id, actorId: actorId);
    await refresh();
  }

  Future<Book?> getBook(int id) => _service.getBook(id);
}
