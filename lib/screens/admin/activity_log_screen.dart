import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/library_info_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/empty_state.dart';

/// Shows all recent activity from the `activity_logs` table. Admins and
/// librarians see all activity; students see only their own entries (role
/// scoped at the SQL layer).
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _actionFilter;
  bool _mineOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser!;
    final showMineOnly = _mineOnly || !user.isAdmin && !user.isLibrarian;
    final actorId = showMineOnly ? user.id : null;
    final repo = context.read<LibraryInfoService>().activityLogs;
    final all = await repo.recentWithUser(limit: 300, actorId: actorId);
    setState(() {
      _items = _actionFilter == null
          ? all
          : all.where((r) => r['action'] == _actionFilter).toList();
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered => _items;

  List<String> get _availableActions {
    final set = <String>{};
    for (final row in _items) {
      set.add(row['action'] as String);
    }
    return set.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    final canSeeAll = user.isAdmin || user.isLibrarian;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppHeaderBar(
        title: 'Activity Log',
        subtitle: canSeeAll ? 'All library activity' : 'Your activity only',
        showMenu: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: AppTheme.cream,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _actionFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by action',
                          isDense: true,
                          prefixIcon: Icon(Icons.filter_list_rounded, size: 18),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All actions'),
                          ),
                          ...AppConstants.knownActions.map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(AppConstants.actionLabel(a)),
                              )),
                        ],
                        onChanged: (v) {
                          setState(() => _actionFilter = v);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (canSeeAll)
                      FilterChip(
                        label: const Text('Mine only',
                            style: TextStyle(
                                fontFamily: 'PT Serif',
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        selected: _mineOnly,
                        onSelected: (v) {
                          setState(() => _mineOnly = v);
                          _load();
                        },
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: _mineOnly ? Colors.white : AppTheme.ink,
                          fontFamily: 'PT Serif',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD6CFBE)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.history_rounded,
                        title: 'No activity recorded yet',
                        message: 'Activity appears here as users sign in, '
                            'add books, issue loans, and edit library content.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 60),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final row = _filtered[i];
                          final action = row['action'] as String;
                          final details = row['details'] as String? ?? '';
                          final actorName = row['actor_name'] as String?;
                          final actorRole = row['actor_role'] as String?;
                          final when = DateTime.fromMillisecondsSinceEpoch(
                              row['created_at'] as int);
                          final color = _colorFor(action);
                          final icon = _iconFor(action);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: color.withOpacity(0.25), width: 1),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.13),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: color.withOpacity(0.35), width: 1),
                                ),
                                child: Icon(icon, color: color, size: 18),
                              ),
                              title: Text(
                                AppConstants.actionLabel(action),
                                style: const TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    details,
                                    style: const TextStyle(
                                      fontFamily: 'PT Serif',
                                      fontSize: 11.5,
                                      color: AppTheme.slate,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (actorName != null)
                                        Text(
                                          actorName,
                                          style: TextStyle(
                                            fontFamily: 'PT Serif',
                                            fontSize: 10.5,
                                            color: color,
                                            fontWeight: FontWeight.w700,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        )
                                      else
                                        const Text(
                                          'System',
                                          style: TextStyle(
                                            fontFamily: 'PT Serif',
                                            fontSize: 10.5,
                                            color: AppTheme.slate,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      if (actorRole != null) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '· ${Role.labelOf(actorRole)}',
                                          style: const TextStyle(
                                            fontFamily: 'PT Serif',
                                            fontSize: 10,
                                            color: AppTheme.slate,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      Text(
                                        '· ${DateUtilsX.relative(when)}',
                                        style: const TextStyle(
                                          fontFamily: 'PT Serif',
                                          fontSize: 10.5,
                                          color: AppTheme.slate,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Text(
                                DateUtilsX.formatDateTime(when),
                                style: const TextStyle(
                                  fontFamily: 'PT Serif',
                                  fontSize: 10,
                                  color: AppTheme.slate,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String action) {
    if (action.contains('delete') || action.contains('deactivate')) return AppTheme.danger;
    if (action.contains('reactivate') || action.contains('handled')) return AppTheme.success;
    if (action.contains('issue') || action.contains('add')) return AppTheme.primary;
    if (action.contains('return')) return AppTheme.success;
    if (action.contains('edit') || action.contains('update') || action.contains('change')) return AppTheme.warning;
    if (action.contains('login')) return AppTheme.success;
    if (action.contains('logout')) return AppTheme.slate;
    return AppTheme.accentDark;
  }

  IconData _iconFor(String action) {
    if (action.contains('login')) return Icons.login_rounded;
    if (action.contains('logout')) return Icons.logout_rounded;
    if (action.contains('book')) return Icons.menu_book_rounded;
    if (action.contains('loan') && action.contains('issue')) return Icons.local_library_rounded;
    if (action.contains('loan') && action.contains('return')) return Icons.assignment_return_rounded;
    if (action.contains('user')) return Icons.person_outline_rounded;
    if (action.contains('service')) return Icons.apps_outlined;
    if (action.contains('step')) return Icons.timeline_rounded;
    if (action.contains('contact')) return Icons.mail_outline_rounded;
    if (action.contains('library_info')) return Icons.info_outline_rounded;
    if (action.contains('settings')) return Icons.settings_outlined;
    if (action.contains('voice')) return Icons.record_voice_over_rounded;
    if (action.contains('password')) return Icons.vpn_key_outlined;
    if (action.contains('profile')) return Icons.person_rounded;
    return Icons.history_rounded;
  }
}
