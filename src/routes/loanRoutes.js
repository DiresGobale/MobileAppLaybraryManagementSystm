const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const requireAuth = require('../middleware/auth');
const { requireLibrarianOrAdmin, ownerOrStaff } = require('../middleware/role');
const { AppError } = require('../middleware/errorHandler');
const loanService = require('../services/loanService');

const router = Router();

// Student (or any user) can see their own active + history loans
router.get('/my', requireAuth, async (req, res, next) => {
  try {
    res.json({
      active: loanService.activeForUser(req.user.id),
      history: loanService.historyForUser(req.user.id),
    });
  } catch (err) {
    next(err);
  }
});

// Librarian/Admin: get loans with optional filters
router.get('/', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    const items = loanService.recent({ limit: Number(req.query.limit || 100) });
    res.json(items);
  } catch (err) {
    next(err);
  }
});

router.get('/overdue', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    res.json(loanService.overdueLoans());
  } catch (err) {
    next(err);
  }
});

router.get('/book/:bookId', requireAuth, async (req, res, next) => {
  try {
    res.json(loanService.activeForBook(Number(req.params.bookId)));
  } catch (err) {
    next(err);
  }
});

router.post('/issue', requireAuth, requireLibrarianOrAdmin, [
  body('userId').isInt({ min: 1 }),
  body('bookId').isInt({ min: 1 }),
  body('overrideLoanDays').optional().isInt({ min: 1, max: 60 }),
], validate, async (req, res, next) => {
  try {
    const loan = loanService.issue({
      userId: Number(req.body.userId),
      bookId: Number(req.body.bookId),
      librarianId: req.user.id,
      overrideLoanDays: req.body.overrideLoanDays ? Number(req.body.overrideLoanDays) : null,
    });
    res.status(201).json(loan);
  } catch (err) {
    next(err);
  }
});

router.post('/return', requireAuth, requireLibrarianOrAdmin, [
  body('loanId').isInt({ min: 1 }),
], validate, async (req, res, next) => {
  try {
    const loan = loanService.returnLoan({
      loanId: Number(req.body.loanId),
      librarianId: req.user.id,
    });
    res.json(loan);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', requireAuth, async (req, res, next) => {
  try {
    const loan = loanService.findById
      ? loanService.findById(Number(req.params.id))
      : require('../models/loanModel').findById(Number(req.params.id));
    if (!loan) throw new AppError('Loan not found', 404, 'NOT_FOUND');
    res.json(loan);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
