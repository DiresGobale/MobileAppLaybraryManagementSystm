/**
 * Application constants — kept in sync with the Flutter app's
 * lib/utils/constants.dart so the backend and frontend agree on
 * role names, action keys, loan statuses, etc.
 */
const ROLES = Object.freeze({
  ADMIN: 'admin',
  LIBRARIAN: 'librarian',
  STUDENT: 'student',
});

const LOAN_STATUS = Object.freeze({
  ACTIVE: 'active',
  RETURNED: 'returned',
  OVERDUE: 'overdue',
});

const ACTION_KEYS = Object.freeze({
  LOGIN: 'login',
  LOGOUT: 'logout',
  BOOK_ADD: 'book_add',
  BOOK_EDIT: 'book_edit',
  BOOK_DELETE: 'book_delete',
  LOAN_ISSUE: 'loan_issue',
  LOAN_RETURN: 'loan_return',
  USER_ADD: 'user_add',
  USER_EDIT: 'user_edit',
  USER_DEACTIVATE: 'user_deactivate',
  USER_REACTIVATE: 'user_reactivate',
  USER_DELETE: 'user_delete',
  SERVICE_ADD: 'service_add',
  SERVICE_EDIT: 'service_edit',
  SERVICE_DELETE: 'service_delete',
  STEP_ADD: 'step_add',
  STEP_EDIT: 'step_edit',
  STEP_DELETE: 'step_delete',
  CONTACT_RECEIVED: 'contact_received',
  CONTACT_HANDLED: 'contact_handled',
  CONTACT_DELETED: 'contact_deleted',
  LIBRARY_INFO_EDIT: 'library_info_edit',
  SETTINGS_CHANGE: 'settings_change',
  PROFILE_UPDATE: 'profile_update',
  PASSWORD_CHANGE: 'password_change',
});

const ACTION_LABELS = Object.freeze({
  [ACTION_KEYS.LOGIN]: 'Signed in',
  [ACTION_KEYS.LOGOUT]: 'Signed out',
  [ACTION_KEYS.BOOK_ADD]: 'Added book',
  [ACTION_KEYS.BOOK_EDIT]: 'Updated book',
  [ACTION_KEYS.BOOK_DELETE]: 'Deleted book',
  [ACTION_KEYS.LOAN_ISSUE]: 'Issued loan',
  [ACTION_KEYS.LOAN_RETURN]: 'Processed return',
  [ACTION_KEYS.USER_ADD]: 'Created user',
  [ACTION_KEYS.USER_EDIT]: 'Updated user',
  [ACTION_KEYS.USER_DEACTIVATE]: 'Deactivated user',
  [ACTION_KEYS.USER_REACTIVATE]: 'Reactivated user',
  [ACTION_KEYS.USER_DELETE]: 'Deleted user',
  [ACTION_KEYS.SERVICE_ADD]: 'Added service',
  [ACTION_KEYS.SERVICE_EDIT]: 'Updated service',
  [ACTION_KEYS.SERVICE_DELETE]: 'Deleted service',
  [ACTION_KEYS.STEP_ADD]: 'Added workflow step',
  [ACTION_KEYS.STEP_EDIT]: 'Updated workflow step',
  [ACTION_KEYS.STEP_DELETE]: 'Deleted workflow step',
  [ACTION_KEYS.CONTACT_RECEIVED]: 'Received contact message',
  [ACTION_KEYS.CONTACT_HANDLED]: 'Marked contact handled',
  [ACTION_KEYS.CONTACT_DELETED]: 'Deleted contact message',
  [ACTION_KEYS.LIBRARY_INFO_EDIT]: 'Edited library info',
  [ACTION_KEYS.SETTINGS_CHANGE]: 'Changed settings',
  [ACTION_KEYS.PROFILE_UPDATE]: 'Updated own profile',
  [ACTION_KEYS.PASSWORD_CHANGE]: 'Changed own password',
});

const SETTINGS_KEYS = Object.freeze({
  LOAN_DAYS: 'default_loan_days',
  MAX_ACTIVE_LOANS: 'max_active_loans',
  SELF_REGISTRATION: 'enable_self_registration',
  LIBRARY_NAME: 'library_name',
  LIBRARIAN_CAN_MANAGE_USERS: 'librarian_can_manage_users',
  VOICE_NAV_ENABLED: 'voice_navigation_enabled',
  LIBRARY_TAGLINE: 'library_tagline',
  LIBRARY_MISSION: 'library_mission',
  LIBRARY_VISION: 'library_vision',
  LIBRARY_HISTORY: 'library_history',
  CONTACT_EMAIL: 'library_email',
  CONTACT_PHONE: 'library_phone',
  CONTACT_ADDRESS: 'library_address',
  CONTACT_HOURS: 'library_hours',
  CONTACT_FACEBOOK: 'library_facebook',
  CONTACT_TWITTER: 'library_twitter',
  CONTACT_INSTAGRAM: 'library_instagram',
});

