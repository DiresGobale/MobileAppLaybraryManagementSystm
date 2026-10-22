# IULMS — Build Log & Audit Notes

## Build 1 (initial)

- 58 Dart files + 2 test files, full feature-based architecture under `lib/`.
- DatabaseHelper with versioned schema, FK enforcement, default-seeded categories & settings.
- Repositories → Services → Providers → Screens separation of concerns.
- Material 3 academic theme (deep navy, gold, cream, burgundy).
- UI preview rendered to `iulms_ui_preview.png` showing 11 screens.

## Build 5 (Landing page with nav bar + 5 DB-backed sections)

The user asked to add a navigation bar with Hero / About / Services / How It Works /
Contact sections — all relevant content integrated with the database.

| Change | Where | What |
|--------|-------|------|
| 3 new SQLite tables | `database_helper.dart` | `library_services` (8 seeded services), `library_steps` (4 seeded workflow steps), `contact_messages` (visitor-submitted contact form messages) |
| Extended `settings` table | `constants.dart` + `_seedSettings` | New keys for library tagline, mission, vision, history, email, phone, address, hours, and 3 social links — all seeded with realistic Ethiopian university defaults |
| New models | `lib/models/library_info.dart` | `LibraryService`, `LibraryStep`, `ContactMessage`, `LibraryContactInfo` + a Material icon name→IconData map (16 icons) |
| New repository | `lib/repositories/library_info_repository.dart` | CRUD for services + steps + contact messages + aggregated contact info query |
| New service | `lib/services/library_info_service.dart` | Public API: `services()`, `steps()`, `contactInfo()`, `saveService()`, `deleteService()`, `saveStep()`, `deleteStep()`, `submitContactMessage()`, `inbox()`, `markContactHandled()`, `setSetting()` |
| New provider | `lib/providers/landing_provider.dart` | `LandingProvider` — loads all 5 sections' data in parallel via `Future.wait` |
| New landing screen | `lib/screens/landing_screen.dart` | Public page with: (1) sticky brand bar with Sign-In / Dashboard button, (2) sticky horizontal scrollable nav chips (Hero · About · Services · How It Works · Contact) — gold pill when active, (3) Ken Burns hero, (4) About section (mission + vision + history cards + live stats from books/users/loans tables), (5) Services section (2-col grid of all services from DB), (6) How It Works (vertical stepper with connector lines), (7) Contact section (info tiles + form that writes to contact_messages), (8) branded footer. Smooth-scrolls to section on chip tap. Active section auto-highlights based on scroll offset. |
| New admin editor | `lib/screens/admin/library_info_editor_screen.dart` | 4-tab editor: About (tagline/mission/vision/history), Services (full CRUD with FAB add), How It Works (full CRUD with FAB add), Contact (email/phone/address/hours/socials). All writes persist to the same DB tables the landing page reads from — changes appear immediately on the public page. |
| New admin inbox | `lib/screens/admin/contact_inbox_screen.dart` | Lists visitor messages, filter unhandled only, reply draft dialog, mark-handled action |
| Splash routes to landing | `splash_screen.dart` | On first launch (or signed-out state), user lands on the public landing page instead of going straight to login |
| Login screen "Explore" link | `login_screen.dart` | "Explore the Library →" button under the Sign-In card |
| Drawer entry | `widgets/app_drawer.dart` | New "About the Library" item linking to landing page + new "Library Info Editor" and "Contact Inbox" items for admins |
| Admin panel cards | `admin_panel.dart` | Two new sections added: "Library Info Editor" + "Contact Inbox" |
| Provider wiring | `routes/app_routes.dart` | `LibraryInfoService` exposed via `Provider<LibraryInfoService>.value`, `LandingProvider` registered as `ChangeNotifierProvider` |
| New route constants | `routes/app_routes.dart` | `/landing`, `/admin/library-info`, `/admin/contact-inbox` |
| Updated UI preview HTML + PNG | `iulms_ui_preview.html` + `.png` | Added a 12th phone mockup showing the full landing page with all 5 sections. Active nav chip is gold "Hero"; Ken Burns hero on top; about/services/how-it-works/contact visible; navy footer. |
| Landing close-up PNG | `iulms_landing_page.png` | Single-phone capture of the new landing page (320×727) |

### Section-to-DB mapping (everything is DB-backed)

| Section | Source | Tables queried |
|---------|--------|----------------|
| Hero | Ken Burns panoramas + tagline | `settings.library_tagline` |
| About | Mission / Vision / History + live stats | `settings.library_mission` / `_vision` / `_history` + `books` + `users` + `loans` |
| Services | Admin-editable list | `library_services` table |
| How It Works | Admin-editable stepper | `library_steps` table |
| Contact | Contact info + form submission | `settings.library_email` etc. + writes to `contact_messages` table |

