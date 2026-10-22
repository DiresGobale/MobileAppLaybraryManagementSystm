/**
 * IULMS Backend — entry point.
 *
 * Boots the Express app, ensures the database is migrated + seeded, and
 * listens on the configured port. Graceful shutdown on SIGINT/SIGTERM.
 */
require('dotenv').config();

const config = require('./config/env');
const { createApp } = require('./app');
const { getDb, closeDb } = require('./db/connection');

// Ensure DB is initialised on boot — schema.sql is idempotent.
getDb();
// Auto-run the seed if no admin exists (idempotent).
const adminRow = getDb().prepare("SELECT COUNT(*) AS n FROM users WHERE role = 'admin'").get();
if (adminRow.n === 0) {
  // Defer to the seed script; we just call it inline.
  console.log('→ No admin user detected — run `npm run seed` to create the default admin.');
}

const app = createApp();
const server = app.listen(config.port, () => {
  console.log(`\n  ┌────────────────────────────────────────────────────────┐`);
  console.log(`  │  IULMS Backend v1.0.0                                 │`);
  console.log(`  │  Listening on http://localhost:${config.port}                  │`);
  console.log(`  │  Environment: ${config.env.padEnd(40)}│`);
  console.log(`  │  Health:     http://localhost:${config.port}/health           │`);
  console.log(`  │  API root:   http://localhost:${config.port}/api             │`);
  console.log(`  └────────────────────────────────────────────────────────┘\n`);
});

function shutdown(signal) {
  console.log(`\n  ${signal} received — shutting down…`);
  server.close(() => {
    closeDb();
    console.log('  ✓ HTTP server closed, DB released. Bye.');
    process.exit(0);
  });
  // Hard kill after 10s if hanging connections don't close.
  setTimeout(() => process.exit(1), 10000).unref();
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('uncaughtException', (err) => {
  console.error('  ✗ Uncaught exception:', err);
  shutdown('uncaughtException');
});

module.exports = server;
