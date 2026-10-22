const { Router } = require('express');
const { body, query } = require('express-validator');
const validate = require('../middleware/validate');
const requireAuth = require('../middleware/auth');
const { requireLibrarianOrAdmin, requireAdmin } = require('../middleware/role');
const { AppError } = require('../middleware/errorHandler');
const bookService = require('../services/bookService');
const { CategoryModel } = require('../models/bookModel');

const router = Router();

// PUBLIC endpoints — used by the landing page (no auth needed)
router.get('/public/inventory', async (req, res, next) => {
  try {
    res.json(bookService.inventoryStats());
  } catch (err) {
    next(err);
  }
});

router.get('/public/categories', async (req, res, next) => {
  try {
    res.json(bookService.listCategories());
  } catch (err) {
    next(err);
  }
});

router.get('/public/search', async (req, res, next) => {
  try {
    const items = bookService.search({
      query: req.query.q || '',
      categoryId: req.query.categoryId ? Number(req.query.categoryId) : null,
      availableOnly: req.query.availableOnly === 'true',
    });
    res.json(items);
  } catch (err) {
    next(err);
  }
});

// AUTHENTICATED endpoints
router.get('/', requireAuth, async (req, res, next) => {
  try {
    const items = bookService.search({
      query: req.query.q || '',
      categoryId: req.query.categoryId ? Number(req.query.categoryId) : null,
      availableOnly: req.query.availableOnly === 'true',
    });
    res.json(items);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', requireAuth, async (req, res, next) => {
  try {
    const book = bookService.getBook(Number(req.params.id));
    if (!book) throw new AppError('Book not found', 404, 'NOT_FOUND');
    res.json(book);
  } catch (err) {
    next(err);
  }
});

router.post('/', requireAuth, requireLibrarianOrAdmin, [
  body('isbn').notEmpty().withMessage('ISBN required'),
  body('title').notEmpty().withMessage('Title required'),
  body('author').notEmpty().withMessage('Author required'),
  body('total_quantity').isInt({ min: 0 }).withMessage('Total quantity must be a non-negative integer'),
  body('available_quantity').isInt({ min: 0 }).withMessage('Available quantity must be a non-negative integer'),
], validate, async (req, res, next) => {
  try {
    const book = await bookService.createBook({
      ...req.body,
      publication_year: req.body.publication_year ? Number(req.body.publication_year) : null,
      total_quantity: Number(req.body.total_quantity),
      available_quantity: Number(req.body.available_quantity),
    }, { actorId: req.user.id });
    res.status(201).json(book);
  } catch (err) {
    next(err);
  }
});

router.patch('/:id', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    const book = await bookService.updateBook(
      Number(req.params.id),
      {
        ...req.body,
        publication_year: req.body.publication_year ? Number(req.body.publication_year) : undefined,
        total_quantity: req.body.total_quantity != null ? Number(req.body.total_quantity) : undefined,
        available_quantity: req.body.available_quantity != null ? Number(req.body.available_quantity) : undefined,
      },
      { actorId: req.user.id },
    );
    res.json(book);
  } catch (err) {
    next(err);
  }
});

router.delete('/:id', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    await bookService.deleteBook(Number(req.params.id), { actorId: req.user.id });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// Categories
router.get('/categories/all', requireAuth, async (req, res, next) => {
  try {
    res.json(bookService.listCategories());
  } catch (err) {
    next(err);
  }
});

router.post('/categories', requireAuth, requireLibrarianOrAdmin, [
  body('name').trim().notEmpty().withMessage('Name required'),
], validate, async (req, res, next) => {
  try {
    const id = await bookService.createCategory({
      name: req.body.name,
      description: req.body.description,
    }, { actorId: req.user.id });
    res.status(201).json(CategoryModel.findById(id));
  } catch (err) {
    next(err);
  }
});

router.patch('/categories/:id', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    await bookService.updateCategory(Number(req.params.id), {
      name: req.body.name,
      description: req.body.description,
    });
    res.json(CategoryModel.findById(Number(req.params.id)));
  } catch (err) {
    next(err);
  }
});

router.delete('/categories/:id', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    await bookService.deleteCategory(Number(req.params.id));
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
