import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import '../utils/date_utils.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header_bar.dart';
import '../widgets/confirm_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _email;
  late TextEditingController _department;
  late TextEditingController _currentPass;
  late TextEditingController _newPass;
  late TextEditingController _confirmPass;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().currentUser!;
    _name = TextEditingController(text: u.fullName);
    _email = TextEditingController(text: u.email);
    _department = TextEditingController(text: u.department ?? '');
    _currentPass = TextEditingController();
    _newPass = TextEditingController();
    _confirmPass = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _department.dispose();
    _currentPass.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const AppHeaderBar(
        title: 'My Profile',
        subtitle: 'Account information and settings',
        showMenu: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accent, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontFamily: 'Playfair Display',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.accent.withOpacity(0.45)),
                          ),
                          child: Text(
                            Role.labelOf(user.role),
                            style: const TextStyle(
                              color: AppTheme.accentDark,
                              fontFamily: 'PT Serif',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Member since ${DateUtilsX.formatDate(user.createdAt)}',
                          style: const TextStyle(
                            fontFamily: 'PT Serif',
                            fontSize: 11.5,
                            color: AppTheme.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Account information'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _department,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.school_outlined, size: 20),
                      helperText: user.isStudent ? 'Optional' : 'N/A for staff',
                    ),
                    enabled: user.isStudent,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _saveProfile(auth),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (user.isStudent) ...[
            const SizedBox(height: 16),
            _sectionTitle('Student details'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _readOnly('Student ID', user.studentId ?? '—'),
                    _readOnly('Department', user.department ?? '—'),
                    _readOnly('Account status', user.isActive ? 'Active' : 'Deactivated'),
                    _readOnly('Username', user.username),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _sectionTitle('Change password'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentPass,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPass,
                    obscureText: _obscure,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      prefixIcon: Icon(Icons.password_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPass,
                    obscureText: _obscure,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                      prefixIcon: Icon(Icons.enhanced_encryption_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _changePassword(auth),
                      icon: const Icon(Icons.vpn_key_outlined, size: 18),
                      label: const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppTheme.danger.withOpacity(0.05),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 22),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  fontFamily: 'PT Serif',
                  fontWeight: FontWeight.w700,
                  color: AppTheme.danger,
                ),
              ),
              subtitle: const Text(
                'You will need to sign in again to access the library.',
                style: TextStyle(fontFamily: 'PT Serif', fontSize: 12, color: AppTheme.slate),
              ),
              onTap: () async {
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Sign out',
                  message: 'Are you sure you want to sign out of your account?',
                  confirmLabel: 'Sign Out',
                  destructive: true,
                );
                if (confirmed != true) return;
                await auth.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 6),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
      );

  Widget _readOnly(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.slate,
                  fontFamily: 'PT Serif',
                  fontSize: 12.5,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontFamily: 'PT Serif',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _saveProfile(AuthProvider auth) async {
    final ok = await auth.updateProfile(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      department: _department.text.trim().isEmpty ? null : _department.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile updated.' : (auth.error ?? 'Could not update profile.')),
        backgroundColor: ok ? AppTheme.success : AppTheme.danger,
      ),
    );
    if (!ok) auth.clearError();
  }

  Future<void> _changePassword(AuthProvider auth) async {
    if (Validators.password(_newPass.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    if (_newPass.text != _confirmPass.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    final ok = await auth.changePassword(_currentPass.text, _newPass.text);
    if (!mounted) return;
    if (ok) {
      _currentPass.clear();
      _newPass.clear();
      _confirmPass.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Password updated.' : (auth.error ?? 'Could not update password.')),
        backgroundColor: ok ? AppTheme.success : AppTheme.danger,
      ),
    );
    if (!ok) auth.clearError();
  }
}