## Build 4 (Ken Burns moving animation on hero image)

The user wanted the home page to have a single hero image with a moving
animation — and that single image must show **all parts of the library**
(interior + students + books + librarian). Standard design colors retained.

| Change | Where | What |
|--------|-------|------|
| Generated 3 wide panoramic hero images (1344×768 each) | `assets/images/hero_panorama.png`, `hero_panorama_2.png`, `hero_panorama_3.png` | Each image is a single wide scene that contains the library interior, students, books, and librarians — so every still frame already shows the whole library ecosystem |
| New `KenBurnsHero` widget | `lib/widgets/ken_burns_hero.dart` | Auto-rotating hero with: (a) slow zoom from 1.05→1.22 scale, (b) slow diagonal pan (12px × 8px), (c) cross-fade between images every 7s, (d) caption fade in/out in sync, (e) page-indicator dots that pulse gold when active, (f) gold "Browse Catalog" CTA chip, (g) brand strip top-left in academic gold. All animations use `AnimationController` + `Curves.easeInOut`/`easeOut` for buttery motion. Widget is reusable — accepts a `List<String>` of image paths, captions, and a tap handler. |
| Placed `KenBurnsHero` at the top of dashboard | `lib/screens/dashboard_screen.dart` | Sits directly below the greeting, above the stat grid + 4 horizontal carousels. Tapping the hero opens the catalog. |
| Added 3 hero image entries to `pubspec.yaml` | pubspec.yaml | All declared explicitly so they bundle into the APK |
| Updated UI preview HTML & PNG | `/home/z/my-project/download/iulms_ui_preview.html` + `.png` | Both admin and student dashboards now show the Ken Burns hero at the top. CSS `@keyframes` mirror the Flutter animation logic so the preview moves the same way the live app does. |
| Tight close-up PNG of just the hero | `/home/z/my-project/download/iulms_hero_animation.png` | 320×260 crop of the animated hero block so you can see the layered image + gradient + caption + CTA composition in isolation |
| Updated dashboard close-up PNG | `/home/z/my-project/download/iulms_dashboard_carousels.png` | Single-phone view with the hero + 4 horizontal carousels + stats + recent activity all visible |

### Animation timing (Flutter)

- **Per-image display**: 7 seconds
- **Cross-fade duration**: 1.2 seconds
- **Ken Burns curve**: ease-in-out, alternating direction per image (so consecutive images don't pan in the same direction)
- **Caption fade**: 0.7 seconds, offset so it fades out before the cross-fade and fades back in after
- **Total cycle**: 3 images × 7s = 21 seconds before the hero loops back to image #1

### Standard design colors used

The hero overlay + accents stick to the IULMS academic palette — no off-brand colors:

| Element | Color | Hex |
|---------|-------|-----|
| Background fill (behind image) | primaryDark | `#13243B` |
| Top gradient fade (image→navy) | primaryDark 35% → transparent 35% → 92% | gradient |
| Brand strip line + label | accent (academic gold) | `#C9A961` |
| Page indicator dot (active) | accent (academic gold) | `#C9A961` |
| Caption title (white) | white with black 55% text-shadow | `#FFFFFF` |
| Caption subtitle | accent (academic gold) | `#C9A961` |
| CTA chip background | accent (academic gold) | `#C9A961` |
| CTA chip text/icon | primaryDark | `#13243B` |

## Build 3 (image carousels on dashboard)

The user asked for the home page to feature a library image with horizontal scroll
across library sections, plus separate carousels for books, students, and librarians
in the best possible design. This iteration delivers all four.

| Change | Where | What |
|--------|-------|------|
| Downloaded 15 real photos (4 library interiors, 4 students, 4 book close-ups, 3 librarians) | `assets/images/` | All photos hosted locally as JPG/PNG, declared in `pubspec.yaml` |
| New `ImageAssets` constants catalog | `lib/utils/image_assets.dart` | Single source of truth for the 4 image lists + paired captions |
| New reusable `ImageCarousel` widget | `lib/widgets/image_carousel.dart` | Horizontal scroll, gradient overlay, gold corner badge with `IULMS` branding, caption block, configurable card width/height |
| Rebuilt the dashboard with 4 carousels | `lib/screens/dashboard_screen.dart` | 1) **"Explore the Library"** hero carousel (4 cards: Reading Hall, Reference Stacks, Quiet Study Area, Periodicals Wing) — directly below the brand header; 2) role-aware stat grid; 3) Quick Actions; 4) **"From the Stacks"** book carousel (Fiction, Reference, Periodicals, New Arrivals); 5) **"Student Community"** carousel (Study Groups, Reading Circles, Quiet Hours, Collaboration) — admin/librarian sees "View all" linking to Users screen; 6) **"Our Librarians"** carousel (Circulation Desk, Reference Help, Cataloging) — admin sees "View all" linking to User Management; 7) Recent Activity feed |
| Updated `pubspec.yaml` asset list | pubspec.yaml | All 15 images declared explicitly so they bundle into the APK |
| Refreshed the UI preview HTML & PNG | `/home/z/my-project/download/iulms_ui_preview.html` + `.png` | Both admin and student dashboard mockups now show the image carousels with real photos |
| Standalone close-up PNG of the new dashboard | `/home/z/my-project/download/iulms_dashboard_carousels.png` | Single-phone view showing the carousel layout in detail |

