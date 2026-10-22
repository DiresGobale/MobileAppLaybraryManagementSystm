import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/report.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/notification_provider.dart';
import '../routes/app_routes.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/date_utils.dart';
import '../utils/image_assets.dart';
import '../utils/backend_config.dart';
import '../providers/data_source_provider.dart';
import '../widgets/activity_tile.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/image_carousel.dart';
import '../widgets/ken_burns_hero.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final dash = context.read<DashboardProvider>();
    final notif = context.read<NotificationProvider>();
    final auth = context.read<AuthProvider>();
    await dash.loadDashboard();
    if (auth.currentUser != null) {
      await notif.loadForUser(auth.currentUser!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dash = context.watch<DashboardProvider>();
    final notif = context.watch<NotificationProvider>();
    final user = auth.currentUser!;
    final stats = dash.stats;
    final recent = stats?.recentLoans ?? [];

    return Scaffold(
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          // ---- Header (gradient, brand mark, greeting) ----
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            automaticallyImplyLeading: false,
            flexibleSpace: _Header(user: user, unreadCount: notif.unreadCount),
            leading: Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            )),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _load,
              ),
            ],
          ),

          // ---- Greeting + tagline ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(user.fullName),
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Signed in as ${Role.labelOf(user.role)} · ${AppConstants.appName}',
                        style: const TextStyle(
                          fontFamily: 'PT Serif',
                          fontSize: 12.5,
                          color: AppTheme.slate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Data-source badge — LOCAL (green) or REMOTE (navy/cloud)
                      Consumer<DataSourceProvider>(
                        builder: (ctx, ds, _) {
                          final remote = ds.isRemote;
                          final connected = ds.isConnected;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: (remote
                                  ? (connected ? AppTheme.success : AppTheme.danger)
                                  : AppTheme.accentDark).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (remote
                                    ? (connected ? AppTheme.success : AppTheme.danger)
                                    : AppTheme.accentDark).withOpacity(0.45),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  remote
                                      ? (connected
                                          ? Icons.cloud_done_rounded
                                          : Icons.cloud_off_rounded)
                                      : Icons.storage_rounded,
                                  size: 10,
                                  color: remote
                                      ? (connected ? AppTheme.success : AppTheme.danger)
                                      : AppTheme.accentDark,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  remote
                                      ? (connected ? 'BACKEND' : 'OFFLINE')
                                      : 'LOCAL',
                                  style: TextStyle(
                                    color: remote
                                        ? (connected ? AppTheme.success : AppTheme.danger)
                                        : AppTheme.accentDark,
                                    fontFamily: 'Playfair Display',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ---- KEN BURNS ANIMATED HERO ----
          // A single panoramic image that contains all library aspects
          // (interior, students, books, librarian). Auto-rotates through
          // 3 panoramas with a slow zoom + pan (Ken Burns) motion + smooth
          // cross-fade. Tapping the hero opens the catalog.
          SliverToBoxAdapter(
            child: KenBurnsHero(
              imagePaths: ImageAssets.heroPanoramas,
              titles: ImageAssets.heroCaptions,
              subtitles: ImageAssets.heroSubCaptions,
              height: 260,
              perImage: const Duration(seconds: 7),
              fadeDuration: const Duration(milliseconds: 1200),
              onTap: () => Navigator.pushNamed(context, AppRoutes.catalog),
            ),
          ),

          // ---- HERO LIBRARY CAROUSEL (scrolls horizontally across library sections) ----
          SliverToBoxAdapter(
            child: ImageCarousel(
              imagePaths: ImageAssets.libraryScenes,
              captions: ImageAssets.libraryCaptions,
              subCaptions: const [
                'Open 08:00 – 22:00',
                'Reference & inter-library loan',
                'Silent study · 240 seats',
                'Current journals & papers',
              ],
              sectionTitle: 'Explore the Library',
              sectionSubtitle: 'Swipe through our reading spaces',
              height: 200,
              cardWidth: 240,
              onTap: (i) => Navigator.pushNamed(context, AppRoutes.catalog),
            ),
          ),

          // ---- Stats grid (role-aware) ----
          if (dash.isLoading && stats == null)
            const SliverToBoxAdapter(child: _LoadingBlock())
          else if (stats != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate(_statCards(context, stats, user)),
              ),
            ),

          // ---- Quick actions ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Container(width: 3, height: 14, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _QuickActions(user: user)),

          // ---- BOOKS CAROUSEL ----
          SliverToBoxAdapter(
            child: ImageCarousel(
              imagePaths: ImageAssets.bookScenes,
              captions: const ['Fiction', 'Reference', 'Periodicals', 'New Arrivals'],
              subCaptions: const [
                'Borrow up to 14 days',
                'In-library use only',
                'Latest issues',
                'Fresh this month',
              ],
              sectionTitle: 'From the Stacks',
              sectionSubtitle: 'Browse books by section',
              height: 180,
              cardWidth: 220,
              onTap: (i) => Navigator.pushNamed(context, AppRoutes.catalog),
            ),
          ),

          // ---- STUDENTS CAROUSEL (only visible to admin / librarian) ----
          if (user.isAdmin || user.isLibrarian)
            SliverToBoxAdapter(
              child: ImageCarousel(
                imagePaths: ImageAssets.studentScenes,
                captions: const ['Study Groups', 'Reading Circles', 'Quiet Hours', 'Collaboration'],
                subCaptions: const [
                  'Group study rooms',
                  'Weekly reading club',
                  'After-hours access',
                  'Project workspaces',
                ],
                sectionTitle: 'Student Community',
                sectionSubtitle: '186 registered students',
                height: 180,
                cardWidth: 220,
                onViewAll: () =>
                    Navigator.pushNamed(context, AppRoutes.students),
              ),
            )
          else
            SliverToBoxAdapter(
              child: ImageCarousel(
                imagePaths: ImageAssets.studentScenes,
                captions: const ['Study Groups', 'Reading Circles', 'Quiet Hours', 'Collaboration'],
                sectionTitle: 'Student Life',
                sectionSubtitle: 'Spaces designed for you',
                height: 180,
                cardWidth: 220,
                onTap: (i) => Navigator.pushNamed(context, AppRoutes.catalog),
              ),
            ),

          // ---- LIBRARIANS CAROUSEL ----
          SliverToBoxAdapter(
            child: ImageCarousel(
              imagePaths: ImageAssets.librarianScenes,
              captions: const ['Circulation Desk', 'Reference Help', 'Cataloging'],
              subCaptions: const [
                'Issue & return',
                'Research support',
                'New acquisitions',
              ],
              sectionTitle: 'Our Librarians',
              sectionSubtitle: 'Visit us at the front desk',
              height: 180,
              cardWidth: 220,
              onViewAll: user.isAdmin
                  ? () => Navigator.pushNamed(context, AppRoutes.userManagement)
                  : null,
            ),
          ),

          // ---- Recent activity ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Container(width: 3, height: 14, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const Spacer(),
                  if (user.canIssueBooks)
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.loanHistory),
                      child: const Text('View all'),
                    ),
                ],
              ),
            ),
          ),
          if (recent.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No borrowing activity yet',
                  message: 'When books are issued or returned, the activity will appear here.',
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => ActivityTile(
                  icon: _iconForLoan(recent[i]),
                  iconColor: _colorForLoan(recent[i]),
                  title: recent[i].loan.isReturned
                      ? '${recent[i].userName} returned "${recent[i].bookTitle}"'
                      : '${recent[i].userName} borrowed "${recent[i].bookTitle}"',
                  subtitle: 'Due ${DateUtilsX.formatDate(recent[i].loan.dueDate)}',
                  time: DateUtilsX.relative(recent[i].loan.issueDate),
                ),
                childCount: recent.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  String _greeting(String name) {
    final h = DateTime.now().hour;
    final prefix = h < 12 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening';
    final first = name.split(' ').firstOrNull ?? name;
    return '$prefix, $first';
  }

  List<Widget> _statCards(BuildContext context, DashboardStats s, User user) {
    final cards = <Widget>[];
    if (user.isAdmin || user.isLibrarian) {
      cards
        ..add(StatCard(
          label: 'Total Titles',
          value: s.totalBooks.toString(),
          icon: Icons.library_books_rounded,
          accent: AppTheme.primary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.catalog),
        ))
        ..add(StatCard(
          label: 'Available Copies',
          value: s.availableBooks.toString(),
          icon: Icons.check_circle_outline_rounded,
          accent: AppTheme.success,
          onTap: () => Navigator.pushNamed(context, AppRoutes.catalog),
        ))
        ..add(StatCard(
          label: 'Borrowed Copies',
          value: s.borrowedBooks.toString(),
          icon: Icons.bookmark_rounded,
          accent: AppTheme.warning,
          onTap: () => Navigator.pushNamed(context, AppRoutes.loanHistory),
        ))
        ..add(StatCard(
          label: 'Overdue',
          value: s.overdueLoans.toString(),
          icon: Icons.error_outline_rounded,
          accent: AppTheme.danger,
          onTap: () => Navigator.pushNamed(context, AppRoutes.loanHistory),
        ));
    }
    if (user.isAdmin) {
      cards
        ..add(StatCard(
          label: 'Students',
          value: s.registeredStudents.toString(),
          icon: Icons.people_outline_rounded,
          accent: AppTheme.burgundy,
          onTap: () => Navigator.pushNamed(context, AppRoutes.userManagement),
        ))
        ..add(StatCard(
          label: 'Total Loans',
          value: s.totalLoans.toString(),
          icon: Icons.history_rounded,
          accent: AppTheme.accentDark,
          onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
        ));
    }
    if (user.isStudent) {
      cards
        ..add(StatCard(
          label: 'Available Books',
          value: s.availableBooks.toString(),
          icon: Icons.check_circle_outline_rounded,
          accent: AppTheme.success,
          onTap: () => Navigator.pushNamed(context, AppRoutes.catalog),
        ))
        ..add(StatCard(
          label: 'Total Titles',
          value: s.totalBooks.toString(),
          icon: Icons.library_books_rounded,
          accent: AppTheme.primary,
          onTap: () => Navigator.pushNamed(context, AppRoutes.catalog),
        ))
        ..add(StatCard(
          label: 'Borrowed Copies',
          value: s.borrowedBooks.toString(),
          icon: Icons.bookmark_rounded,
          accent: AppTheme.warning,
          onTap: () => Navigator.pushNamed(context, AppRoutes.myLoans),
        ))
        ..add(StatCard(
          label: 'Overdue',
          value: s.overdueLoans.toString(),
          icon: Icons.error_outline_rounded,
          accent: AppTheme.danger,
        ));
    }
    return cards;
  }

  IconData _iconForLoan(LoanDetail l) =>
      l.loan.isReturned ? Icons.assignment_returned : Icons.local_library;
  Color _colorForLoan(LoanDetail l) => l.loan.isReturned
      ? AppTheme.success
      : (l.loan.isOverdue ? AppTheme.danger : AppTheme.primary);
}

