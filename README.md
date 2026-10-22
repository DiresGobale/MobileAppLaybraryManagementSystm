# IULMS Backend — Node.js + Express

Production-grade REST API for the **Injibara University Library Management System**. Built
with Node.js, Express, and SQLite (via `better-sqlite3`). Provides JWT authentication,
role-based access control (Admin / Librarian / Student), transactional loan workflows,
activity logging, CSV reports, and a complete REST API consumed by the Flutter mobile app.

This is the **real** backend — every endpoint reads from and writes to a real database
with foreign-key enforcement, CHECK constraints, transactions, and audit logging. No
mocks, no in-memory stubs.

---

## Features

| Area | Highlights |
|------|------------|
| **Auth** | JWT (7-day tokens), bcrypt password hashing (10 salt rounds), login by username or email, role-gated routes, profile + password change |
| **Users** | CRUD with role-based access — admin can create/deactivate/reactivate/delete users; students can self-register (toggle-able via settings) |
| **Books** | CRUD with ISBN uniqueness, search by title/author/ISBN/category, availability filter, delete-guard when active loans exist, inventory consistency maintained |
| **Loans** | Transactional issue/return with atomic CAS on `available_quantity` — borrowing limits enforced, overdue reconciliation, due-date tracking, double-return prevention |
| **Categories** | Full CRUD with delete-protection when books are still assigned |
| **Notifications** | Auto-generated on issue/return; per-user inbox with unread badge; mark-read + mark-all-read; delete |
| **Activity Log** | 27 action types logged with actor id — full audit trail; filterable by action and "mine only" |
| **Reports** | Inventory summary, popular books, overdue list, borrowing activity by date range, CSV export |
| **Landing Page Content** | `library_services`, `library_steps`, `contact_messages` tables — admin can edit via API; visitors can submit contact messages |
| **Settings** | Persisted in `settings` table — loan days, max active loans, self-registration toggle, voice nav toggle, all contact info, mission/vision/history |
| **Security** | Helmet, CORS allow-list, rate limiting (production), input validation via express-validator, parameterised queries throughout |
| **Observability** | Morgan HTTP logging (dev=combined), all DB queries logged in dev mode, structured errors with codes |

---

## Architecture

```
src/
├── config/
│   ├── env.js           # Environment loader with safe defaults
│   └── constants.js     # Roles, action keys, default settings/services/steps
├── db/
│   ├── connection.js    # better-sqlite3 wrapper (WAL, FK on, schema apply)
│   ├── schema.sql       # Full schema (10 tables, indexes, FKs, CHECKs)
│   ├── migrate.js       # `npm run migrate` — idempotent schema apply
│   └── seed.js          # `npm run seed` — default admin, categories, services, steps, settings
├── middleware/
│   ├── auth.js          # requireAuth — verifies Bearer JWT
│   ├── role.js          # requireRole / requireAdmin / ownerOrStaff
│   ├── validate.js      # express-validator result helper
│   └── errorHandler.js  # notFound + centralised error handler + AppError
├── models/              # Pure SQL data access (no business logic)
│   ├── userModel.js
│   ├── bookModel.js     # BookModel + CategoryModel
│   ├── loanModel.js
│   ├── auxModels.js     # NotificationModel + ActivityLogModel + SettingModel
│   └── libraryModels.js # LibraryServiceModel + LibraryStepModel + ContactMessageModel
├── services/            # Business logic — transactions, validation, logging
│   ├── authService.js
│   ├── bookService.js
│   ├── loanService.js   # Transactional issue/return with CAS on available_quantity
│   ├── libraryInfoService.js
│   ├── reportService.js
│   └── auxServices.js   # NotificationService + ActivityLogService
├── controllers/         # (Logic kept inline in routes for compactness — see routes/)
├── routes/
│   ├── index.js         # Mounts /api/auth, /api/books, /api/loans, /api, /api/reports
│   ├── authRoutes.js
│   ├── bookRoutes.js
│   ├── loanRoutes.js
│   ├── libraryRoutes.js # notifications, activity log, admin library info, contact inbox
│   └── reportRoutes.js
├── utils/
│   ├── hash.js          # bcrypt wrapper
│   ├── jwt.js           # JWT sign + verify
│   └── csv.js           # RFC-4180 CSV serializer
├── app.js               # Express app builder (helmet, cors, morgan, rate limit)
└── server.js            # Boot + graceful shutdown
tests/
├── auth.test.js         # login / me / change password / etc.
└── books.test.js        # book CRUD, loans, duplicate ISBN, role gate
docs/
└── API.md               # Full endpoint reference
```

