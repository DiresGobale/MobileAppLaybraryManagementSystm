import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    if (!user.isAdmin) {
      return Scaffold(
        appBar: const AppHeaderBar(title: 'Access denied', showBack: true),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Only administrators can access this area.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'PT Serif', color: AppTheme.slate),
            ),
          ),
        ),
      );
    }
    final sections = <_AdminSection>[
      _AdminSection(
        title: 'User Management',
        description: 'Add librarians and students, deactivate accounts, view student records.',
        icon: Icons.people_outline_rounded,
        color: AppTheme.burgundy,
        route: AppRoutes.userManagement,
      ),
      _AdminSection(
        title: 'Categories',
        description: 'Manage book categories used for cataloging and filtering.',
        icon: Icons.category_outlined,
        color: AppTheme.accentDark,
        route: AppRoutes.categoryManagement,
      ),
      _AdminSection(
        title: 'Reports',
        description: 'Inventory summary, popular titles, overdue loans, CSV export.',
        icon: Icons.assessment_outlined,
        color: AppTheme.primary,
        route: AppRoutes.reports,
      ),
      _AdminSection(
        title: 'Students',
        description: 'Browse registered student accounts by department.',
        icon: Icons.school_outlined,
        color: AppTheme.success,
        route: AppRoutes.students,
      ),
      _AdminSection(
        title: 'Library Info Editor',
        description: 'Edit landing page: services, How-It-Works steps, mission, contact details.',
        icon: Icons.edit_note_outlined,
        color: AppTheme.accent,
        route: AppRoutes.libraryInfoEditor,
      ),
      _AdminSection(
        title: 'Contact Inbox',
        description: 'Messages submitted by visitors via the landing page Contact form.',
        icon: Icons.inbox_outlined,
        color: AppTheme.primaryLight,
        route: AppRoutes.contactInbox,
      ),
      _AdminSection(
        title: 'Activity Log',
        description: 'Audit trail: every sign-in, CRUD operation, and contact event.',
        icon: Icons.history_rounded,
        color: AppTheme.burgundy,
        route: AppRoutes.activityLog,
      ),
      _AdminSection(
        title: 'Settings',
        description: 'Default loan period, borrowing limits, self-registration toggle.',
        icon: Icons.settings_outlined,
        color: AppTheme.slate,
        route: AppRoutes.settings,
      ),
    ];
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const AppHeaderBar(
        title: 'Administration',
        subtitle: 'Injibara University Library',
        showMenu: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        itemBuilder: (context, i) {
          final s = sections[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pushNamed(context, s.route),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: s.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: s.color.withOpacity(0.35)),
                      ),
                      child: Icon(s.icon, color: s.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: const TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.description,
                            style: const TextStyle(
                              fontFamily: 'PT Serif',
                              fontSize: 12,
                              color: AppTheme.slate,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.slate, size: 22),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 6),
    );
  }
}

class _AdminSection {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  _AdminSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}
