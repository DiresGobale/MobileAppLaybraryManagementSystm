/**
 * Standalone migration runner: applies schema.sql to the configured DB.
 *
 * Usage:
 *   node src/db/migrate.js
 *
 * Safe to run multiple times — the schema uses `CREATE TABLE IF NOT EXISTS`.
 */
const { getDb, closeDb } = require('./connection');

console.log('→ Running migrations…');
const db = getDb();
console.log('  Schema applied successfully.');
console.log('  Database path:', db.name);
// Close + exit explicitly to skip a known better-sqlite3 + Node 24 native
// cleanup crash on prepared-statement destructors.
try {
  closeDb();
} catch (_) {}
process.exit(0);