---

## Quick start

```bash
# 1. Install dependencies
npm install

# 2. Copy env template + tweak secrets
cp .env.example .env
# Edit .env — set JWT_SECRET and DEFAULT_ADMIN_PASSWORD

# 3. Run migrations + seed default data + default admin
npm run setup        # = npm run migrate && npm run seed

# 4. Start the server
npm start            # or: npm run dev (with nodemon hot reload)
```

The server boots at **http://localhost:4000**. Health check: `GET /health`.

### Default admin credentials

```
username: admin
password: ChangeMe!2025    (or whatever you set in DEFAULT_ADMIN_PASSWORD)
email:    admin@injibara.edu
```

**Change the password immediately after first login** via `PATCH /api/auth/profile` or
`POST /api/auth/change-password`.

---

## API reference (short)

| Method | Path | Role | Description |
|--------|------|------|-------------|
| `GET`  | `/health` | public | Health probe |
| `POST` | `/api/auth/register` | public | Student self-registration |
| `POST` | `/api/auth/login` | public | Login (username or email) |
| `POST` | `/api/auth/logout` | auth | Logs the logout event |
| `GET`  | `/api/auth/me` | auth | Current user profile |
| `POST` | `/api/auth/change-password` | auth | Change own password |
| `PATCH`| `/api/auth/profile` | auth | Update own profile |
| `GET`  | `/api/auth/users` | librarian+ | List users (optional `?role=` filter) |
| `POST` | `/api/auth/users` | admin | Create any role account |
| `PATCH`| `/api/auth/users/:id/deactivate` | admin | Soft-deactivate user |
| `PATCH`| `/api/auth/users/:id/reactivate` | admin | Reactivate user |
| `DELETE`| `/api/auth/users/:id` | admin | Hard-delete user |
| `GET`  | `/api/books` | auth | Search books (`?q=&categoryId=&availableOnly=`) |
| `GET`  | `/api/books/:id` | auth | Book detail |
| `POST` | `/api/books` | librarian+ | Add book |
| `PATCH`| `/api/books/:id` | librarian+ | Update book |
| `DELETE`| `/api/books/:id` | librarian+ | Delete book (blocks if active loans) |
| `GET`  | `/api/books/categories/all` | auth | List categories |
| `POST` | `/api/books/categories` | librarian+ | Add category |
| `PATCH`| `/api/books/categories/:id` | librarian+ | Update category |
| `DELETE`| `/api/books/categories/:id` | librarian+ | Delete category (blocks if books assigned) |
| `GET`  | `/api/books/public/search` | public | Public catalog search (no auth) |
| `GET`  | `/api/books/public/inventory` | public | Public inventory totals |
| `GET`  | `/api/books/public/categories` | public | Public categories list |
| `GET`  | `/api/loans/my` | auth | Current user's active + history loans |
| `GET`  | `/api/loans` | librarian+ | All loans (recent) |
| `GET`  | `/api/loans/overdue` | librarian+ | Overdue loans |
| `GET`  | `/api/loans/book/:bookId` | auth | Active loans for a book |
| `POST` | `/api/loans/issue` | librarian+ | Issue book (transactional) |
| `POST` | `/api/loans/return` | librarian+ | Return loan (transactional) |
| `GET`  | `/api/notifications` | auth | User's notifications + unread count |
| `PATCH`| `/api/notifications/:id/read` | auth | Mark one read |
| `PATCH`| `/api/notifications/read-all` | auth | Mark all read |
| `DELETE`| `/api/notifications/:id` | auth | Delete notification |
| `GET`  | `/api/activity-log` | auth | Activity log (admins see all, students own only) |
| `GET`  | `/api/public/info` | public | Landing page content (services + steps + contact info) |
| `POST` | `/api/public/contact` | public | Submit a contact message (no auth) |
| `GET`  | `/api/admin/services` | librarian+ | All services (incl. inactive) |
| `POST` | `/api/admin/services` | admin | Create service |
| `PATCH`| `/api/admin/services/:id` | admin | Update service |
| `DELETE`| `/api/admin/services/:id` | admin | Delete service |
| `GET`  | `/api/admin/steps` | librarian+ | All steps |
| `POST` | `/api/admin/steps` | admin | Create step |
| `PATCH`| `/api/admin/steps/:id` | admin | Update step |
| `DELETE`| `/api/admin/steps/:id` | admin | Delete step |
| `GET`  | `/api/admin/contact-inbox` | librarian+ | List contact messages |
| `PATCH`| `/api/admin/contact-inbox/:id/handled` | librarian+ | Mark handled |
| `DELETE`| `/api/admin/contact-inbox/:id` | admin | Delete message |
| `GET`  | `/api/admin/info` | librarian+ | Library info (mission, vision, contact, etc.) |
| `PATCH`| `/api/admin/info` | admin | Update library info settings |
| `GET`  | `/api/reports/dashboard` | auth | Dashboard stats + inventory summary + activity-today count |
| `GET`  | `/api/reports/inventory` | librarian+ | Inventory summary |
| `GET`  | `/api/reports/popular` | auth | Most-borrowed books |
| `GET`  | `/api/reports/overdue` | librarian+ | Overdue loans |
| `GET`  | `/api/reports/loans?from=&to=` | librarian+ | Loans in a date range |
| `GET`  | `/api/reports/loans.csv?from=&to=` | librarian+ | Same loans as CSV download |

