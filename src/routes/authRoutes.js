const { Router } = require('express');
const { body, query, param, validationResult } = require('express-validator');
const validate = require('../middleware/validate');
const requireAuth = require('../middleware/auth');
const { requireRole, requireAdmin, requireLibrarianOrAdmin, ownerOrStaff } = require('../middleware/role');
const { AppError } = require('../middleware/errorHandler');
const authService = require('../services/authService');
const { ROLES } = require('../config/constants');

const router = Router();

const registerValidation = [
  body('fullName').trim().isLength({ min: 2 }).withMessage('Full name must be at least 2 characters'),
  body('username').trim().matches(/^[a-zA-Z0-9_.]{3,}$/).withMessage('Username: 3+ chars, letters/digits/._ only'),
  body('email').isEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('studentId').optional({ checkFalsy: true }).isLength({ min: 4 }).withMessage('Student ID too short'),
];

const loginValidation = [
  body('identifier').trim().notEmpty().withMessage('Identifier required'),
  body('password').notEmpty().withMessage('Password required'),
];

router.post('/register', registerValidation, validate, async (req, res, next) => {
  try {
    const result = await authService.registerStudent({
      fullName: req.body.fullName,
      username: req.body.username,
      email: req.body.email,
      password: req.body.password,
      studentId: req.body.studentId,
      department: req.body.department,
    });
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
});

router.post('/login', loginValidation, validate, async (req, res, next) => {
  try {
    const result = await authService.login(req.body.identifier, req.body.password, { ip: req.ip });
    res.json(result);
  } catch (err) {
    next(err);
  }
});

router.post('/logout', requireAuth, async (req, res, next) => {
  try {
    await authService.logout(req.user.id);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

router.get('/me', requireAuth, async (req, res, next) => {
  try {
    const user = authService.listUsers().find((u) => u.id === req.user.id);
    if (!user) throw new AppError('User not found', 404, 'NOT_FOUND');
    const { password_hash, ...safe } = user;
    res.json(safe);
  } catch (err) {
    next(err);
  }
});

router.post('/change-password', requireAuth, [
  body('currentPassword').notEmpty(),
  body('newPassword').isLength({ min: 6 }),
], validate, async (req, res, next) => {
  try {
    await authService.changePassword(req.user.id, req.body.currentPassword, req.body.newPassword);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

router.patch('/profile', requireAuth, [
  body('fullName').optional({ checkFalsy: true }).trim().isLength({ min: 2 }),
  body('email').optional({ checkFalsy: true }).isEmail(),
], validate, async (req, res, next) => {
  try {
    const updated = await authService.updateProfile(req.user.id, {
      fullName: req.body.fullName,
      department: req.body.department,
      email: req.body.email,
    });
    const { password_hash, ...safe } = updated;
    res.json(safe);
  } catch (err) {
    next(err);
  }
});

// ---- Admin user management ----
router.get('/users', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    const users = authService.listUsers({ roleFilter: req.query.role || undefined });
    res.json(users.map(({ password_hash, ...u }) => u));
  } catch (err) {
    next(err);
  }
});

router.post('/users', requireAuth, requireAdmin, [
  body('fullName').trim().isLength({ min: 2 }),
  body('username').trim().matches(/^[a-zA-Z0-9_.]{3,}$/),
  body('email').isEmail(),
  body('password').isLength({ min: 6 }),
  body('role').isIn([ROLES.ADMIN, ROLES.LIBRARIAN, ROLES.STUDENT]),
], validate, async (req, res, next) => {
  try {
    const user = await authService.createUserByAdmin({
      fullName: req.body.fullName,
      username: req.body.username,
      email: req.body.email,
      password: req.body.password,
      role: req.body.role,
      studentId: req.body.studentId,
      department: req.body.department,
    }, req.user.id);
    const { password_hash, ...safe } = user;
    res.status(201).json(safe);
  } catch (err) {
    next(err);
  }
});

router.patch('/users/:id/deactivate', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    await authService.deactivate(Number(req.params.id), req.user.id);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

router.patch('/users/:id/reactivate', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    await authService.reactivate(Number(req.params.id), req.user.id);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

router.delete('/users/:id', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    await authService.deleteUser(Number(req.params.id), req.user.id);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
