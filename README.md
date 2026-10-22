# Injibara University Library Management System (IULMS)

A complete, modern Flutter mobile application for Injibara University (Ethiopia) that digitizes library
operations: book inventory management, student borrowing/return tracking, role-based access for
administrators, librarians, and students, plus notifications and reports.

The application uses **Flutter + Dart** with a local **SQLite** database via the `sqflite` package,
**Provider** for state management, and **Material Design 3** for the UI with a polished academic
theme inspired by classical university branding (deep navy, academic gold, cream surfaces).

---

## 1. Features

| Area | Highlights |
|------|------------|
| Authentication | Local login + registration, password hashing (SHA-256 + per-user salt), role-based access |
| Roles | Administrator, Librarian, Student — enforced at UI + service layer |
| Dashboard | Role-specific stats computed from real DB records (totals, available, borrowed, overdue, recent activity) |
| Books | Full CRUD, ISBN uniqueness, search (title/author/ISBN/category), availability labels, prevent deletion with active loans |
| Loans | Issue/return workflow with DB transactions, due dates, overdue detection, borrowing limits |
| Students | Browse catalog, view availability, see own loans + history, profile editing |
| Notifications | In-app notification center (due soon, overdue, return confirmations) |
| Reports | Inventory summary, popular books, borrowing activity, CSV export |
| Migrations | Versioned schema, FK enforcement, parameterized queries |

---

## 2. Offline vs. Server-based Features

| Works offline (current) | Requires future backend |
|--------------------------|-------------------------|
| All local data (books, loans, users) | Cross-device sync |
| Local authentication (this device only) | Multi-device secure authentication |
| In-app notifications stored locally | Push notifications |
| CSV export to local storage | Cloud report storage / sharing |
| Single-device library prototype | Multi-user concurrent access across phones |

> **Note:** Because SQLite is local to the device, this prototype does **not** provide secure
> multi-user access across different phones. Production deployment requires a server-side
> authentication service and a shared backend database.

---

## 3. Prerequisites

- Flutter SDK `>= 3.13.0` (Dart `>= 3.0.0`)
- Android Studio or VS Code with Flutter/Dart plugins
- An Android emulator (API 21+) or a physical Android device (USB debugging enabled)
- (For desktop/tests) `sqflite_common_ffi` is included in `dev_dependencies` so unit tests run on the host machine

---

## 4. Installation & Setup

```bash
# 1. Clone or copy this project folder
cd iulms

# 2. Fetch dependencies
flutter pub get

# 3. Run code generation (none required — pure Dart)

# 4. Run the app
flutter run
```

### First Administrator Setup

On the very first launch, the database initializes empty. To create the first administrator,
run the included setup helper:

```bash
dart run lib/utils/first_admin_setup.dart
```

You will be prompted for an admin username, full name, email, and password. The script hashes the
password with a random per-user salt and inserts the record into the local `users` table.

Alternatively, the **Login** screen detects an empty user table and offers a one-time
"Initialize Administrator" link that walks the user through the same setup on-device.

> Never hardcode a production password. The setup flow generates a fresh salt per user.

---

## 5. Project Structure

```
lib/
  main.dart
  models/         # Data classes (User, Book, Category, Loan, etc.)
  database/       # DatabaseHelper, schema, migrations
  repositories/   # SQL data-access layer (no UI imports)
  services/       # Business logic (auth, book, loan, notification, report)
  providers/      # ChangeNotifiers for state management
  screens/        # UI: splash, login, dashboard, books, loans, admin
  widgets/        # Reusable widgets: stat cards, book cards, dialogs
  utils/          # Theme, constants, validators, hash utils
  routes/         # Named route configuration
test/             # Unit + widget tests
```

---

## 6. Database Schema

| Table | Key Fields |
|-------|-----------|
| users | id, full_name, username, email, password_hash, password_salt, role, student_id, department, created_at, is_active |
| books | id, isbn (UNIQUE), title, author, category_id, publisher, publication_year, edition, shelf_location, description, total_quantity, available_quantity, cover_path, created_at, updated_at |
| categories | id, name (UNIQUE), description |
| loans | id, user_id, book_id, issued_by, issue_date, due_date, return_date, status |
| notifications | id, user_id, title, message, created_at, is_read |
| activity_logs | id, user_id, action, details, created_at |
| settings | id, setting_key (UNIQUE), setting_value |

Foreign-key enforcement is enabled via `PRAGMA foreign_keys = ON`. All multi-row mutations
use database transactions.

---

## 7. Running Tests

```bash
flutter test
```

Tests cover database CRUD, duplicate-ISBN prevention, loan issuance, return processing,
inventory consistency, overdue calculations, and the login widget.

---

## 8. Configuration

Default settings (seeded on first run, editable in **Admin → Settings**):

| Key | Default | Description |
|-----|---------|-------------|
| `default_loan_days` | `14` | Borrowing period |
| `max_active_loans` | `3` | Per-student concurrent loans |
| `enable_self_registration` | `true` | Allow students to sign up |
| `library_name` | `Injibara University Library` | Branding |

### CSV Export & Android Storage

