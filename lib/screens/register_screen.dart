import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import '../widgets/app_header_bar.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _studentId = TextEditingController();
  final _department = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _studentId.dispose();
    _department.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.registerStudent(
      fullName: _name.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      studentId: _studentId.text.trim(),
      department: _department.text.trim().isEmpty ? null : _department.text.trim(),
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Welcome to Injibara Library.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (_) => false);
    } else if (auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppTheme.danger),
      );
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: const AppHeaderBar(
        title: 'Create Student Account',
        subtitle: 'Injibara University Library',
        showBack: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth > 600;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Student Registration',
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Use your university Student ID and a valid email. '
                              'Your account will be active immediately.',
                              style: TextStyle(
                                fontFamily: 'PT Serif',
                                fontSize: 12.5,
                                color: AppTheme.slate,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _field(_name, 'Full name', 'e.g. Selam Bekele',
                                validator: (v) => Validators.required(v, label: 'Full name')),
                            _field(_username, 'Username', 'lowercase, no spaces',
                                validator: (v) => Validators.username(v)),
                            _field(_email, 'Email', 'you@injibara.edu',
                                validator: (v) => Validators.email(v),
                                keyboardType: TextInputType.emailAddress),
                            Row(
                              children: [
                                Expanded(
                                  child: _field(_studentId, 'Student ID', 'LIB/2025/...',
                                      validator: (v) => Validators.studentId(v)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _field(_department, 'Department', 'optional',
                                      validator: null),
                                ),
                              ],
                            ),
                            _field(_password, 'Password', 'min 6 chars',
                                obscure: _obscure,
                                suffix: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                validator: (v) => Validators.password(v)),
                            _field(_confirm, 'Confirm password', 're-enter',
                                obscure: _obscure,
                                validator: (v) =>
                                    Validators.confirmPassword(v, _password.text)),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: auth.isLoading ? null : _submit,
                                icon: const Icon(Icons.check_circle_outline_rounded),
                                label: const Text('Create Account'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Already have an account? Sign in'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixIcon: suffix,
          ),
          validator: validator,
        ),
      );
}
