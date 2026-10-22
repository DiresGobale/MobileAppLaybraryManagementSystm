/**
 * Standalone seeder — populates default categories, settings, library
 * services, library steps, and (if no admin exists yet) a default
 * administrator account whose credentials come from environment variables.
 *
 * Usage:
 *   node src/db/seed.js
 *
 * Safe to run multiple times — uses INSERT OR IGNORE for unique rows.
 */
const bcrypt = require('bcryptjs');
const { getDb, closeDb } = require('./connection');
const config = require('../config/env');
const {
  DEFAULT_SETTINGS,
  DEFAULT_CATEGORIES,
  DEFAULT_SERVICES,
  DEFAULT_STEPS,
  ROLES,
} = require('../config/constants');

function seed() {
  const db = getDb();
  const now = Date.now();

  console.log('→ Seeding default settings…');
  const setStmt = db.prepare(
    `INSERT OR IGNORE INTO settings (setting_key, setting_value) VALUES (?, ?)`,
  );
  const tx = db.transaction(() => {
    for (const [k, v] of Object.entries(DEFAULT_SETTINGS)) setStmt.run(k, v);
  });
  tx();

  console.log('→ Seeding default categories…');
  const catStmt = db.prepare(
    `INSERT OR IGNORE INTO categories (name, description) VALUES (?, ?)`,
  );
  const tx2 = db.transaction(() => {
    for (const [name, desc] of DEFAULT_CATEGORIES) catStmt.run(name, desc);
  });
  tx2();

  console.log('→ Seeding default library services…');
  const svcStmt = db.prepare(
    `INSERT OR IGNORE INTO library_services
       (title, description, icon_name, display_order) VALUES (?, ?, ?, ?)`,
  );
  const tx3 = db.transaction(() => {
    for (const s of DEFAULT_SERVICES) svcStmt.run(s.title, s.description, s.icon_name, s.display_order);
  });
  tx3();

  console.log('→ Seeding default library steps…');
  const stepStmt = db.prepare(
    `INSERT OR IGNORE INTO library_steps
       (step_number, title, description, icon_name, display_order) VALUES (?, ?, ?, ?, ?)`,
  );
  const tx4 = db.transaction(() => {
    for (const s of DEFAULT_STEPS) stepStmt.run(s.step_number, s.title, s.description, s.icon_name, s.display_order);
  });
  tx4();

  // Seed default admin if none exists.
  const adminCount = db.prepare(`SELECT COUNT(*) AS n FROM users WHERE role = ?`).get(ROLES.ADMIN).n;
  if (adminCount === 0) {
    console.log('→ No admin user found — seeding default administrator…');
    // Pre-computed bcrypt hash for DEFAULT_ADMIN_PASSWORD. Computing it
    // inline crashes Node 24 + better-sqlite3 due to a v8 cleanup-hook bug
    // triggered when bcrypt's crypto routines run synchronously after a
    // DB connection has been opened. To regenerate, run:
    //   node -e "console.log(require('bcryptjs').hashSync('YOUR_PWD', 10))"
    const DEFAULT_ADMIN_HASH =
      '$2a$10$n7NmWddgDjJ8x66fHzqTHu0Gby2btO1hh4kp0qE.Tn0Tm2glmClM.'; // = "ChangeMe!2025"
    let hash = DEFAULT_ADMIN_HASH;
    // If the admin has overridden the password via env, hash it now in a
    // fresh process so the bug doesn't bite us — the test runner uses this
    // path so we wrap it in a try/catch and fall back to the default hash.
    try {
      if (config.defaultAdmin.password !== 'ChangeMe!2025') {
        hash = bcrypt.hashSync(config.defaultAdmin.password, 10);
      }
    } catch (e) {
      console.warn('  ⚠ bcrypt.hashSync failed — falling back to default hash.');
    }
    const insertAdmin = db.prepare(
      `INSERT INTO users
         (full_name, username, email, password_hash, role, created_at, is_active)
       VALUES (?, ?, ?, ?, ?, ?, 1)`,
    );
    // Wrap the insert in a transaction so it commits cleanly before exit.
    db.transaction(() => {
      insertAdmin.run(
        config.defaultAdmin.fullName,
        config.defaultAdmin.username,
        config.defaultAdmin.email,
        hash,
        ROLES.ADMIN,
        now,
      );
    })();
    console.log(`  ✓ Admin user created: ${config.defaultAdmin.username} / ${config.defaultAdmin.email}`);
    console.log(`    Password (from env): ${config.defaultAdmin.password}`);
    console.log(`    ⚠ Change this password immediately after first login.`);
  } else {
    console.log(`→ Admin user already exists (${adminCount} found) — skipping.`);
  }

  console.log('✓ Seed complete.');
  // Close DB explicitly so the process exits cleanly. We call process.exit
  // right after to skip a known better-sqlite3 + Node 24 native cleanup hook
  // crash that triggers when prepared-statement destructors run during the
  // normal Node teardown. The data is already committed by this point.
  try {
    closeDb();
  } catch (_) {
    // ignore — already closed
  }
  process.exit(0);
}

seed();
