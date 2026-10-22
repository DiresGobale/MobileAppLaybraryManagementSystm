import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/landing_provider.dart';
import '../providers/tts_provider.dart';
import '../providers/data_source_provider.dart';
import '../services/auth_service.dart';
import '../services/book_service.dart';
import '../services/loan_service.dart';
import '../services/notification_service.dart';
import '../services/report_service.dart';
import '../services/library_info_service.dart';
import '../services/tts_service.dart';
import '../services/remote_services.dart';
import '../services/api_client.dart';
import '../utils/backend_config.dart';
import '../database/database_helper.dart';
import '../repositories/user_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/loan_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/activity_log_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/library_info_repository.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/books/book_catalog_screen.dart';
import '../screens/books/book_detail_screen.dart';
import '../screens/books/book_form_screen.dart';
import '../screens/books/manage_books_screen.dart';
import '../screens/loans/my_loans_screen.dart';
import '../screens/loans/issue_loan_screen.dart';
import '../screens/loans/return_loan_screen.dart';
import '../screens/loans/loan_history_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/admin/admin_panel.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/category_management_screen.dart';
import '../screens/admin/settings_screen.dart';
import '../screens/admin/reports_screen.dart';
import '../screens/admin/library_info_editor_screen.dart';
import '../screens/admin/contact_inbox_screen.dart';
import '../screens/admin/activity_log_screen.dart';
import '../screens/students_screen.dart';
import '../utils/theme.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const landing = '/landing';
  static const dashboard = '/dashboard';
  static const catalog = '/catalog';
  static const bookDetail = '/book/detail';
  static const bookForm = '/book/form';
  static const manageBooks = '/books/manage';
  static const myLoans = '/loans/my';
  static const issueLoan = '/loans/issue';
  static const returnLoan = '/loans/return';
  static const loanHistory = '/loans/history';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const adminPanel = '/admin';
  static const userManagement = '/admin/users';
  static const categoryManagement = '/admin/categories';
  static const settings = '/admin/settings';
  static const reports = '/admin/reports';
  static const libraryInfoEditor = '/admin/library-info';
  static const contactInbox = '/admin/contact-inbox';
  static const activityLog = '/admin/activity-log';
  static const students = '/students';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case landing:
        return MaterialPageRoute(builder: (_) => const LandingScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case catalog:
        return MaterialPageRoute(builder: (_) => const BookCatalogScreen());
      case bookDetail:
        final id = (settings.arguments as int?) ?? 0;
        return MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: id));
      case bookForm:
        final id = settings.arguments as int?;
        return MaterialPageRoute(builder: (_) => BookFormScreen(bookId: id));
      case manageBooks:
        return MaterialPageRoute(builder: (_) => const ManageBooksScreen());
      case myLoans:
        return MaterialPageRoute(builder: (_) => const MyLoansScreen());
      case issueLoan:
        return MaterialPageRoute(builder: (_) => const IssueLoanScreen());
      case returnLoan:
        return MaterialPageRoute(builder: (_) => const ReturnLoanScreen());
      case loanHistory:
        return MaterialPageRoute(builder: (_) => const LoanHistoryScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case adminPanel:
        return MaterialPageRoute(builder: (_) => const AdminPanel());
      case userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      case categoryManagement:
        return MaterialPageRoute(builder: (_) => const CategoryManagementScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case libraryInfoEditor:
        return MaterialPageRoute(builder: (_) => const LibraryInfoEditorScreen());
      case contactInbox:
        return MaterialPageRoute(builder: (_) => const ContactInboxScreen());
      case activityLog:
        return MaterialPageRoute(builder: (_) => const ActivityLogScreen());
      case students:
        return MaterialPageRoute(builder: (_) => const StudentsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }

  /// Wires up the Provider tree at app startup. Reads `BackendConfig.mode` to
  /// decide whether to instantiate local (SQLite) services or remote (HTTP)
  /// services. To switch modes, the user changes the setting in Settings →
  /// Backend and relaunches the app.
  static List<Provider> providers() {
    // Bootstrap config synchronously — the mode is needed now.
    // (Async bootstrap is also called from main.dart, but here we read the
    // cached singleton. The first launch defaults to LOCAL mode.)
    final isRemote = BackendConfig.instance.isRemote;

    // Always register TTS + DataSource providers (mode-independent)
    final settingsRepo = SettingsRepository(DatabaseHelper.instance);
    final ttsService = TtsService(settingsRepo);

    if (isRemote) {
      // ===== REMOTE MODE — all services talk to the Node.js backend via HTTP
      final remoteAuth = RemoteAuthService();
      final remoteBook = RemoteBookService();
      final remoteLoan = RemoteLoanService();
      final remoteNotif = RemoteNotificationService();
      final remoteReport = RemoteReportService();
      final remoteLibraryInfo = RemoteLibraryInfoService();

      return [
        Provider<RemoteAuthService>.value(value: remoteAuth),
        Provider<RemoteBookService>.value(value: remoteBook),
        Provider<RemoteLoanService>.value(value: remoteLoan),
        Provider<RemoteNotificationService>.value(value: remoteNotif),
        Provider<RemoteReportService>.value(value: remoteReport),
        Provider<RemoteLibraryInfoService>.value(value: remoteLibraryInfo),
        Provider<TtsService>.value(value: ttsService),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(remoteAuth)..bootstrap(),
        ),
        ChangeNotifierProvider<BookProvider>(
          create: (_) => BookProvider(remoteBook), // _categories = null (remote)
        ),
        ChangeNotifierProvider<LoanProvider>(
          create: (_) => LoanProvider(remoteLoan),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(remoteNotif),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(remoteReport),
        ),
        ChangeNotifierProvider<LandingProvider>(
          create: (_) => LandingProvider(remoteLibraryInfo, remoteReport),
        ),
        ChangeNotifierProvider<TtsProvider>(
          create: (_) => TtsProvider(ttsService)..bootstrap(),
        ),
        ChangeNotifierProvider<DataSourceProvider>(
          create: (_) => DataSourceProvider()..bootstrap(),
        ),
      ];
    }

    // ===== LOCAL MODE — all services use on-device SQLite
    final db = DatabaseHelper.instance;
    final userRepo = UserRepository(db);
    final bookRepo = BookRepository(db);
    final categoryRepo = CategoryRepository(db);
    final loanRepo = LoanRepository(db);
    final notifRepo = NotificationRepository(db);
    final logRepo = ActivityLogRepository(db);
    final libraryInfoRepo = LibraryInfoRepository(db);

    final authService = AuthService(userRepo, logRepo, settingsRepo);
    final bookService = BookService(bookRepo, categoryRepo, logRepo);
    final loanService = LoanService(loanRepo, bookRepo, notifRepo, logRepo, settingsRepo);
    final notifService = NotificationService(notifRepo);
    final reportService = ReportService(bookRepo, loanRepo, userRepo);
    final libraryInfoService = LibraryInfoService(libraryInfoRepo, logRepo);

    return [
      Provider<AuthService>.value(value: authService),
      Provider<BookService>.value(value: bookService),
      Provider<LoanService>.value(value: loanService),
      Provider<NotificationService>.value(value: notifService),
      Provider<ReportService>.value(value: reportService),
      Provider<LibraryInfoService>.value(value: libraryInfoService),
      Provider<TtsService>.value(value: ttsService),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(authService)..bootstrap(),
      ),
      ChangeNotifierProvider<BookProvider>(
        create: (_) => BookProvider(bookService, categoryRepo),
      ),
      ChangeNotifierProvider<LoanProvider>(
        create: (_) => LoanProvider(loanService),
      ),
      ChangeNotifierProvider<NotificationProvider>(
        create: (_) => NotificationProvider(notifService),
      ),
      ChangeNotifierProvider<DashboardProvider>(
        create: (_) => DashboardProvider(reportService),
      ),
      ChangeNotifierProvider<LandingProvider>(
        create: (_) => LandingProvider(libraryInfoService, reportService),
      ),
      ChangeNotifierProvider<TtsProvider>(
        create: (_) => TtsProvider(ttsService)..bootstrap(),
      ),
      ChangeNotifierProvider<DataSourceProvider>(
        create: (_) => DataSourceProvider()..bootstrap(),
      ),
    ];
  }

  static ThemeData theme() => AppTheme.light();

  /// Human-readable label for a route — used by the TTS voice-navigation
  /// system so it can speak the destination's name even when the route
  /// string is a slash path (e.g. `/admin/users` → "User Management").
  static String labelForRoute(String route) {
    const labels = <String, String>{
      splash: 'Home',
      login: 'Login',
      register: 'Register',
      landing: 'About the Library',
      dashboard: 'Dashboard',
      catalog: 'Book Catalog',
      bookDetail: 'Book Details',
      bookForm: 'Book Form',
      manageBooks: 'Manage Books',
      myLoans: 'My Loans',
      issueLoan: 'Issue Book',
      returnLoan: 'Return Book',
      loanHistory: 'Loan History',
      notifications: 'Notifications',
      profile: 'Profile',
      adminPanel: 'Administration',
      userManagement: 'User Management',
      categoryManagement: 'Categories',
      settings: 'Settings',
      reports: 'Reports',
      libraryInfoEditor: 'Library Info Editor',
      contactInbox: 'Contact Inbox',
      activityLog: 'Activity Log',
      students: 'Students',
    };
    return labels[route] ?? route.replaceAll('/', '').replaceAll('_', ' ');
  }
}
