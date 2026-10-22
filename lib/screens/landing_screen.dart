import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/library_info.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/landing_provider.dart';
import '../routes/app_routes.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/image_assets.dart';
import '../utils/validators.dart';
import '../widgets/app_header_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/image_carousel.dart';
import '../widgets/ken_burns_hero.dart';
import '../widgets/stat_card.dart';

/// Public landing page accessible without login (also reachable from the
/// dashboard drawer). All content is sourced from the local SQLite DB:
/// - Hero: Ken Burns rotating panoramas (already DB-backed via image assets)
/// - About: contact info (settings table) + live stats from books/loans/users
/// - Services: library_services table (admin-editable)
/// - How It Works: library_steps table (admin-editable)
/// - Contact: contact info (settings table) + form that writes to contact_messages
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollCtrl = ScrollController();
  final _sectionKeys = <String, GlobalKey>{
    'hero': GlobalKey(),
    'about': GlobalKey(),
    'services': GlobalKey(),
    'how': GlobalKey(),
    'contact': GlobalKey(),
  };
  String _activeSection = 'hero';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final landing = context.read<LandingProvider>();
    await landing.loadAll();
  }

  void _onScroll() {
    // Highlight the section currently in view.
    final offset = _scrollCtrl.offset;
    String next = _activeSection;
    for (final entry in _sectionKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero).dy;
      // Section is "active" if its top edge is within 200px of the screen top.
      if (pos < 220 && pos > -box.size.height) {
        next = entry.key;
      }
    }
    if (next != _activeSection) {
      setState(() => _activeSection = next);
    }
  }

  void _scrollTo(String section) {
    final ctx = _sectionKeys[section]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      alignment: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final landing = context.watch<LandingProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final contact = landing.contact;
    final services = landing.services;
    final steps = landing.steps;
    final stats = landing.stats;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              // Sticky brand bar
              SliverAppBar(
                pinned: true,
                expandedHeight: 0,
                toolbarHeight: 56,
                automaticallyImplyLeading: false,
                backgroundColor: AppTheme.primary,
                title: Row(
                  children: [
                    const BrandMark(size: 30),
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
                              fontSize: 9.5,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            AppConstants.appName,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Playfair Display',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      onPressed: _load,
                      tooltip: 'Refresh',
                    ),
                    if (!isLoggedIn)
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, AppRoutes.login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: AppTheme.primaryDark,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(
                            fontFamily: 'PT Serif',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Sign In'),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.dashboard_rounded, color: Colors.white),
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, AppRoutes.dashboard),
                        tooltip: 'Dashboard',
                      ),
                  ],
                ),
              ),

              // Sticky section nav bar — horizontally scrollable chips
              SliverPersistentHeader(
                pinned: true,
                delegate: _SectionNavBar(
                  active: _activeSection,
                  onJump: _scrollTo,
                ),
              ),

              // ===== SECTION: HERO =====
              SliverToBoxAdapter(
                key: _sectionKeys['hero'],
                child: Column(
                  children: [
                    KenBurnsHero(
                      imagePaths: ImageAssets.heroPanoramas,
                      titles: ImageAssets.heroCaptions,
                      subtitles: ImageAssets.heroSubCaptions,
                      height: 280,
                      perImage: const Duration(seconds: 7),
                      fadeDuration: const Duration(milliseconds: 1200),
                      onTap: isLoggedIn
                          ? () => Navigator.pushReplacementNamed(
                              context, AppRoutes.catalog)
                          : () => _scrollTo('about'),
                    ),
                    // Tagline strip below hero
                    Container(
                      width: double.infinity,
                      color: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      child: Text(
                        contact?.tagline ?? AppConstants.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontFamily: 'Playfair Display',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== SECTION: ABOUT =====
              SliverToBoxAdapter(
                key: _sectionKeys['about'],
                child: _AboutSection(contact: contact, stats: stats),
              ),

              // ===== SECTION: SERVICES =====
              SliverToBoxAdapter(
                key: _sectionKeys['services'],
                child: _ServicesSection(services: services),
              ),

              // ===== SECTION: HOW IT WORKS =====
              SliverToBoxAdapter(
                key: _sectionKeys['how'],
                child: _HowItWorksSection(steps: steps),
              ),

              // ===== SECTION: CONTACT =====
              SliverToBoxAdapter(
                key: _sectionKeys['contact'],
                child: _ContactSection(contact: contact),
              ),

              // Footer
              SliverToBoxAdapter(
                child: _Footer(contact: contact),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Sticky horizontal section nav bar
// ============================================================
class _SectionNavBar extends SliverPersistentHeaderDelegate {
  final String active;
  final void Function(String) onJump;
  _SectionNavBar({required this.active, required this.onJump});

  static const _items = <_NavItem>[
    _NavItem(key: 'hero', label: 'Hero', icon: Icons.home_rounded),
    _NavItem(key: 'about', label: 'About', icon: Icons.info_outline_rounded),
    _NavItem(key: 'services', label: 'Services', icon: Icons.apps_outlined),
    _NavItem(key: 'how', label: 'How It Works', icon: Icons.timeline_rounded),
    _NavItem(key: 'contact', label: 'Contact', icon: Icons.mail_outline_rounded),
  ];

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: AppTheme.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final item = _items[i];
          final isActive = item.key == active;
          return _SectionChip(
            label: item.label,
            icon: item.icon,
            active: isActive,
            onTap: () => onJump(item.key),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_SectionNavBar oldDelegate) =>
      oldDelegate.active != active;
}

class _NavItem {
  final String key;
  final String label;
  final IconData icon;
  const _NavItem({required this.key, required this.label, required this.icon});
}

class _SectionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _SectionChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppTheme.accent : Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? AppTheme.primaryDark : Colors.white70,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'PT Serif',
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? AppTheme.primaryDark : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// About section
// ============================================================
class _AboutSection extends StatelessWidget {
  final LibraryContactInfo? contact;
  final DashboardStats? stats;
  const _AboutSection({this.contact, this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cream,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('About the Library', 'Our mission, vision, and history'),
          if (contact == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            // Mission + Vision cards
            Row(
              children: [
                Expanded(child: _aboutCard(
                  'Our Mission',
                  contact!.mission,
                  Icons.flag_outlined,
                  AppTheme.primary,
                )),
                const SizedBox(width: 10),
                Expanded(child: _aboutCard(
                  'Our Vision',
                  contact!.vision,
                  Icons.visibility_outlined,
                  AppTheme.burgundy,
                )),
              ],
            ),
            const SizedBox(height: 12),
            // History block
            _aboutCard(
              'Our History',
              contact!.history,
              Icons.history_edu_outlined,
              AppTheme.accentDark,
              fullWidth: true,
            ),
            const SizedBox(height: 18),
            // Live stats from the database
            _miniSectionHeader('Library at a Glance'),
            const SizedBox(height: 8),
            if (stats == null)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.05,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _miniStat('${stats!.totalBooks}', 'Titles',
                      Icons.library_books_rounded, AppTheme.primary),
                  _miniStat('${stats!.availableBooks}', 'Available',
                      Icons.check_circle_outline_rounded, AppTheme.success),
                  _miniStat('${stats!.borrowedBooks}', 'On Loan',
                      Icons.bookmark_rounded, AppTheme.warning),
                  _miniStat('${stats!.registeredStudents}', 'Students',
                      Icons.people_outline_rounded, AppTheme.burgundy),
                  _miniStat('${stats!.activeLoans}', 'Active Loans',
                      Icons.local_library_rounded, AppTheme.accentDark),
                  _miniStat('${stats!.overdueLoans}', 'Overdue',
                      Icons.error_outline_rounded, AppTheme.danger),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _aboutCard(String title, String body, IconData icon, Color color,
      {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E0D5), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'PT Serif',
              fontSize: 12,
              color: AppTheme.ink,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniSectionHeader(String text) => Row(
        children: [
          Container(width: 3, height: 12, color: AppTheme.accent),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ],
      );

  Widget _miniStat(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E0D5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'PT Serif',
              fontSize: 9.5,
              color: AppTheme.slate,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Services section
// ============================================================
class _ServicesSection extends StatelessWidget {
  final List<LibraryService> services;
  const _ServicesSection({required this.services});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cream,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Our Services', 'What the library offers'),
          const SizedBox(height: 12),
          if (services.isEmpty)
            const EmptyState(
              icon: Icons.apps_outlined,
              title: 'No services configured',
              message: 'Administrators can add services in the Library Info editor.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemBuilder: (context, i) {
                final s = services[i];
                final palette = _paletteFor(i);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E0D5)),
                    boxShadow: [
                      BoxShadow(
                        color: palette.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: palette.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: palette.withOpacity(0.35), width: 1),
                        ),
                        child: Icon(s.icon, color: palette, size: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.title,
                        style: const TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        child: Text(
                          s.description,
                          style: const TextStyle(
                            fontFamily: 'PT Serif',
                            fontSize: 10.5,
                            color: AppTheme.slate,
                            height: 1.35,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _paletteFor(int i) {
    const colors = [
      AppTheme.primary,
      AppTheme.burgundy,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.accentDark,
      AppTheme.danger,
      AppTheme.primaryLight,
      AppTheme.accent,
    ];
    return colors[i % colors.length];
  }
}

// ============================================================
// How It Works section
// ============================================================
class _HowItWorksSection extends StatelessWidget {
  final List<LibraryStep> steps;
  const _HowItWorksSection({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cream,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('How It Works', 'Borrowing in 4 simple steps'),
          const SizedBox(height: 12),
          if (steps.isEmpty)
            const EmptyState(
              icon: Icons.timeline_rounded,
              title: 'No steps configured',
              message: 'Administrators can configure workflow steps.',
            )
          else
            // Vertical stepper with connector line
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E0D5)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  for (int i = 0; i < steps.length; i++) ...[
                    _StepRow(step: steps[i]),
                    if (i < steps.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: SizedBox(
                          height: 24,
                          child: VerticalDivider(
                            color: AppTheme.accent.withOpacity(0.55),
                            thickness: 1.6,
                            width: 1.6,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final LibraryStep step;
  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number badge
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.accent, width: 1.4),
          ),
          child: Center(
            child: Text(
              '${step.stepNumber}',
              style: const TextStyle(
                color: AppTheme.accent,
                fontFamily: 'Playfair Display',
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(step.icon, color: AppTheme.burgundy, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                step.description,
                style: const TextStyle(
                  fontFamily: 'PT Serif',
                  fontSize: 12,
                  color: AppTheme.slate,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Contact section
// ============================================================
class _ContactSection extends StatefulWidget {
  final LibraryContactInfo? contact;
  const _ContactSection({this.contact});

  @override
  State<_ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<_ContactSection> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final landing = context.read<LandingProvider>();
    final ok = await landing.submitContactMessage(
      name: _name.text.trim(),
      email: _email.text.trim(),
      subject: _subject.text.trim(),
      message: _message.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _name.clear();
      _email.clear();
      _subject.clear();
      _message.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your message has been delivered to the library.'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(landing.error ?? 'Could not send message.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;
    return Container(
      color: AppTheme.cream,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Contact Us', 'Reach out — we love to hear from you'),
          const SizedBox(height: 12),
          if (contact == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Contact info cards (left column on wide screens, stacked on mobile)
            Row(
              children: [
                Expanded(child: _contactTile('Email', contact.email,
                    Icons.mail_outline_rounded, AppTheme.primary)),
                const SizedBox(width: 8),
                Expanded(child: _contactTile('Phone', contact.phone,
                    Icons.phone_outlined, AppTheme.success)),
              ],
            ),
            const SizedBox(height: 8),
            _contactTile('Address', contact.address,
                Icons.location_on_outlined, AppTheme.burgundy, full: true),
            const SizedBox(height: 8),
            _contactTile('Opening Hours', contact.hours,
                Icons.schedule_rounded, AppTheme.warning, full: true),
            const SizedBox(height: 14),
            // Quick message form — writes to contact_messages table
            _miniHeader('Send us a message'),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _formField(_name, 'Name',
                            validator: (v) => Validators.required(v, label: 'Name')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _formField(_email, 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => Validators.email(v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _formField(_subject, 'Subject',
                      validator: (v) => Validators.required(v, label: 'Subject')),
                  const SizedBox(height: 8),
                  _formField(_message, 'Message', maxLines: 4,
                      validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Message must be at least 10 characters';
                    }
                    return null;
                  }),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _submit,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Send Message'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactTile(String label, String value, IconData icon, Color color,
      {bool full = false}) {
    return Container(
      width: full ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E0D5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'PT Serif',
                    fontSize: 10,
                    color: AppTheme.slate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'PT Serif',
                    fontSize: 12,
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniHeader(String text) => Row(
        children: [
          Container(width: 3, height: 12, color: AppTheme.accent),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ],
      );

  Widget _formField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
        ),
        validator: validator,
      );
}

// ============================================================
// Footer
// ============================================================
class _Footer extends StatelessWidget {
  final LibraryContactInfo? contact;
  const _Footer({this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.primaryDark,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          const BrandMark(size: 36),
          const SizedBox(height: 10),
          const Text(
            AppConstants.appName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Playfair Display',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            contact?.tagline ?? AppConstants.tagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.accent,
              fontFamily: 'PT Serif',
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          if (contact != null)
            Text(
              '${contact!.email} · ${contact!.phone}',
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'PT Serif',
                fontSize: 11,
              ),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (contact?.facebook != null)
                _socialBtn(Icons.facebook_outlined, () {}),
              if (contact?.twitter != null) ...[
              const SizedBox(width: 8),
              _socialBtn(Icons.alternate_email_rounded, () {}),
              ],
              if (contact?.instagram != null) ...[
              const SizedBox(width: 8),
              _socialBtn(Icons.camera_alt_outlined, () {}),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '© ${DateTime.now().year} ${AppConstants.universityName} · '
            'IULMS v1.0.0',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontFamily: 'PT Serif',
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
          ),
          child: Icon(icon, color: AppTheme.accent, size: 16),
        ),
      );
}

// ============================================================
// Shared section title component
// ============================================================
Widget _sectionTitle(String title, String subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(width: 4, height: 22, color: AppTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'PT Serif',
            fontSize: 12.5,
            color: AppTheme.slate,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      const SizedBox(height: 4),
    ],
  );
}
