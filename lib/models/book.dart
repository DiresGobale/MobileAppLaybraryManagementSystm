import 'category.dart';

class Book {
  final int? id;
  final String isbn;
  final String title;
  final String author;
  final int? categoryId;
  final String? publisher;
  final int? publicationYear;
  final String? edition;
  final String? shelfLocation;
  final String? description;
  final int totalQuantity;
  final int availableQuantity;
  final String? coverPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    this.id,
    required this.isbn,
    required this.title,
    required this.author,
    this.categoryId,
    this.publisher,
    this.publicationYear,
    this.edition,
    this.shelfLocation,
    this.description,
    required this.totalQuantity,
    required this.availableQuantity,
    this.coverPath,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAvailable => availableQuantity > 0;
  bool get isOutOfStock => availableQuantity <= 0;
  int get borrowedCount => totalQuantity - availableQuantity;

  factory Book.fromMap(Map<String, dynamic> m) => Book(
        id: m['id'] as int?,
        isbn: m['isbn'] as String,
        title: m['title'] as String,
        author: m['author'] as String,
        categoryId: m['category_id'] as int?,
        publisher: m['publisher'] as String?,
        publicationYear: m['publication_year'] as int?,
        edition: m['edition'] as String?,
        shelfLocation: m['shelf_location'] as String?,
        description: m['description'] as String?,
        totalQuantity: m['total_quantity'] as int,
        availableQuantity: m['available_quantity'] as int,
        coverPath: m['cover_path'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'isbn': isbn,
        'title': title,
        'author': author,
        'category_id': categoryId,
        'publisher': publisher,
        'publication_year': publicationYear,
        'edition': edition,
        'shelf_location': shelfLocation,
        'description': description,
        'total_quantity': totalQuantity,
        'available_quantity': availableQuantity,
        'cover_path': coverPath,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  Book copyWith({
    int? id,
    String? isbn,
    String? title,
    String? author,
    int? categoryId,
    String? publisher,
    int? publicationYear,
    String? edition,
    String? shelfLocation,
    String? description,
    int? totalQuantity,
    int? availableQuantity,
    String? coverPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Book(
        id: id ?? this.id,
        isbn: isbn ?? this.isbn,
        title: title ?? this.title,
        author: author ?? this.author,
        categoryId: categoryId ?? this.categoryId,
        publisher: publisher ?? this.publisher,
        publicationYear: publicationYear ?? this.publicationYear,
        edition: edition ?? this.edition,
        shelfLocation: shelfLocation ?? this.shelfLocation,
        description: description ?? this.description,
        totalQuantity: totalQuantity ?? this.totalQuantity,
        availableQuantity: availableQuantity ?? this.availableQuantity,
        coverPath: coverPath ?? this.coverPath,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// View model joining Book + Category name.
class BookWithCategory {
  final Book book;
  final String? categoryName;

  BookWithCategory({required this.book, this.categoryName});

  factory BookWithCategory.fromMap(Map<String, dynamic> m) => BookWithCategory(
        book: Book.fromMap(m),
        categoryName: m['category_name'] as String?,
      );
}