The Reports screen exports loan activity as CSV using `getApplicationDocumentsDirectory()`
from the `path_provider` package. This writes to **app-scoped storage** on Android 10+
(API 29+) — files live at `/data/data/<package>/files/` and **do not require any runtime
storage permission** for app-private use.

After saving, the file is passed to the system share sheet via `share_plus`, so the
user can send it via email, save to Downloads, or open in another app. This is the
recommended approach for scoped storage on modern Android.

If you need to write directly to the public Downloads directory (legacy behavior),
add this permission and request it at runtime before the write call:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                 android:maxSdkVersion="28" />
```

The full manifest template is provided at `android/app/src/main/AndroidManifest.xml`.

---

## 9. Backend Integration (Node.js + Express)

This Flutter app ships in **dual-mode** — it can run standalone using on-device
SQLite (LOCAL mode) OR connect to a Node.js + Express backend over HTTP (REMOTE
mode). The mode is configurable at runtime via **Admin → Settings → Backend
Connection**.

### Architecture

```
┌────────────────────────┐         ┌─────────────────────────────────┐
│  Flutter mobile app    │         │  Node.js backend (Express)       │
│  (this repo)           │         │  (branch: backend on GitHub)     │
│                        │         │                                  │
│  AuthProvider          │  HTTP   │  /api/auth/*      (JWT + bcrypt)  │
│  BookProvider  ←──────→│  JSON   │  /api/books/*     (CRUD + search) │
│  LoanProvider          │         │  /api/loans/*     (transactional)│
│  NotificationProvider  │         │  /api/notifications/*             │
│  DashboardProvider     │         │  /api/reports/*   (dashboard+CSV) │
│  LandingProvider       │         │  /api/public/info (landing page) │
│                        │         │  /api/admin/*     (services/steps)│
│  ┌──────────────────┐ │         │  ┌─────────────────────────────┐ │
│  │ LOCAL: SQLite    │ │         │  │ better-sqlite3 · WAL mode    │ │
│  │ (sqflite)        │ │         │  │ 10 tables · FK · CHECK       │ │
│  │ OR               │ │         │  │ + Helmet · CORS · Rate limit │ │
│  │ REMOTE: HTTP     │ │         │  │ + Activity logging (27 types)│ │
│  │ (http package)   │ │         │  │ + JWT auth + role middleware │ │
│  └──────────────────┘ │         │  └─────────────────────────────┘ │
└────────────────────────┘         └─────────────────────────────────┘
```

### How to switch modes

1. **Admin → Settings → Backend Connection**
2. Toggle "Use remote Node.js backend"
3. Set the backend URL (default `http://10.0.2.2:4000` for Android emulator,
   `http://192.168.x.x:4000` for a real device on the same Wi-Fi)
4. Tap "Test" to verify connectivity
5. Save → relaunch the app for the new mode to take effect

### Running the backend

```bash
git clone -b backend https://github.com/DiresGobale/MobileAppLaybraryManagementSystm.git iulms-backend
cd iulms-backend
cp .env.example .env
npm install
npm run setup     # migrate + seed default admin
npm start         # listens on http://localhost:4000
```

Default admin: `admin` / `ChangeMe!2025` (change immediately after first login).

### Files added for integration

| File | Purpose |
|------|---------|
| `lib/utils/backend_config.dart` | Singleton holding the active mode + backend URL (persisted in SharedPreferences) |
| `lib/services/api_client.dart` | HTTP wrapper with JWT storage, JSON encode/decode, error → ApiException mapping |
| `lib/services/remote_services.dart` | 6 remote service classes mirroring the local ones (RemoteAuthService, RemoteBookService, RemoteLoanService, RemoteNotificationService, RemoteReportService, RemoteLibraryInfoService) |
| `lib/providers/data_source_provider.dart` | ChangeNotifier for mode + URL + live connectivity status |
| `lib/routes/app_routes.dart` (updated) | Wires either local or remote services into the Provider tree based on `BackendConfig.mode` |
| `lib/screens/admin/settings_screen.dart` (updated) | New "Backend Connection" section with toggle, URL field, and live connection status |
| `lib/screens/dashboard_screen.dart` (updated) | Shows a LOCAL / BACKEND / OFFLINE badge next to the signed-in label |
| `android/app/src/main/AndroidManifest.xml` (updated) | Declares INTERNET permission + allows cleartext HTTP to localhost/10.0.2.2/192.168.x |
| `android/app/src/main/res/xml/network_security_config.xml` | Allows cleartext HTTP for dev IPs (disabled in production) |

### What works in REMOTE mode

Every screen that previously read/wrote local SQLite now talks to the backend:
- ✅ Login + register (JWT stored in SharedPreferences)
- ✅ User CRUD (admin)
- ✅ Book CRUD + search
- ✅ Loan issue/return (transactional — backend uses CAS on `available_quantity`)
- ✅ Notifications (auto-generated on backend issue/return)
- ✅ Reports + CSV export
- ✅ Activity log (role-scoped)
- ✅ Landing page (services + steps + contact form)
- ✅ Library Info Editor (admin can edit landing page content remotely)

---

## 10. License

Internal academic project — Injibara University. For educational use.
