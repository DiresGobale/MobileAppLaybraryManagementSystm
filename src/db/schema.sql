-- ============================================================================
--  IULMS — SQLite schema (also PostgreSQL-compatible; types use INTEGER for
--  booleans and ISO strings are stored as milliseconds-since-epoch integers).
--  Foreign-key enforcement MUST be enabled per-connection:
--    SQLite:  PRAGMA foreign_keys = ON;
--    Postgres: ON by default.
-- ============================================================================

-- ----------------------------- users -----------------------------
CREATE TABLE IF NOT EXISTS users (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  full_name       TEXT    NOT NULL,
  username        TEXT    NOT NULL UNIQUE,
  email           TEXT    NOT NULL UNIQUE,
  password_hash   TEXT    NOT NULL,
  role            TEXT    NOT NULL CHECK (role IN ('admin','librarian','student')),
  student_id      TEXT,
  department      TEXT,
  created_at      INTEGER NOT NULL,
  is_active       INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_users_role       ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_student_id ON users(student_id);

-- --------------------------- categories --------------------------
CREATE TABLE IF NOT EXISTS categories (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL UNIQUE,
  description TEXT
);

-- ----------------------------- books -----------------------------
CREATE TABLE IF NOT EXISTS books (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  isbn               TEXT    NOT NULL UNIQUE,
  title              TEXT    NOT NULL,
  author             TEXT    NOT NULL,
  category_id        INTEGER,
  publisher          TEXT,
  publication_year   INTEGER,
  edition            TEXT,
  shelf_location     TEXT,
  description        TEXT,
  total_quantity     INTEGER NOT NULL CHECK (total_quantity >= 0),
  available_quantity INTEGER NOT NULL CHECK (available_quantity >= 0),
  cover_path         TEXT,
  created_at         INTEGER NOT NULL,
  updated_at         INTEGER NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON UPDATE CASCADE ON DELETE SET NULL,
  CHECK (available_quantity <= total_quantity)
);
CREATE INDEX IF NOT EXISTS idx_books_title    ON books(title);
CREATE INDEX IF NOT EXISTS idx_books_author   ON books(author);
CREATE INDEX IF NOT EXISTS idx_books_category ON books(category_id);

-- ----------------------------- loans -----------------------------
CREATE TABLE IF NOT EXISTS loans (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id     INTEGER NOT NULL,
  book_id     INTEGER NOT NULL,
  issued_by   INTEGER NOT NULL,
  issue_date  INTEGER NOT NULL,
  due_date    INTEGER NOT NULL,
  return_date INTEGER,
  status      TEXT    NOT NULL CHECK (status IN ('active','returned','overdue')),
  FOREIGN KEY (user_id)   REFERENCES users(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (book_id)   REFERENCES books(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (issued_by) REFERENCES users(id) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS idx_loans_user   ON loans(user_id);
CREATE INDEX IF NOT EXISTS idx_loans_book   ON loans(book_id);
CREATE INDEX IF NOT EXISTS idx_loans_status ON loans(status);

-- ------------------------- notifications ------------------------
CREATE TABLE IF NOT EXISTS notifications (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id     INTEGER NOT NULL,
  title       TEXT    NOT NULL,
  message     TEXT    NOT NULL,
  created_at  INTEGER NOT NULL,
  is_read     INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);

-- ------------------------- activity_logs ------------------------
CREATE TABLE IF NOT EXISTS activity_logs (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id     INTEGER,
  action      TEXT    NOT NULL,
  details     TEXT,
  created_at  INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_logs_user    ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_logs_created ON activity_logs(created_at);

-- --------------------------- settings --------------------------
CREATE TABLE IF NOT EXISTS settings (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  setting_key   TEXT    NOT NULL UNIQUE,
  setting_value TEXT    NOT NULL
);

-- ----------------------- library_services ----------------------
CREATE TABLE IF NOT EXISTS library_services (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  title         TEXT    NOT NULL,
  description  TEXT    NOT NULL,
  icon_name     TEXT    NOT NULL DEFAULT 'menu_book',
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active     INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_services_order ON library_services(display_order);

-- -------------------------- library_steps ----------------------
CREATE TABLE IF NOT EXISTS library_steps (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  step_number   INTEGER NOT NULL,
  title         TEXT    NOT NULL,
  description   TEXT    NOT NULL,
  icon_name     TEXT    NOT NULL DEFAULT 'search',
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active     INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_steps_order ON library_steps(display_order);

-- ---------------------- contact_messages ----------------------
CREATE TABLE IF NOT EXISTS contact_messages (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT    NOT NULL,
  email         TEXT    NOT NULL,
  subject       TEXT    NOT NULL,
  message       TEXT    NOT NULL,
  submitted_at  INTEGER NOT NULL,
  is_handled    INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_contact_submitted ON contact_messages(submitted_at);