See **docs/API.md** for request/response examples.

---

## Authentication

Send the JWT returned by `/api/auth/login` or `/api/auth/register` as a Bearer token:

```http
GET /api/auth/me
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

Tokens expire after 7 days by default (`JWT_EXPIRES_IN`). On expiry, the client
must call `/api/auth/login` again.

---

## Tests

```bash
npm test
```

Tests use an in-memory SQLite database (no disk file, no shared state). Coverage:

- `auth.test.js` — login by username/email, wrong password, unknown user, `/me` 401 without token
- `books.test.js` — book creation, duplicate ISBN rejection (409), student 403 on create,
  public search without auth, book detail with category join, update, delete-block when
  active loans exist (409), librarian issue loan, double-issue out-of-stock 409

---

## Database

- **Engine**: SQLite via `better-sqlite3` (synchronous, fast, no native event loop).
- **Schema**: see `src/db/schema.sql` (10 tables, indexes, FK constraints, CHECK constraints).
- **Migrations**: idempotent — `npm run migrate` runs `CREATE TABLE IF NOT EXISTS` for every table.
- **Seed**: `npm run seed` populates default categories, library services, library steps,
  settings, and creates the default admin if none exists.
- **Production**: swap to PostgreSQL by changing `DATABASE_PATH` to a `DATABASE_URL` and
  replacing the `better-sqlite3` driver with `pg`. The schema is PostgreSQL-compatible.

### Schema summary

| Table | Purpose |
|-------|---------|
| `users` | id, full_name, username (UNIQUE), email (UNIQUE), password_hash (bcrypt), role, student_id, department, created_at, is_active |
| `categories` | id, name (UNIQUE), description |
| `books` | id, isbn (UNIQUE), title, author, category_id, publisher, year, edition, shelf_location, description, total_quantity, available_quantity (CHECK ≤ total), cover_path, timestamps |
| `loans` | id, user_id, book_id, issued_by, issue_date, due_date, return_date, status (active/returned/overdue) |
| `notifications` | id, user_id, title, message, created_at, is_read |
| `activity_logs` | id, user_id (nullable for system actions), action, details, created_at |
| `settings` | id, setting_key (UNIQUE), setting_value |
| `library_services` | id, title, description, icon_name, display_order, is_active |
| `library_steps` | id, step_number, title, description, icon_name, display_order, is_active |
| `contact_messages` | id, name, email, subject, message, submitted_at, is_handled |

Foreign keys are enforced (`PRAGMA foreign_keys = ON`). Activity logs reference users
with `ON DELETE SET NULL` (preserves audit trail when users are hard-deleted). Loans
reference users and books with `ON DELETE RESTRICT` (prevents deleting a user/book with
active loans).

---

## Loan workflow (transactional)

The loan issue/return flow is the heart of the system. Both run inside a single
`better-sqlite3` transaction:

```
issue(userId, bookId, librarianId, overrideLoanDays?):
  1. Reconcile overdue loans (active → overdue where due_date < now)
  2. Verify user exists + is_active
  3. Verify book exists + available_quantity > 0
  4. Check student's active loan count < max (default 3)
  5. CAS decrement available_quantity (UPDATE … WHERE available_quantity > 0)
     - If 0 rows affected → throw "Inventory race" 409
  6. INSERT loan row (status=active)
  7. INSERT notification (title="Book Issued", message includes due date)
  8. INSERT activity_log (action=loan_issue, user_id=librarianId)
  → returns loan row

