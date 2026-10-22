import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _roleFilter = 'all';
  List<User> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);
    _users = await auth.listUsers(roleFilter: _roleFilter == 'all' ? null : _roleFilter);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final me = auth.currentUser!;
    return Scaffold(
      backgroundColor: AppTheme.cream,
      drawer: const AppDrawer(),
      appBar: AppHeaderBar(
        title: 'User Management',
        subtitle: '${_users.length} account(s) shown',
        showMenu: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _openCreateForm(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.cream,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Wrap(
              spacing: 8,
              children: [
                _chip('All', 'all'),
                _chip('Admins', Role.admin),
                _chip('Librarians', Role.librarian),
                _chip('Students', Role.student),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
                : _users.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No users match this filter',
                        message: 'Create the first account for this role.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 60),
                        itemCount: _users.length,
                        itemBuilder: (context, i) {
                          final u = _users[i];
                          final isSelf = u.id == me.id;
                          return _userCard(context, u, isSelf, auth);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String role) {
    final selected = _roleFilter == role;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _roleFilter = role);
        _load();
      },
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.ink,
        fontFamily: 'PT Serif',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFD6CFBE)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _userCard(BuildContext context, User u, bool isSelf, AuthProvider auth) {
    final color = u.role == Role.admin
        ? AppTheme.burgundy
        : u.role == Role.librarian
            ? AppTheme.accentDark
            : AppTheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.18),
              child: Text(
                u.fullName.isNotEmpty ? u.fullName.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          u.fullName,
                          style: const TextStyle(
                            fontFamily: 'PT Serif',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'PT Serif',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${u.studentId ?? '—'} · ${u.email}',
                    style: const TextStyle(
                      fontFamily: 'PT Serif',
                      fontSize: 11.5,
                      color: AppTheme.slate,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Text(
                          Role.labelOf(u.role),
                          style: TextStyle(
                            color: color,
                            fontFamily: 'PT Serif',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: u.isActive ? AppTheme.success : AppTheme.danger,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          u.isActive ? 'Active' : 'Deactivated',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'PT Serif',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (u.id != me.id && u.isActive)
              IconButton(
                icon: const Icon(Icons.block_rounded, color: AppTheme.danger),
                onPressed: () => _deactivate(u, auth),
                tooltip: 'Deactivate',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deactivate(User u, AuthProvider auth) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Deactivate account',
      message: 'Deactivating "${u.fullName}" prevents them from signing in. '
          'Existing loan records are preserved. This action can be reversed later.',
      confirmLabel: 'Deactivate',
      destructive: true,
    );
    if (confirmed != true) return;
    await auth.deactivateUser(u.id!);
    _load();
  }

  Future<void> _openCreateForm() {
    return showDialog(
      context: context,
      builder: (_) => const _CreateUserDialog(),
    ).then((_) => _load());
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _studentId = TextEditingController();
  final _department = TextEditingController();
  final _password = TextEditingController();
  String _role = Role.student;
  bool _obscure = true;
  bool _working = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _studentId.dispose();
    _department.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _working = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.createUserByAdmin(
      fullName: _name.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      role: _role,
      studentId: _role == Role.student ? _studentId.text.trim() : null,
      department: _department.text.trim().isEmpty ? null : _department.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not create account.'),
            backgroundColor: AppTheme.danger),
      );
      auth.clearError();
    }
    if (mounted) setState(() => _working = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('New Account',
          style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: Role.student, child: Text('Student')),
                    DropdownMenuItem(value: Role.librarian, child: Text('Librarian')),
                    DropdownMenuItem(value: Role.admin, child: Text('Administrator')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? Role.student),
                ),
                _f(_name, 'Full name', 'e.g. Almaz Tesfaye', validator: (v) => Validators.required(v, label: 'Full name')),
                _f(_username, 'Username', 'lowercase, no spaces', validator: (v) => Validators.username(v)),
                _f(_email, 'Email', 'user@injibara.edu', validator: (v) => Validators.email(v), keyboardType: TextInputType.emailAddress),
                if (_role == Role.student)
                  _f(_studentId, 'Student ID', 'LIB/2025/...',
                      validator: (v) => Validators.studentId(v)),
                _f(_department, 'Department', 'optional'),
                _f(_password, 'Temporary password', 'min 6 chars',
                    obscure: _obscure,
                    validator: (v) => Validators.password(v),
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )),
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
          onPressed: _working ? null : _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Widget _f(TextEditingController c, String label, String hint,
      {bool obscure = false,
      Widget? suffix,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label, hintText: hint, suffixIcon: suffix),
          validator: validator,
        ),
      );
}