const DEFAULT_SETTINGS = {
  [SETTINGS_KEYS.LOAN_DAYS]: '14',
  [SETTINGS_KEYS.MAX_ACTIVE_LOANS]: '3',
  [SETTINGS_KEYS.SELF_REGISTRATION]: 'true',
  [SETTINGS_KEYS.LIBRARY_NAME]: 'Injibara University Library',
  [SETTINGS_KEYS.LIBRARIAN_CAN_MANAGE_USERS]: 'false',
  [SETTINGS_KEYS.VOICE_NAV_ENABLED]: 'true',
  [SETTINGS_KEYS.LIBRARY_TAGLINE]: 'Knowledge · Heritage · Discovery',
  [SETTINGS_KEYS.LIBRARY_MISSION]:
    'To empower Injibara University students and faculty with equitable access to scholarly resources, cultivate information literacy, and preserve the academic heritage of our community.',
  [SETTINGS_KEYS.LIBRARY_VISION]:
    'To be the leading academic library in the Amhara region — a hub for research, lifelong learning, and the digital preservation of Ethiopian scholarship.',
  [SETTINGS_KEYS.LIBRARY_HISTORY]:
    'Founded in 2018 alongside Injibara University, the library has grown from a single reading room of 1,200 volumes to a multi-floor learning environment serving over 4,000 students across six colleges.',
  [SETTINGS_KEYS.CONTACT_EMAIL]: 'library@injibara.edu.et',
  [SETTINGS_KEYS.CONTACT_PHONE]: '+251 58 334 0000',
  [SETTINGS_KEYS.CONTACT_ADDRESS]:
    'Injibara University Main Campus, Library Building, P.O. Box 67, Injibara, Amhara Region, Ethiopia',
  [SETTINGS_KEYS.CONTACT_HOURS]: 'Mon – Fri 08:00 – 22:00 · Sat 09:00 – 18:00 · Sun closed',
  [SETTINGS_KEYS.CONTACT_FACEBOOK]: 'https://facebook.com/injibara.library',
  [SETTINGS_KEYS.CONTACT_TWITTER]: 'https://twitter.com/iulibrary',
  [SETTINGS_KEYS.CONTACT_INSTAGRAM]: 'https://instagram.com/iulibrary',
};

const DEFAULT_CATEGORIES = [
  ['Computer Science', 'Programming, algorithms, software engineering, AI'],
  ['Engineering', 'Civil, mechanical, electrical, chemical engineering'],
  ['Business', 'Management, accounting, economics, marketing'],
  ['Medicine', 'Medicine, nursing, public health, pharmacy'],
  ['Humanities', 'History, philosophy, literature, languages'],
  ['Natural Sciences', 'Mathematics, physics, chemistry, biology'],
  ['Education', 'Pedagogy, curriculum, educational psychology'],
  ['Law', 'Constitutional, criminal, civil, international law'],
  ['Agriculture', 'Agronomy, animal science, food security'],
  ['Reference', 'Dictionaries, encyclopedias, atlases'],
];

const DEFAULT_SERVICES = [
  { title: 'Book Borrowing', description: 'Borrow up to 3 books for 14 days with your student ID. Renewals available at the circulation desk.', icon_name: 'menu_book', display_order: 1 },
  { title: 'Quiet Study Spaces', description: '240 silent-study seats across three reading halls, plus 6 group-study rooms available by reservation.', icon_name: 'self_improvement', display_order: 2 },
  { title: 'Research Assistance', description: 'Subject-specialist librarians offer one-on-one research consultations, citation help, and literature-review coaching.', icon_name: 'psychology', display_order: 3 },
  { title: 'Inter-Library Loan', description: 'Request books and articles from partner universities across Ethiopia and the East African research consortium.', icon_name: 'local_shipping', display_order: 4 },
  { title: 'Digital Resources', description: 'On-campus access to JSTOR, IEEE Xplore, HINARI, and over 40 subscribed e-journals and e-book collections.', icon_name: 'devices', display_order: 5 },
  { title: 'Reference & Citation Help', description: 'Drop-in help with APA, MLA, Chicago, and IEEE citation styles. Reference management software tutorials weekly.', icon_name: 'school', display_order: 6 },
  { title: 'Printing & Scanning', description: 'Black-and-white and color printing, photocopying, and document scanning at subsidized student rates.', icon_name: 'print', display_order: 7 },
  { title: 'Wi-Fi & Power', description: 'Campus-wide Eduroam Wi-Fi and power outlets at every study seat for laptops and personal devices.', icon_name: 'wifi', display_order: 8 },
];

const DEFAULT_STEPS = [
  { step_number: 1, title: 'Browse the Catalog', description: 'Search by title, author, ISBN, or category. Filter to see only books currently on the shelves.', icon_name: 'search', display_order: 1 },
  { step_number: 2, title: 'Find Your Book', description: 'Note the shelf location code (e.g. A-12) from the book detail page and locate the shelf in the reading hall.', icon_name: 'menu_book', display_order: 2 },
  { step_number: 3, title: 'Borrow at the Counter', description: 'Bring the book and your student ID to the circulation desk. The librarian issues the loan and stamps your due-date slip.', icon_name: 'local_library', display_order: 3 },
  { step_number: 4, title: 'Return on Time', description: 'Return the book on or before the due date. Overdue loans block further borrowing until resolved.', icon_name: 'assignment_return', display_order: 4 },
];

module.exports = {
  ROLES,
  LOAN_STATUS,
  ACTION_KEYS,
  ACTION_LABELS,
  SETTINGS_KEYS,
  DEFAULT_SETTINGS,
  DEFAULT_CATEGORIES,
  DEFAULT_SERVICES,
  DEFAULT_STEPS,
};