## Build 2 (compile-audit & CSV export fix)

After running a static audit, the following compile bugs were identified and fixed
so the project compiles cleanly under `flutter run` from VS Code:

| Bug | Fix |
|-----|-----|
| `AppConstants.libraryName` referenced in `app_drawer.dart` + `dashboard_screen.dart` — this constant does NOT exist (it's a settings key, not a constant value) | Changed both call sites to `AppConstants.appName` (which is `'Injibara University Library'`) |
| `IssueLoanScreen` called `auth.defaultLoanDays()` on AuthProvider — method didn't exist | Added `defaultLoanDays()` and `maxActiveLoans()` delegating wrappers on `AuthProvider` |
| `IssueLoanScreen` called `books.search(query: ..., availableOnly: true)` on `BookProvider` — method didn't exist (only `setQuery`/`setCategory`/`refresh`) | Added public `search({query, categoryId, availableOnly})` method on `BookProvider` that delegates to `BookService.search` without mutating provider state |
| `BookDetailScreen._load()` called `loans.activeForBook(bookId)` on `LoanProvider` — method didn't exist | Added `activeForBook(int bookId)` delegating wrapper on `LoanProvider` |
| `BookDetailScreen._body` accepted a `User` parameter but didn't import `models/user.dart` | Added the missing import |
| `BookDetailScreen._load` category lookup used ugly cast chain that wouldn't compile cleanly | Refactored to a clean `firstWhere` with try/catch, also lazy-loads categories if the provider hasn't fetched them yet |
| CSV export in `ReportsScreen` only showed text in a dialog, didn't actually save a file | Added `path_provider` + `share_plus` packages; `_exportCsv` now writes to `getApplicationDocumentsDirectory()` and offers the file via the system share sheet. Falls back to dialog if sharing is unavailable |
| `AndroidManifest.xml` was missing | Created manifest template with INTERNET permission + documented storage permission rationale in the comments and README |

## How to verify the fixes

```bash
cd iulms
flutter pub get
flutter analyze    # should show only style warnings, no errors
flutter run        # launches on a connected Android device / emulator
flutter test       # runs all unit + widget tests (uses sqflite_common_ffi)
```

## Original brief coverage (12 sections)

1. Tech stack ✓ (Flutter, sqflite, Provider, Material 3, intl, validation)
2. Roles & auth ✓ (login, register, first-admin setup, role gates at UI + service)
3. Dashboard ✓ (role-aware stats from real DB records, quick actions, recent activity)
4. Book management ✓ (CRUD, ISBN uniqueness, search by title/author/ISBN/category, delete guard)
5. Borrowing/returning ✓ (transactional issue/return, overdue detection, borrowing limit)
6. DB design ✓ (7 tables, FK, CHECK constraints, indexes, transactions)
7. Student features ✓ (browse, filter, profile editing, password change, empty states)
8. Notifications ✓ (in-app center, auto-generated on issue/return); Reports ✓ (CSV export to file)
9. UI/UX ✓ (splash, login, register, dashboards, catalog, detail, forms, loans, notifications, reports, profile, admin)
10. Project structure ✓ (models, database, repositories, services, providers, screens, widgets, utils, routes)
11. Testing ✓ (database_test.dart + widget_test.dart — covers hashing, auth, duplicate ISBN, loan consistency, double-return, overdue, login widget)
12. Implementation ✓ (complete code, no placeholders, all imports resolve)

## Files added/modified in Build 2

- `lib/providers/auth_provider.dart` — added `defaultLoanDays()` + `maxActiveLoans()`
- `lib/providers/book_provider.dart` — added public `search()` method
- `lib/providers/loan_provider.dart` — added `activeForBook()` method
- `lib/screens/books/book_detail_screen.dart` — added user.dart import, refactored category lookup
- `lib/widgets/app_drawer.dart` — `libraryName` → `appName`
- `lib/screens/dashboard_screen.dart` — `libraryName` → `appName`
- `lib/screens/admin/reports_screen.dart` — real CSV file save via path_provider + share_plus
- `pubspec.yaml` — added `path_provider` and `share_plus`
- `android/app/src/main/AndroidManifest.xml` — new manifest template
- `README.md` — added Android storage permissions section
