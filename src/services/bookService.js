const { AppError } = require('../middleware/errorHandler');
const { BookModel, CategoryModel } = require('../models/bookModel');
const { ActivityLogModel } = require('../models/auxModels');
const { ACTION_KEYS } = require('../config/constants');

class BookService {
  search({ query, categoryId, availableOnly } = {}) {
    return BookModel.search({ query: query || '', categoryId, availableOnly });
  }

  getBook(id) {
    return BookModel.findByIdWithCategory(id);
  }

  findByIsbn(isbn) {
    return BookModel.findByIsbn(isbn);
  }

  async createBook(book, { actorId = null } = {}) {
    if (BookModel.findByIsbn(book.isbn)) {
      throw new AppError('A book with this ISBN already exists.', 409, 'ISBN_DUPLICATE');
    }
    if (book.total_quantity < 0) {
      throw new AppError('Total quantity cannot be negative.', 400, 'BAD_QTY');
    }
    if (book.available_quantity > book.total_quantity) {
      throw new AppError('Available quantity cannot exceed total quantity.', 400, 'BAD_QTY');
    }
    const id = BookModel.create(book);
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.BOOK_ADD,
      details: `Added book: ${book.title} (ISBN ${book.isbn})`,
    });
    return BookModel.findById(id);
  }

  async updateBook(id, fields, { actorId = null } = {}) {
    const existing = BookModel.findById(id);
    if (!existing) throw new AppError('Book not found.', 404, 'NOT_FOUND');
    if (fields.isbn && fields.isbn !== existing.isbn) {
      const dup = BookModel.findByIsbn(fields.isbn);
      if (dup && dup.id !== existing.id) {
        throw new AppError('A book with this ISBN already exists.', 409, 'ISBN_DUPLICATE');
      }
    }
    if (fields.available_quantity != null && fields.total_quantity != null &&
        fields.available_quantity > fields.total_quantity) {
      throw new AppError('Available quantity cannot exceed total quantity.', 400, 'BAD_QTY');
    }
    BookModel.update(id, fields);
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.BOOK_EDIT,
      details: `Updated book #${id}: ${existing.title}`,
    });
    return BookModel.findById(id);
  }

  async deleteBook(id, { actorId = null } = {}) {
    const book = BookModel.findById(id);
    if (!book) throw new AppError('Book not found.', 404, 'NOT_FOUND');
    const active = BookModel.countActiveLoansForBook(id);
    if (active > 0) {
      throw new AppError(
        `Cannot delete: ${active} active loan(s) reference this book. Resolve them first.`,
        409, 'BOOK_HAS_LOANS',
      );
    }
    BookModel.remove(id);
    ActivityLogModel.create({
      user_id: actorId,
      action: ACTION_KEYS.BOOK_DELETE,
      details: `Deleted book #${id}: ${book.title}`,
    });
  }

  // ---- Categories ----
  listCategories() {
    return CategoryModel.all();
  }

  async createCategory({ name, description = null }, { actorId = null } = {}) {
    const trimmed = (name || '').trim();
    if (!trimmed) throw new AppError('Category name cannot be empty.', 400, 'BAD_NAME');
    if (CategoryModel.findByName(trimmed)) {
      throw new AppError('Category name already exists.', 409, 'DUPLICATE');
    }
    return CategoryModel.create({ name: trimmed, description });
  }

  async updateCategory(id, { name, description }, { actorId = null } = {}) {
    const trimmed = (name || '').trim();
    if (!trimmed) throw new AppError('Category name cannot be empty.', 400, 'BAD_NAME');
    return CategoryModel.update(id, { name: trimmed, description });
  }

  async deleteCategory(id) {
    const count = CategoryModel.countBooksInCategory(id);
    if (count > 0) {
      throw new AppError(`Cannot delete: ${count} book(s) still in this category.`, 409, 'NOT_EMPTY');
    }
    return CategoryModel.remove(id);
  }

  // ---- Stats ----
  inventoryStats() {
    return {
      titles: BookModel.countTitles(),
      totalCopies: BookModel.sumTotalCopies(),
      availableCopies: BookModel.sumAvailableCopies(),
      borrowedCopies: BookModel.sumTotalCopies() - BookModel.sumAvailableCopies(),
      outOfStockTitles: BookModel.countOutOfStock(),
      categories: CategoryModel.count(),
    };
  }
}

module.exports = new BookService();
