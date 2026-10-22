import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/validators.dart';
import '../widgets/app_header_bar.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _checkedInit = false;
  bool _needsInitialAdmin = false;
  bool _selfRegEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInit());
  }

  Future<void> _checkInit() async {
    final auth = context.read<AuthProvider>();
    final needs = await auth.needsInitialAdmin();
    final enabled = await auth.selfRegistrationEnabled();
    setState(() {
      _needsInitialAdmin = needs;
      _selfRegEnabled = enabled;
      _checkedInit = true;
    });
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_identifier.text.trim(), _password.text);
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else if (auth.error != null && mounted) {
      _showSnack(auth.error!);
      auth.clearError();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primaryDark],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth > 600;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 460 : double.infinity),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),
                        const BrandMark(size: 64),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.universityName,
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontFamily: 'PT Serif',
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Playfair Display',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontFamily: 'Playfair Display',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Access your library account with your username or email.',
                                    style: TextStyle(
                                      fontFamily: 'PT Serif',
                                      fontSize: 12,
                                      color: AppTheme.slate,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _identifier,
                                    textInputAction: TextInputAction.next,
                                    textCapitalization: TextCapitalization.none,
                                    decoration: const InputDecoration(
                                      labelText: 'Username or Email',
                                      prefixIcon: Icon(Icons.person_outline, size: 20),
                                      hintText: 'e.g. jane.doe or jane@injibara.edu',
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Enter your username or email'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _password,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined),
                                        onPressed: () => setState(() => _obscure = !_obscure),
                                      ),
                                    ),
                                    validator: (v) => Validators.password(v),
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                  const SizedBox(height: 18),
                                  if (auth.isLoading)
                                    const LinearProgressIndicator()
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.login_rounded),
                                        label: const Text('Sign In'),
                                        onPressed: _submit,
                                      ),
                                    ),
                                  if (_checkedInit && (_needsInitialAdmin || _selfRegEnabled)) ...[
                                    const SizedBox(height: 14),
                                    const Divider(),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (_selfRegEnabled)
                                          TextButton(
                                            onPressed: () => Navigator.pushNamed(
                                                context, AppRoutes.register),
                                            child: const Text('Register as Student'),
                                          )
                                        else
                                          const Text('Self-registration disabled',
                                              style: TextStyle(color: AppTheme.slate, fontSize: 12)),
                                        if (_needsInitialAdmin)
                                          TextButton(
                                            onPressed: _openInitAdmin,
                                            child: const Text('Initialize Administrator'),
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Center(
                                    child: TextButton(
                                      onPressed: () => Navigator.pushReplacementNamed(
                                          context, AppRoutes.landing),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.explore_outlined, size: 14),
                                          SizedBox(width: 4),
                                          Text('Explore the Library →'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Local-only authentication: credentials are stored on this device. '
                          'Production requires a server backend for cross-device security.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'PT Serif',
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openInitAdmin() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const _InitAdminSheet(),
      fullscreenDialog: true,
    ));
  }
}

class _InitAdminSheet extends StatefulWidget {
  const _InitAdminSheet();

  @override
  State<_InitAdminSheet> createState() => _InitAdminSheetState();
}

class _InitAdminSheetState extends State<_InitAdminSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.createFirstAdmin(
      fullName: _name.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
    );
    if (ok && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (_) => false,
      );
    } else if (auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error!),
        backgroundColor: AppTheme.danger,
      ));
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppHeaderBar(
        title: 'Initialize Administrator',
        subtitle: 'First-run setup',
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.accentDark, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No administrator accounts exist on this device yet. '
                          'Create the first administrator to manage the library.',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontFamily: 'PT Serif',
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _field(_name, 'Full name', 'e.g. Selam Bekele', validator: (v) => Validators.required(v, label: 'Full name')),
                _field(_username, 'Username', 'lowercase, no spaces', validator: (v) => Validators.username(v)),
                _field(_email, 'Email', 'admin@injibara.edu', validator: (v) => Validators.email(v), keyboardType: TextInputType.emailAddress),
                _field(_password, 'Password', 'min 6 chars',
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => Validators.password(v)),
                _field(_confirm, 'Confirm password', 're-enter',
                    obscure: _obscure,
                    validator: (v) => Validators.confirmPassword(v, _password.text)),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: auth.isLoading ? null : _submit,
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    label: const Text('Create Administrator'),
                  ),
                ),
              ],
            ),
          ),
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