returnLoan(loanId, librarianId):
  1. Verify loan exists
  2. If already returned → throw 409 ALREADY_RETURNED
  3. UPDATE loan SET status=returned, return_date=now WHERE id=? AND status!=returned
     - If 0 rows affected → throw 409
  4. UPDATE books SET available_quantity = MIN(available_quantity+1, total_quantity)
  5. INSERT notification (title="Book Returned")
  6. INSERT activity_log (action=loan_return)
  → returns updated loan row
```

Any exception inside the transaction rolls back ALL changes — no partial state.

---

## CSV export

`GET /api/reports/loans.csv?from=2025-01-01&to=2025-12-31` returns a CSV file
download with these columns:

```
loan_id,user,student_id,book_title,isbn,author,issued_by,issue_date,due_date,return_date,status
1,Dawit Kebede,LIB/2025/100,Introduction to Algorithms,978-0262033848,Cormen et al.,Selam Bekele,2025-10-23T15:42:00.000Z,2025-11-06T15:42:00.000Z,,active
```

CSV values are RFC-4180 compliant — fields containing commas, quotes, or newlines are
wrapped in double-quotes (with internal quotes doubled).

---

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `4000` | HTTP port |
| `NODE_ENV` | `development` | Sets prod/dev behaviour (rate limiting, morgan format, error stack exposure) |
| `DATABASE_PATH` | `./data/iulms.db` | SQLite file path. Use `:memory:` for tests |
| `JWT_SECRET` | (insecure dev default) | **Set this in production** — min 32 random chars |
| `JWT_EXPIRES_IN` | `7d` | Token lifetime |
| `JWT_ISSUER` | `iulms-backend` | Token issuer claim |
| `CORS_ALLOWED_ORIGINS` | `*` | Comma-separated list of allowed origins for browser clients |
| `RATE_LIMIT_WINDOW_MS` | `900000` | Rate limit window (15 min default) |
| `RATE_LIMIT_MAX` | `300` | Max requests per window per IP |
| `DEFAULT_ADMIN_*` | (see .env.example) | Only used by `npm run seed` to create the first admin |
| `LOG_LEVEL` | `info` | Logging verbosity |

---

## Production deployment

### Option A — bare-metal / VPS

```bash
git clone https://github.com/DiresGobale/MobileAppLaybraryManagementSystm.git
cd MobileAppLaybraryManagementSystm/iulms-backend
npm ci --omit=dev
cp .env.example .env  # edit secrets
npm run setup
NODE_ENV=production node src/server.js
```

Run behind Nginx or Caddy as a reverse proxy with TLS.

### Option B — Docker

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN mkdir -p data
EXPOSE 4000
CMD ["node", "src/server.js"]
```

Build + run:
```bash
docker build -t iulms-backend .
docker run -d -p 4000:4000 -v $(pwd)/data:/app/data --env-file .env iulms-backend
```

### Option C — PM2 (process manager)

```bash
npm install -g pm2
pm2 start src/server.js --name iulms-backend --env production
pm2 save && pm2 startup
```

---

## License

MIT — Injibara University internal academic project.
