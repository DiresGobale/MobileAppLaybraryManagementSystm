const { Router } = require('express');
const requireAuth = require('../middleware/auth');
const { requireLibrarianOrAdmin } = require('../middleware/role');
const reportService = require('../services/reportService');
const { CategoryModel } = require('../models/bookModel');

const router = Router();

router.get('/dashboard', requireAuth, async (req, res, next) => {
  try {
    const stats = reportService.dashboardStats({ recentLimit: 10 });
    // Patch in the categories count (kept out of ReportService to avoid model coupling)
    const summary = reportService.inventorySummary();
    summary.categories = CategoryModel.count();
    res.json({ ...stats, inventory: summary });
  } catch (err) {
    next(err);
  }
});

router.get('/inventory', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    const summary = reportService.inventorySummary();
    summary.categories = CategoryModel.count();
    res.json(summary);
  } catch (err) {
    next(err);
  }
});

router.get('/popular', requireAuth, async (req, res, next) => {
  try {
    res.json(reportService.popularBooks({ limit: Number(req.query.limit || 10) }));
  } catch (err) {
    next(err);
  }
});

router.get('/overdue', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    res.json(reportService.overdueLoans());
  } catch (err) {
    next(err);
  }
});

router.get('/loans', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    const from = req.query.from ? new Date(req.query.from).getTime() : new Date(Date.now() - 30 * 24 * 3600 * 1000).getTime();
    const to = req.query.to ? new Date(req.query.to).getTime() : Date.now();
    res.json(reportService.loansBetween(from, to));
  } catch (err) {
    next(err);
  }
});

router.get('/loans.csv', requireAuth, requireLibrarianOrAdmin, async (req, res, next) => {
  try {
    const from = req.query.from ? new Date(req.query.from).getTime() : new Date(Date.now() - 30 * 24 * 3600 * 1000).getTime();
    const to = req.query.to ? new Date(req.query.to).getTime() : Date.now();
    const loans = reportService.loansBetween(from, to);
    const csv = reportService.toLoansCsv(loans);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="iulms_loans_${from}_${to}.csv"`);
    res.send(csv);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
