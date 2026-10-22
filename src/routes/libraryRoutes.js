const { Router } = require('express');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const requireAuth = require('../middleware/auth');
const { requireAdmin, requireLibrarianOrAdmin } = require('../middleware/role');
const libraryInfoService = require('../services/libraryInfoService');
const { NotificationService, ActivityLogService } = require('../services/auxServices');

const router = Router();

// ---- PUBLIC landing page content ----
router.get('/public/info', async (req, res, next) => {
  try {
    const [info, services, steps] = await Promise.all([
      Promise.resolve(libraryInfoService.fetchContactInfo()),
      Promise.resolve(libraryInfoService.listServices()),
      Promise.resolve(libraryInfoService.listSteps()),
    ]);
    res.json({ info, services, steps });
  } catch (err) {
    next(err);
  }
});

router.post('/public/contact', [
  body('name').trim().notEmpty().withMessage('Name required'),
  body('email').isEmail().withMessage('Valid email required'),
  body('subject').trim().notEmpty().withMessage('Subject required'),
  body('message').trim().isLength({ min: 10 }).withMessage('Message must be at least 10 characters'),
], validate, async (req, res, next) => {
  try {
    const msg = libraryInfoService.submitContactMessage({
      name: req.body.name,
      email: req.body.email,
      subject: req.body.subject,
      message: req.body.message,
    });
    res.status(201).json(msg);
  } catch (err) {
    next(err);
  }
});

// ---- AUTHENTICATED notifications ----
router.get('/notifications', requireAuth, async (req, res, next) => {
  try {
    res.json({
      items: NotificationService.forUser(req.user.id, {
        unreadOnly: req.query.unreadOnly === 'true',
      }),
      unreadCount: NotificationService.countUnread(req.user.id),
    });
  } catch (err) {
    next(err);
  }
});

router.patch('/notifications/:id/read', requireAuth, async (req, res, next) => {
  try {
    NotificationService.markRead(Number(req.params.id));
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

router.patch('/notifications/read-all', requireAuth, async (req, res, next) => {
  try {
    NotificationService.markAllRead(req.user.id);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

router.delete('/notifications/:id', requireAuth, async (req, res, next) => {
  try {
    NotificationService.remove(Number(req.params.id));
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ---- AUTHENTICATED activity log ----
router.get('/activity-log', requireAuth, async (req, res, next) => {
  try {
    const { ROLES } = require('../config/constants');
    const mineOnly = req.query.mineOnly === 'true' || (req.user.role !== ROLES.ADMIN && req.user.role !== ROLES.LIBRARIAN);
    res.json(ActivityLogService.recent({
      limit: Number(req.query.limit || 200),
      actorId: mineOnly ? req.user.id : null,
    }));
  } catch (err) {
    next(err);
  }
});

// ---- ADMIN: library services CRUD ----
router.get('/admin/services', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    res.json(libraryInfoService.listAllServices());
  } catch (err) {
    next(err);
  }
});

router.post('/admin/services', requireAuth, requireAdmin, [
  body('title').trim().notEmpty(),
  body('description').trim().notEmpty(),
], validate, async (req, res, next) => {
  try {
    res.status(201).json(libraryInfoService.createService(req.body, { actorId: req.user.id }));
  } catch (err) {
    next(err);
  }
});

router.patch('/admin/services/:id', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    res.json(libraryInfoService.updateService(Number(req.params.id), req.body, { actorId: req.user.id }));
  } catch (err) {
    next(err);
  }
});

router.delete('/admin/services/:id', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    await libraryInfoService.deleteService(Number(req.params.id), { actorId: req.user.id });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ---- ADMIN: library steps CRUD ----
router.get('/admin/steps', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    res.json(libraryInfoService.listAllSteps());
  } catch (err) {
    next(err);
  }
});

router.post('/admin/steps', requireAuth, requireAdmin, [
  body('step_number').isInt({ min: 1 }),
  body('title').trim().notEmpty(),
  body('description').trim().notEmpty(),
], validate, async (req, res, next) => {
  try {
    res.status(201).json(libraryInfoService.createStep(req.body, { actorId: req.user.id }));
  } catch (err) {
    next(err);
  }
});

router.patch('/admin/steps/:id', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    res.json(libraryInfoService.updateStep(Number(req.params.id), req.body, { actorId: req.user.id }));
  } catch (err) {
    next(err);
  }
});

router.delete('/admin/steps/:id', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    await libraryInfoService.deleteStep(Number(req.params.id), { actorId: req.user.id });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ---- ADMIN: contact inbox ----
router.get('/admin/contact-inbox', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    res.json(libraryInfoService.listContactMessages({
      unhandledOnly: req.query.unhandledOnly === 'true',
    }));
  } catch (err) {
    next(err);
  }
});

router.patch('/admin/contact-inbox/:id/handled', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    libraryInfoService.markContactHandled(Number(req.params.id), { actorId: req.user.id });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

router.delete('/admin/contact-inbox/:id', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    libraryInfoService.deleteContactMessage(Number(req.params.id), { actorId: req.user.id });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

// ---- ADMIN: library info settings ----
router.get('/admin/info', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    res.json(libraryInfoService.fetchContactInfo());
  } catch (err) {
    next(err);
  }
});

router.patch('/admin/info', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    const allowed = [
      'library_tagline','library_mission','library_vision','library_history',
      'library_email','library_phone','library_address','library_hours',
      'library_facebook','library_twitter','library_instagram','library_name',
    ];
    for (const [k, v] of Object.entries(req.body)) {
      if (allowed.includes(k)) {
        await libraryInfoService.setSetting(k, String(v), { actorId: req.user.id });
      }
    }
    res.json(libraryInfoService.fetchContactInfo());
  } catch (err) {
    next(err);
  }
});

module.exports = router;
