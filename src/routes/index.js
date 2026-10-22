const { Router } = require('express');

const authRoutes = require('./authRoutes');
const bookRoutes = require('./bookRoutes');
const loanRoutes = require('./loanRoutes');
const libraryRoutes = require('./libraryRoutes');
const reportRoutes = require('./reportRoutes');

const router = Router();

// Health check — no auth, no DB.
router.get('/health', (req, res) => {
  res.json({ ok: true, service: 'iulms-backend', ts: new Date().toISOString() });
});

// All feature routes mount under /api
router.use('/api/auth', authRoutes);
router.use('/api/books', bookRoutes);
router.use('/api/loans', loanRoutes);
router.use('/api', libraryRoutes);    // /api/public/info, /api/notifications, /api/admin/...
router.use('/api/reports', reportRoutes);

module.exports = router;
