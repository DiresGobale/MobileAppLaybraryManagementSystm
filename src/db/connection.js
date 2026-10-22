const path = require('path');
const fs = require('fs');
const Database = require('better-sqlite3');
const config = require('../config/env');

let _db = null;

/**
 * Opens (and lazily creates) the SQLite database file. The same Database
 * instance is reused for the lifetime of the process — better-sqlite3
 * is synchronous and thread-safe per connection.
 *
 * The schema is applied on first open. Foreign-key enforcement is on.
 */
function getDb() {
  if (_db) return _db;

  // Ensure the data directory exists.
  const dir = path.dirname(config.databasePath);
  fs.mkdirSync(dir, { recursive: true });

  _db = new Database(config.databasePath, {
    fileMustExist: false,
    verbose: config.isProd ? undefined : (msg) => console.debug('[sql]', msg),
  });

  // FK enforcement is per-connection in SQLite.
  _db.pragma('journal_mode = WAL');
  _db.pragma('foreign_keys = ON');

  // Apply schema (idempotent — uses CREATE TABLE IF NOT EXISTS).
  const schemaPath = path.join(__dirname, 'schema.sql');
  const schemaSql = fs.readFileSync(schemaPath, 'utf8');
  _db.exec(schemaSql);

  return _db;
}

/**
 * Closes the DB connection — used by tests and graceful shutdown.
 */
function closeDb() {
  if (_db) {
    _db.close();
    _db = null;
  }
}

/**
 * Convenience helper: runs the given function inside a transaction.
 * better-sqlite3 transactions are synchronous, so exceptions propagate
 * naturally and the transaction is rolled back automatically.
 *
 *   const result = tx(db => db.prepare(...).get(...));
 */
function tx(fn) {
  const db = getDb();
  return db.transaction(fn)(db);
}

module.exports = { getDb, closeDb, tx };
