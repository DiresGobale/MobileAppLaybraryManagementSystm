import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/library_info.dart';
import '../../providers/landing_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/library_info_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';

/// Admin editor for landing-page content:
/// - About section: tagline, mission, vision, history (settings table)
/// - Services section: CRUD on library_services table
/// - How It Works section: CRUD on library_steps table
/// - Contact section: email, phone, address, hours, socials (settings table)
class LibraryInfoEditorScreen extends StatefulWidget {
  const LibraryInfoEditorScreen({super.key});

  @override
  State<LibraryInfoEditorScreen> createState() => _LibraryInfoEditorScreenState();
}

class _LibraryInfoEditorScreenState extends State<LibraryInfoEditorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  bool _loading = true;

  // About-section text controllers
  final _tagline = TextEditingController();
  final _mission = TextEditingController();
  final _vision = TextEditingController();
  final _history = TextEditingController();
  // Contact-section text controllers
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _hours = TextEditingController();
  final _facebook = TextEditingController();
  final _twitter = TextEditingController();
  final _instagram = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _tagline.dispose();
    _mission.dispose();
    _vision.dispose();
    _history.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _hours.dispose();
    _facebook.dispose();
    _twitter.dispose();
    _instagram.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final landing = context.read<LandingProvider>();
    // Service is read lazily by the nested tabs — no need to keep a reference here.
    await landing.loadAll();
    final c = landing.contact;
    if (c != null) {
      _tagline.text = c.tagline;
      _mission.text = c.mission;
      _vision.text = c.vision;
      _history.text = c.history;
      _email.text = c.email;
      _phone.text = c.phone;
      _address.text = c.address;
      _hours.text = c.hours;
      _facebook.text = c.facebook ?? '';
      _twitter.text = c.twitter ?? '';
      _instagram.text = c.instagram ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveAbout() async {
    final svc = context.read<LibraryInfoService>();
    final auth = context.read<AuthProvider>();
    final actorId = auth.currentUser?.id;
    await Future.wait([
      svc.setSetting(AppConstants.keyLibraryTagline, _tagline.text.trim(), actorId: actorId),
      svc.setSetting(AppConstants.keyLibraryMission, _mission.text.trim(), actorId: actorId),
      svc.setSetting(AppConstants.keyLibraryVision, _vision.text.trim(), actorId: actorId),
      svc.setSetting(AppConstants.keyLibraryHistory, _history.text.trim(), actorId: actorId),
    ]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('About content saved.'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _saveContact() async {
    final svc = context.read<LibraryInfoService>();
    final auth = context.read<AuthProvider>();
    final actorId = auth.currentUser?.id;
    await Future.wait([
      svc.setSetting(AppConstants.keyContactEmail, _email.text.trim(), actorId: actorId),
      svc.setSetting(AppConstants.keyContactPhone, _phone.text.trim(), actorId: actorId),
      svc.setSetting(AppConstants.keyContactAddress, _address.text.trim(), actorId: actorId),
      svc.setSetting(AppConstants.keyContactHours, _hours.text.trim(), actorId: actorId),
      svc.setSetting(AppConstants.keyContactFacebook, _facebook.text.trim(), actorId: actorId),
      svc.setSetting(AppConstants.keyContactTwitter, _twitter.text.trim(), actorId: actorId),
      svc.setSetting(AppConstants.keyContactInstagram, _instagram.text.trim(), actorId: actorId),
    ]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact info saved.'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final landing = context.watch<LandingProvider>();
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppHeaderBar(
        title: 'Library Info Editor',
        subtitle: 'Manage landing page content',
        showMenu: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Material(
                  color: AppTheme.primary,
                  child: TabBar(
                    controller: _tabs,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: AppTheme.accent,
                    indicatorWeight: 3,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Services'),
                      Tab(text: 'How It Works'),
                      Tab(text: 'Contact'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _AboutTab(
                        tagline: _tagline,
                        mission: _mission,
                        vision: _vision,
                        history: _history,
                        onSave: _saveAbout,
                      ),
                      _ServicesTab(services: landing.services),
                      _StepsTab(steps: landing.steps),
                      _ContactTab(
                        email: _email,
                        phone: _phone,
                        address: _address,
                        hours: _hours,
                        facebook: _facebook,
                        twitter: _twitter,
                        instagram: _instagram,
                        onSave: _saveContact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------- ABOUT TAB ----------------
class _AboutTab extends StatelessWidget {
  final TextEditingController tagline, mission, vision, history;
  final VoidCallback onSave;
  const _AboutTab({
    required this.tagline,
    required this.mission,
    required this.vision,
    required this.history,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoBanner('About section content appears on the public landing '
              'page. Edit the tagline, mission, vision, and history.'),
          _field(tagline, 'Tagline', 'e.g. Knowledge · Heritage · Discovery'),
          _field(mission, 'Mission', 'A paragraph describing the mission',
              maxLines: 4),
          _field(vision, 'Vision', 'A paragraph describing the vision',
              maxLines: 4),
          _field(history, 'History', 'A brief history of the library',
              maxLines: 5),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save About Content'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- SERVICES TAB ----------------
class _ServicesTab extends StatefulWidget {
  final List<LibraryService> services;
  const _ServicesTab({required this.services});
  @override
  State<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<_ServicesTab> {
  @override
  Widget build(BuildContext context) {
    final svc = context.read<LibraryInfoService>();
    final items = widget.services;
    return Stack(
      children: [
        items.isEmpty
            ? const Center(
                child: EmptyState(
                  icon: Icons.apps_outlined,
                  title: 'No services yet',
                  message: 'Tap the + button to add the first service.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: items.length,
                itemBuilder: (context, i) => _ServiceCard(
                  service: items[i],
                  onEdit: () => _openEditor(svc, items[i]),
                  onDelete: () => _delete(svc, items[i]),
                ),
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: AppTheme.accent,
            foregroundColor: AppTheme.primaryDark,
            onPressed: () => _openEditor(svc, null),
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(LibraryInfoService svc, LibraryService? existing) async {
    await showDialog(
      context: context,
      builder: (_) => _ServiceDialog(service: existing),
    );
    if (!mounted) return;
    await context.read<LandingProvider>().loadAll();
    setState(() {});
  }

  Future<void> _delete(LibraryInfoService svc, LibraryService s) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete service',
      message: 'Delete "${s.title}"? This change is reflected immediately on '
          'the landing page.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;
    final auth = context.read<AuthProvider>();
    await svc.deleteService(s.id!, actorId: auth.currentUser?.id, title: s.title);
    if (!mounted) return;
    await context.read<LandingProvider>().loadAll();
    setState(() {});
  }
}

class _ServiceCard extends StatelessWidget {
  final LibraryService service;
  final VoidCallback onEdit, onDelete;
  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withOpacity(0.35)),
          ),
          child: Icon(service.icon, color: AppTheme.primary, size: 18),
        ),
        title: Text(service.title),
        subtitle: Text(
          service.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 18),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  final LibraryService? service;
  const _ServiceDialog({this.service});
  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title, _desc, _icon, _order;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.service?.title ?? '');
    _desc = TextEditingController(text: widget.service?.description ?? '');
    _icon = TextEditingController(text: widget.service?.iconName ?? 'menu_book');
    _order = TextEditingController(
        text: (widget.service?.displayOrder ?? 1).toString());
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _icon.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final svc = context.read<LibraryInfoService>();
    final auth = context.read<AuthProvider>();
    final s = LibraryService(
      id: widget.service?.id,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      iconName: _icon.text.trim().isEmpty ? 'menu_book' : _icon.text.trim(),
      displayOrder: int.tryParse(_order.text.trim()) ?? 1,
      isActive: true,
    );
    await svc.saveService(s, actorId: auth.currentUser?.id, isNew: widget.service == null);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(widget.service == null ? 'New Service' : 'Edit Service',
          style: const TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => Validators.required(v, label: 'Title'),
                ),
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) => Validators.required(v, label: 'Description'),
                ),
                TextFormField(
                  controller: _icon,
                  decoration: const InputDecoration(
                    labelText: 'Icon name',
                    helperText: 'menu_book · school · wifi · print · devices',
                  ),
                ),
                TextFormField(
                  controller: _order,
                  decoration: const InputDecoration(labelText: 'Display order'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------- STEPS TAB ----------------
class _StepsTab extends StatefulWidget {
  final List<LibraryStep> steps;
  const _StepsTab({required this.steps});
  @override
  State<_StepsTab> createState() => _StepsTabState();
}

class _StepsTabState extends State<_StepsTab> {
  @override
  Widget build(BuildContext context) {
    final svc = context.read<LibraryInfoService>();
    final items = widget.steps;
    return Stack(
      children: [
        items.isEmpty
            ? const Center(
                child: EmptyState(
                  icon: Icons.timeline_rounded,
                  title: 'No steps yet',
                  message: 'Tap + to add the first workflow step.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: items.length,
                itemBuilder: (context, i) => _StepCard(
                  step: items[i],
                  onEdit: () => _openEditor(svc, items[i]),
                  onDelete: () => _delete(svc, items[i]),
                ),
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: AppTheme.accent,
            foregroundColor: AppTheme.primaryDark,
            onPressed: () => _openEditor(svc, null),
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(LibraryInfoService svc, LibraryStep? existing) async {
    await showDialog(
      context: context,
      builder: (_) => _StepDialog(step: existing),
    );
    if (!mounted) return;
    await context.read<LandingProvider>().loadAll();
    setState(() {});
  }

  Future<void> _delete(LibraryInfoService svc, LibraryStep s) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete step',
      message: 'Delete "${s.title}"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;
    final auth = context.read<AuthProvider>();
    await svc.deleteStep(s.id!, actorId: auth.currentUser?.id, title: s.title);
    if (!mounted) return;
    await context.read<LandingProvider>().loadAll();
    setState(() {});
  }
}

class _StepCard extends StatelessWidget {
  final LibraryStep step;
  final VoidCallback onEdit, onDelete;
  const _StepCard({required this.step, required this.onEdit, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Text(
            '${step.stepNumber}',
            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(step.title),
        subtitle: Text(step.description, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 18),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDialog extends StatefulWidget {
  final LibraryStep? step;
  const _StepDialog({this.step});
  @override
  State<_StepDialog> createState() => _StepDialogState();
}

class _StepDialogState extends State<_StepDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _stepNo, _title, _desc, _icon, _order;

  @override
  void initState() {
    super.initState();
    _stepNo = TextEditingController(
        text: (widget.step?.stepNumber ?? 1).toString());
    _title = TextEditingController(text: widget.step?.title ?? '');
    _desc = TextEditingController(text: widget.step?.description ?? '');
    _icon = TextEditingController(text: widget.step?.iconName ?? 'search');
    _order = TextEditingController(
        text: (widget.step?.displayOrder ?? 1).toString());
  }

  @override
  void dispose() {
    _stepNo.dispose();
    _title.dispose();
    _desc.dispose();
    _icon.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final svc = context.read<LibraryInfoService>();
    final auth = context.read<AuthProvider>();
    final s = LibraryStep(
      id: widget.step?.id,
      stepNumber: int.tryParse(_stepNo.text.trim()) ?? 1,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      iconName: _icon.text.trim().isEmpty ? 'search' : _icon.text.trim(),
      displayOrder: int.tryParse(_order.text.trim()) ?? 1,
      isActive: true,
    );
    await svc.saveStep(s, actorId: auth.currentUser?.id, isNew: widget.step == null);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(widget.step == null ? 'New Step' : 'Edit Step',
          style: const TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _stepNo,
                  decoration: const InputDecoration(labelText: 'Step number'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => Validators.required(v, label: 'Title'),
                ),
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) => Validators.required(v, label: 'Description'),
                ),
                TextFormField(
                  controller: _icon,
                  decoration: const InputDecoration(
                    labelText: 'Icon name',
                    helperText: 'search · menu_book · local_library · assignment_return',
                  ),
                ),
                TextFormField(
                  controller: _order,
                  decoration: const InputDecoration(labelText: 'Display order'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------- CONTACT TAB ----------------
class _ContactTab extends StatelessWidget {
  final TextEditingController email, phone, address, hours, facebook, twitter, instagram;
  final VoidCallback onSave;
  const _ContactTab({
    required this.email,
    required this.phone,
    required this.address,
    required this.hours,
    required this.facebook,
    required this.twitter,
    required this.instagram,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoBanner('Contact info is shown in the landing page footer and Contact section.'),
          _field(email, 'Email', 'library@injibara.edu.et',
              keyboardType: TextInputType.emailAddress, validator: (v) => Validators.email(v)),
          _field(phone, 'Phone', '+251 58 334 0000',
              keyboardType: TextInputType.phone),
          _field(address, 'Address', 'P.O. Box 67, Injibara', maxLines: 2),
          _field(hours, 'Opening hours', 'Mon – Fri 08:00 – 22:00'),
          _field(facebook, 'Facebook URL', 'https://facebook.com/...'),
          _field(twitter, 'Twitter URL', 'https://twitter.com/...'),
          _field(instagram, 'Instagram URL', 'https://instagram.com/...'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Contact Info'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Shared helpers ----------------
Widget _infoBanner(String text) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.1),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.accentDark, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'PT Serif',
                fontSize: 12,
                color: AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );

Widget _field(
  TextEditingController controller,
  String label,
  String hint, {
  TextInputType? keyboardType,
  int maxLines = 1,
  String? Function(String?)? validator,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
