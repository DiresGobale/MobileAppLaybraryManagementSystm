# IULMS Backend API Reference

Base URL (dev): `http://localhost:4000`

## Authentication

All authenticated endpoints expect a Bearer JWT in the `Authorization` header:

```
Authorization: Bearer <token>
```

Tokens are obtained from `POST /api/auth/login` or `POST /api/auth/register` and last 7 days
by default. On expiry, the response is `401 { code: 'TOKEN_EXPIRED' }`.

## Roles

- `admin` — full access (users, books, loans, settings, library info, contact inbox, reports)
- `librarian` — manage books, loans, categories, contact inbox; cannot manage users or settings
- `student` — browse catalog, view own loans, manage own profile + password, submit contact messages

---

## Auth endpoints

### POST `/api/auth/register`

Public. Student self-registration. Disabled when `enable_self_registration = false`.

**Body**:
```json
{
  "fullName": "Dawit Kebede",
  "username": "dawit.k",
  "email": "dawit@injibara.edu",
  "password": "secret123",
  "studentId": "LIB/2025/100",
  "department": "Computer Science"
}
```

**Response** (201):
```json
{
  "user": { "id": 12, "username": "dawit.k", "role": "student", "fullName": "...", ... },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### POST `/api/auth/login`

Public. Login by username OR email.

**Body**:
```json
{ "identifier": "dawit.k", "password": "secret123" }
```

**Response** (200):
```json
{ "user": { ... }, "token": "..." }
```

**Errors**:
- `404 NOT_FOUND` — no account with that identifier
- `401 BAD_CREDENTIALS` — wrong password
- `403 INACTIVE` — account is deactivated

### GET `/api/auth/me`

Auth. Returns the current user (without `password_hash`).

### POST `/api/auth/change-password`

Auth. **Body**: `{ "currentPassword": "...", "newPassword": "..." }`
New password must be ≥ 6 chars.

### PATCH `/api/auth/profile`

Auth. Update own profile (partial). Fields: `fullName`, `email`, `department`.

### POST `/api/auth/logout`

Auth. Logs a `logout` activity log entry.

### User management (admin only)

- `GET /api/auth/users?role=student` — list users
- `POST /api/auth/users` — create any role account
- `PATCH /api/auth/users/:id/deactivate`
- `PATCH /api/auth/users/:id/reactivate`
- `DELETE /api/auth/users/:id` — hard delete (FK RESTRICT prevents if user has loan history)

---

## Books endpoints

### GET `/api/books?q=&categoryId=&availableOnly=`

Auth. Search the catalog. Joins categories to include `category_name`.

### GET `/api/books/:id`

Auth. Single book with category name.

### POST `/api/books`

Librarian+. **Body**:
```json
{
  "isbn": "978-0262033848",
  "title": "Introduction to Algorithms",
  "author": "Cormen et al.",
  "category_id": 1,
  "publisher": "MIT Press",
  "publication_year": 2022,
  "edition": "4th",
  "shelf_location": "A-12",
  "description": "Comprehensive algorithms textbook.",
  "total_quantity": 8,
  "available_quantity": 8,
  "cover_path": null
}
```

**Errors**: `409 ISBN_DUPLICATE`, `400 BAD_QTY`.

### PATCH `/api/books/:id`

Librarian+. Partial update — send only fields to change.

### DELETE `/api/books/:id`

Librarian+. Refuses with `409 BOOK_HAS_LOANS` if active loans reference it.

### Categories

- `GET /api/books/categories/all` (auth)
- `POST /api/books/categories` — librarian+, body: `{ "name": "...", "description": "..." }`
- `PATCH /api/books/categories/:id`
- `DELETE /api/books/categories/:id` — refuses if books are assigned (409 NOT_EMPTY)

### Public catalog (no auth)

- `GET /api/books/public/search?q=&categoryId=&availableOnly=`
- `GET /api/books/public/inventory` — totals only (titles, totalCopies, availableCopies, etc.)
- `GET /api/books/public/categories`

---

## Loans endpoints

### POST `/api/loans/issue`

Librarian+. **Body**: `{ "userId": 12, "bookId": 5, "overrideLoanDays": 21 }`

Transactional: reconciles overdue → checks user/book/limit → atomic decrement of
`available_quantity` → inserts loan row → inserts notification → inserts activity log.

**Errors**:
- `404 USER_NOT_FOUND` / `BOOK_NOT_FOUND`
- `409 NO_COPIES` — book has 0 available
- `409 LIMIT_EXCEEDED` — student already has max active loans
- `409 RACE` — another concurrent request grabbed the last copy

### POST `/api/loans/return`

Librarian+. **Body**: `{ "loanId": 87 }`

Transactional: marks loan returned → increments inventory (cap at total) → inserts
"Book Returned" notification → inserts `loan_return` activity log.

**Errors**: `404 LOAN_NOT_FOUND`, `409 ALREADY_RETURNED`.

### GET `/api/loans/my`

Auth. Returns `{ active: [...], history: [...] }` for the current user.

### GET `/api/loans`

Librarian+. Recent loans across all users.

### GET `/api/loans/overdue`

Librarian+. Reconciles overdue first, then lists.

### GET `/api/loans/book/:bookId`

Auth. Active loans for a specific book (used by Book Detail screen).

---

## Notifications endpoints

### GET `/api/notifications?unreadOnly=true`

Auth. Returns `{ items: [...], unreadCount: 7 }`.

### PATCH `/api/notifications/:id/read`

### PATCH `/api/notifications/read-all`

### DELETE `/api/notifications/:id`

---

## Activity log

### GET `/api/activity-log?limit=200&mineOnly=false`

Auth. Returns activity log entries joined with the actor's name + role.
- Admins and librarians see all entries by default.
- Students see only their own entries (server-enforced).
- Filter by `mineOnly=true` for staff to see only their own.

Each entry has: `id`, `user_id`, `action`, `details`, `created_at`,
`actor_name`, `actor_username`, `actor_role`.

---

## Library info / landing page content

### GET `/api/public/info`

Public. Returns the aggregate needed by the Flutter landing page:
```json
{
  "info": { "libraryName": "...", "tagline": "...", "mission": "...", ... },
  "services": [{ "id": 1, "title": "Book Borrowing", ... }, ...],
  "steps": [{ "id": 1, "step_number": 1, "title": "Browse the Catalog", ... }, ...]
}
```

### POST `/api/public/contact`

Public. Submit a contact message. **Body**:
```json
{
  "name": "Bekele Tadesse",
  "email": "bekele@injibara.edu",
  "subject": "Question about borrowing limits",
  "message": "Can I borrow 4 books at once for my thesis?"
}
```

Logs a `contact_received` activity entry so admins see new messages in the audit trail.

### Admin: services CRUD

- `GET /api/admin/services` (librarian+) — includes inactive
- `POST /api/admin/services` (admin) — body: `{ title, description, icon_name, display_order }`
- `PATCH /api/admin/services/:id` (admin)
- `DELETE /api/admin/services/:id` (admin)

### Admin: steps CRUD

- `GET /api/admin/steps` (librarian+)
- `POST /api/admin/steps` (admin) — body: `{ step_number, title, description, icon_name, display_order }`
- `PATCH /api/admin/steps/:id` (admin)
- `DELETE /api/admin/steps/:id` (admin)

### Admin: contact inbox

- `GET /api/admin/contact-inbox?unhandledOnly=true` (librarian+)
- `PATCH /api/admin/contact-inbox/:id/handled` (librarian+)
- `DELETE /api/admin/contact-inbox/:id` (admin)

### Admin: library info settings

- `GET /api/admin/info` (librarian+) — returns the `LibraryContactInfo` aggregate
- `PATCH /api/admin/info` (admin) — body: any subset of `{ library_tagline, library_mission, library_vision, library_history, library_email, library_phone, library_address, library_hours, library_facebook, library_twitter, library_instagram, library_name }`

---

## Reports

### GET `/api/reports/dashboard`

Auth. Returns dashboard stats (book totals, students, loans, overdue, etc.) +
inventory summary + `activityToday` count + recent loans.

### GET `/api/reports/inventory`

Librarian+. Inventory summary:
```json
{
  "totalTitles": 248,
  "totalCopies": 475,
  "availableCopies": 412,
  "borrowedCopies": 63,
  "outOfStockTitles": 3,
  "categories": 10
}
```

### GET `/api/reports/popular?limit=10`

Auth. Top-borrowed books, sorted by loan count.

### GET `/api/reports/overdue`

Librarian+. Overdue loans list.

### GET `/api/reports/loans?from=2025-01-01&to=2025-12-31`

Librarian+. Loans issued in a date range.

### GET `/api/reports/loans.csv?from=...&to=...`

Librarian+. Same data as CSV file download. Content-Type: `text/csv`, with
`Content-Disposition: attachment; filename=...`.

---

## Error responses

All errors follow this shape:

```json
{
  "error": "Book not found",
  "code": "NOT_FOUND",
  "stack": ["..."]   // only in non-production
}
```

Common codes: `NO_TOKEN`, `TOKEN_EXPIRED`, `INVALID_TOKEN`, `INSUFFICIENT_ROLE`,
`NOT_OWNER`, `VALIDATION`, `NOT_FOUND`, `DUPLICATE`, `BAD_CREDENTIALS`, `INACTIVE`,
`FK_VIOLATION`, `CHECK_VIOLATION`, `BOOK_HAS_LOANS`, `NO_COPIES`, `LIMIT_EXCEEDED`,
`RACE`, `ALREADY_RETURNED`, `INTERNAL`.

HTTP status codes: `200` (success), `201` (created), `400` (validation), `401`
(auth), `403` (forbidden), `404` (not found), `409` (conflict), `500` (server).
