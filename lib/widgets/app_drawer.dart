import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../routes/app_routes.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/tts_provider.dart';
import 'app_header_bar.dart';

/// Shared bottom navigation for top-level screens.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notif = context.watch<NotificationProvider>();
    final user = auth.currentUser!;
    final canManageBooks = user.canManageBooks;
    final isAdmin = user.isAdmin;

    final items = <_NavItem>[
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Home',
        route: AppRoutes.dashboard,
      ),
      _NavItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: 'Catalog',
        route: AppRoutes.catalog,
      ),
      _NavItem(
        icon: Icons.bookmark_border_rounded,
        activeIcon: Icons.bookmark_rounded,
        label: user.isStudent ? 'My Loans' : 'Loans',
        route: AppRoutes.myLoans,
      ),
      _NavItem(
        icon: Icons.notifications_none_rounded,
        activeIcon: Icons.notifications_rounded,
        label: 'Alerts',
        route: AppRoutes.notifications,
        badge: notif.unreadCount,
      ),
      if (canManageBooks)
        _NavItem(
          icon: Icons.library_books_outlined,
          activeIcon: Icons.library_books_rounded,
          label: 'Manage',
          route: AppRoutes.manageBooks,
        ),
      if (isAdmin)
        _NavItem(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings_rounded,
          label: 'Admin',
          route: AppRoutes.adminPanel,
        ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
        route: AppRoutes.profile,
      ),
    ];

    final index = currentIndex.clamp(0, items.length - 1);

    return BottomNavigationBar(
      currentIndex: index,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: AppTheme.slate,
      unselectedFontSize: 10.5,
      selectedFontSize: 11,
      showUnselectedLabels: true,
      onTap: (i) {
        final route = items[i].route;
        if (i == index) return;
        // Speak the destination name when voice nav is enabled.
        context.read<TtsProvider>().speakNav(items[i].label);
        Navigator.pushNamedAndRemoveUntil(context, route, (r) => r.settings.name == route);
      },
      items: items
          .map((e) => BottomNavigationBarItem(
                icon: e.badge > 0
                    ? Stack(
                        children: [
                          Icon(e.icon),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                color: AppTheme.danger,
                                shape: BoxShape.circle,
                              ),
                              constraints:
                                  const BoxConstraints(minWidth: 14, minHeight: 14),
                              child: Text(
                                '${e.badge}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Icon(e.icon),
                activeIcon: Icon(e.activeIcon),
                label: e.label,
              ))
          .toList(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final int badge;
  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.badge = 0,
  });
}

/// Shared app drawer accessible from any top-level screen via Scaffold.drawer.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final tts = context.watch<TtsProvider>();
    final user = auth.currentUser!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primaryLight],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BrandMark(size: 40),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        tts.isEnabled
                            ? Icons.record_voice_over_rounded
                            : Icons.voice_over_off_rounded,
                        color: tts.isEnabled ? AppTheme.accent : Colors.white54,
                        size: 22,
                      ),
                      tooltip: tts.isEnabled
                          ? 'Voice navigation ON · tap to mute'
                          : 'Voice navigation OFF · tap to enable',
                      onPressed: () => tts.toggle(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Playfair Display',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.fullName} · ${Role.labelOf(user.role)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: 'PT Serif',
                    fontSize: 12,
                  ),
                ),
                if (tts.isEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.volume_up_rounded,
                            color: AppTheme.accent, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Voice navigation enabled',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontFamily: 'PT Serif',
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _drawerTile(context, Icons.dashboard_outlined, 'Dashboard', AppRoutes.dashboard),
          _drawerTile(context, Icons.explore_outlined, 'About the Library', AppRoutes.landing),
          _drawerTile(context, Icons.menu_book_outlined, 'Book Catalog', AppRoutes.catalog),
          if (user.isStudent)
            _drawerTile(context, Icons.bookmark_border_rounded, 'My Loans', AppRoutes.myLoans),
          if (user.canManageBooks)
            _drawerTile(context, Icons.library_books_outlined, 'Manage Books', AppRoutes.manageBooks),
          if (user.canIssueBooks)
            _drawerTile(context, Icons.local_library_outlined, 'Issue Book', AppRoutes.issueLoan),
          if (user.canIssueBooks)
            _drawerTile(context, Icons.assignment_return_outlined, 'Return Book', AppRoutes.returnLoan),
          if (user.canIssueBooks)
            _drawerTile(context, Icons.history, 'Loan History', AppRoutes.loanHistory),
          _drawerTile(context, Icons.notifications_none_rounded, 'Notifications', AppRoutes.notifications),
          _drawerTile(context, Icons.history_rounded, 'Activity Log', AppRoutes.activityLog),
          if (user.isAdmin) ...[
            const Divider(),
            _drawerTile(context, Icons.admin_panel_settings_outlined, 'Administration', AppRoutes.adminPanel),
            _drawerTile(context, Icons.people_outline_rounded, 'Users', AppRoutes.userManagement),
            _drawerTile(context, Icons.category_outlined, 'Categories', AppRoutes.categoryManagement),
            _drawerTile(context, Icons.assessment_outlined, 'Reports', AppRoutes.reports),
            _drawerTile(context, Icons.school_outlined, 'Library Info Editor', AppRoutes.libraryInfoEditor),
            _drawerTile(context, Icons.inbox_outlined, 'Contact Inbox', AppRoutes.contactInbox),
            _drawerTile(context, Icons.settings_outlined, 'Settings', AppRoutes.settings),
          ],
          const Divider(),
          _drawerTile(context, Icons.person_outline, 'Profile', AppRoutes.profile),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                fontFamily: 'PT Serif',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.danger,
              ),
            ),
            onTap: () async {
              final tts = context.read<TtsProvider>();
              await tts.speak('Signing out. Goodbye.');
              Navigator.pop(context);
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String label, String route) {
    final current = ModalRoute.of(context)?.settings.name;
    final selected = current == route;
    final tts = context.read<TtsProvider>();
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppTheme.primary : AppTheme.slate,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'PT Serif',
          fontSize: 13.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppTheme.primary : AppTheme.ink,
        ),
      ),
      onTap: () {
        // Speak the destination name (when voice nav is enabled) so
        // users hear where they're going.
        tts.speakNav(label);
        Navigator.pop(context);
        if (current != route) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