class _Header extends StatelessWidget {
  final User user;
  final int unreadCount;
  const _Header({required this.user, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryLight],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  const BrandMark(size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.universityName,
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontFamily: 'PT Serif',
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          AppConstants.appName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Playfair Display',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final User user;
  const _QuickActions({required this.user});

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionItem>[
      _ActionItem(
        icon: Icons.search_rounded,
        label: 'Search Catalog',
        color: AppTheme.primary,
        onTap: () => Navigator.pushNamed(context, AppRoutes.catalog),
      ),
      if (user.isStudent)
        _ActionItem(
          icon: Icons.bookmark_border_rounded,
          label: 'My Loans',
          color: AppTheme.warning,
          onTap: () => Navigator.pushNamed(context, AppRoutes.myLoans),
        ),
      if (user.canIssueBooks)
        _ActionItem(
          icon: Icons.local_library_rounded,
          label: 'Issue Book',
          color: AppTheme.burgundy,
          onTap: () => Navigator.pushNamed(context, AppRoutes.issueLoan),
        ),
      if (user.canIssueBooks)
        _ActionItem(
          icon: Icons.assignment_return_rounded,
          label: 'Return Book',
          color: AppTheme.success,
          onTap: () => Navigator.pushNamed(context, AppRoutes.returnLoan),
        ),
      if (user.canManageBooks)
        _ActionItem(
          icon: Icons.add_circle_outline_rounded,
          label: 'Add Book',
          color: AppTheme.accentDark,
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.bookForm, arguments: null),
        ),
      if (user.isAdmin)
        _ActionItem(
          icon: Icons.assessment_rounded,
          label: 'Reports',
          color: AppTheme.burgundy,
          onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: actions
            .map((a) => InkWell(
                  onTap: a.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 86,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E0D5), width: 1),
                    ),
                    child: Column(
                      children: [
                        Icon(a.icon, color: a.color, size: 22),
                        const SizedBox(height: 6),
                        Text(
                          a.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'PT Serif',
                            fontSize: 11.5,
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
}
