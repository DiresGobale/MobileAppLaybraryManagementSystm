/// Application-wide constants for IULMS.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Injibara University Library';
  static const String appNameShort = 'IULMS';
  static const String universityName = 'Injibara University';
  static const String tagline = 'Knowledge. Heritage. Discovery.';

  // Database
  static const String dbName = 'iulms.db';
  static const int dbVersion = 1;

  // Settings keys
  static const String keyLoanDays = 'default_loan_days';
  static const String keyMaxActiveLoans = 'max_active_loans';
  static const String keySelfRegistration = 'enable_self_registration';
  static const String keyLibraryName = 'library_name';
  static const String keyLibrarianCanManageUsers = 'librarian_can_manage_users';
  static const String keyTtsEnabled = 'voice_navigation_enabled';
  static const String keyTtsLanguage = 'voice_navigation_language';
  static const String keyDataSourceMode = 'data_source_mode'; // 'local' or 'remote'
  static const String keyBackendUrl = 'backend_url';

  // Library info (About section) settings keys
  static const String keyLibraryTagline = 'library_tagline';
  static const String keyLibraryMission = 'library_mission';
  static const String keyLibraryVision = 'library_vision';
  static const String keyLibraryHistory = 'library_history';

  // Contact section settings keys
  static const String keyContactEmail = 'library_email';
  static const String keyContactPhone = 'library_phone';
  static const String keyContactAddress = 'library_address';
  static const String keyContactHours = 'library_hours';
  static const String keyContactFacebook = 'library_facebook';
  static const String keyContactTwitter = 'library_twitter';
  static const String keyContactInstagram = 'library_instagram';

  // Default settings seeded on first launch
  static const Map<String, String> defaultSettings = {
    keyLoanDays: '14',
    keyMaxActiveLoans: '3',
    keySelfRegistration: 'true',
    keyLibraryName: 'Injibara University Library',
    keyLibrarianCanManageUsers: 'false',
    keyTtsEnabled: 'true',
    keyTtsLanguage: 'en-US',
    keyDataSourceMode: 'local',
    keyBackendUrl: 'http://10.0.2.2:4000',
    // About section content
    keyLibraryTagline: 'Knowledge · Heritage · Discovery',
    keyLibraryMission:
        'To empower Injibara University students and faculty with equitable '
        'access to scholarly resources, cultivate information literacy, and '
        'preserve the academic heritage of our community.',
    keyLibraryVision:
        'To be the leading academic library in the Amhara region — a hub for '
        'research, lifelong learning, and the digital preservation of '
        'Ethiopian scholarship.',
    keyLibraryHistory:
        'Founded in 2018 alongside Injibara University, the library has grown '
        'from a single reading room of 1,200 volumes to a multi-floor learning '
        'environment serving over 4,000 students across six colleges. Our '
        'collections emphasize STEM, agriculture, business, and Ethiopian '
        'studies.',
    // Contact section content
    keyContactEmail: 'library@injibara.edu.et',
    keyContactPhone: '+251 58 334 0000',
    keyContactAddress:
        'Injibara University Main Campus, Library Building, '
        'P.O. Box 67, Injibara, Amhara Region, Ethiopia',
    keyContactHours: 'Mon – Fri 08:00 – 22:00 · Sat 09:00 – 18:00 · Sun closed',
    keyContactFacebook: 'https://facebook.com/injibara.library',
    keyContactTwitter: 'https://twitter.com/iulibrary',
    keyContactInstagram: 'https://instagram.com/iulibrary',
  };

  // Role names
  static const String roleAdmin = 'admin';
  static const String roleLibrarian = 'librarian';
  static const String roleStudent = 'student';

  // Loan status
  static const String statusActive = 'active';
  static const String statusReturned = 'returned';
  static const String statusOverdue = 'overdue';

  // Activity log actions
  static const String actionLogin = 'login';
  static const String actionLogout = 'logout';
  static const String actionBookAdd = 'book_add';
  static const String actionBookEdit = 'book_edit';
  static const String actionBookDelete = 'book_delete';
  static const String actionLoanIssue = 'loan_issue';
  static const String actionLoanReturn = 'loan_return';
  static const String actionUserAdd = 'user_add';
  static const String actionUserEdit = 'user_edit';
  static const String actionUserDeactivate = 'user_deactivate';
  static const String actionUserReactivate = 'user_reactivate';
  static const String actionUserDelete = 'user_delete';
  static const String actionServiceAdd = 'service_add';
  static const String actionServiceEdit = 'service_edit';
  static const String actionServiceDelete = 'service_delete';
  static const String actionStepAdd = 'step_add';
  static const String actionStepEdit = 'step_edit';
  static const String actionStepDelete = 'step_delete';
  static const String actionContactReceived = 'contact_received';
  static const String actionContactHandled = 'contact_handled';
  static const String actionContactDeleted = 'contact_deleted';
  static const String actionLibraryInfoEdit = 'library_info_edit';
  static const String actionSettingsChange = 'settings_change';
  static const String actionVoiceToggle = 'voice_toggle';
  static const String actionProfileUpdate = 'profile_update';
  static const String actionPasswordChange = 'password_change';

  /// Human-readable label for an activity-log action key.
  static String actionLabel(String action) {
    const labels = <String, String>{
      actionLogin: 'Signed in',
      actionLogout: 'Signed out',
      actionBookAdd: 'Added book',
      actionBookEdit: 'Updated book',
      actionBookDelete: 'Deleted book',
      actionLoanIssue: 'Issued loan',
      actionLoanReturn: 'Processed return',
      actionUserAdd: 'Created user',
      actionUserEdit: 'Updated user',
      actionUserDeactivate: 'Deactivated user',
      actionUserReactivate: 'Reactivated user',
      actionUserDelete: 'Deleted user',
      actionServiceAdd: 'Added service',
      actionServiceEdit: 'Updated service',
      actionServiceDelete: 'Deleted service',
      actionStepAdd: 'Added workflow step',
      actionStepEdit: 'Updated workflow step',
      actionStepDelete: 'Deleted workflow step',
      actionContactReceived: 'Received contact message',
      actionContactHandled: 'Marked contact handled',
      actionContactDeleted: 'Deleted contact message',
      actionLibraryInfoEdit: 'Edited library info',
      actionSettingsChange: 'Changed settings',
      actionVoiceToggle: 'Toggled voice navigation',
      actionProfileUpdate: 'Updated own profile',
      actionPasswordChange: 'Changed own password',
    };
    return labels[action] ?? action;
  }

  /// Static list of all known activity-log action keys. Used by the
  /// Activity Log screen's filter dropdown.
  static const List<String> knownActions = [
    actionLogin, actionLogout,
    actionBookAdd, actionBookEdit, actionBookDelete,
    actionLoanIssue, actionLoanReturn,
    actionUserAdd, actionUserEdit, actionUserDeactivate,
    actionUserReactivate, actionUserDelete,
    actionServiceAdd, actionServiceEdit, actionServiceDelete,
    actionStepAdd, actionStepEdit, actionStepDelete,
    actionContactReceived, actionContactHandled, actionContactDeleted,
    actionLibraryInfoEdit, actionSettingsChange, actionVoiceToggle,
    actionProfileUpdate, actionPasswordChange,
  ];

  // Notification titles
  static const String notifLoanIssued = 'Book Issued';
  static const String notifDueSoon = 'Due Soon Reminder';
  static const String notifOverdue = 'Overdue Notice';
  static const String notifReturned = 'Book Returned';
}
