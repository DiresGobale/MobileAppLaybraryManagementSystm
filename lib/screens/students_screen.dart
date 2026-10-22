import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/empty_state.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<User> _students = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    _students = await auth.listUsers(roleFilter: Role.student);
    setState(() => _loading = false);
  }

  List<User> get _filtered {
    if (_query.trim().isEmpty) return _students;
    final q = _query.toLowerCase();
    return _students
        .where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            (u.studentId?.toLowerCase().contains(q) ?? false) ||
            (u.department?.toLowerCase().contains(q) ?? false) ||
            u.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const AppHeaderBar(
        title: 'Students',
        subtitle: 'Registered student accounts',
        showMenu: true,
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.cream,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search by name, Student ID, email, or department',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
                : _filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.school_outlined,
                        title: 'No students found',
                        message: 'Students appear here after registration.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 60),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final s = _filtered[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primary.withOpacity(0.12),
                                child: Text(
                                  s.fullName.isNotEmpty
                                      ? s.fullName.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: AppTheme.primary),
                                ),
                              ),
                              title: Text(s.fullName),
                              subtitle: Text(
                                '${s.studentId ?? '—'} · ${s.department ?? 'No department'}',
                                style: const TextStyle(
                                  fontFamily: 'PT Serif',
                                  fontSize: 12,
                                  color: AppTheme.slate,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: s.isActive ? AppTheme.success : AppTheme.danger,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      s.isActive ? 'Active' : 'Inactive',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'PT Serif',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Joined ${DateUtilsX.formatDate(s.createdAt)}',
                                    style: const TextStyle(
                                      fontFamily: 'PT Serif',
                                      fontSize: 10.5,
                                      color: AppTheme.slate,
                                    ),
                                  ),
                                ],
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
}
