import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/database_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_source_provider.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/backend_config.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _loanDaysCtrl = TextEditingController();
  final _maxLoansCtrl = TextEditingController();
  final _libraryNameCtrl = TextEditingController();
  final _backendUrlCtrl = TextEditingController(text: 'http://10.0.2.2:4000');
  bool _selfReg = true;
  bool _librarianManageUsers = false;
  bool _voiceNav = true;
  bool _isRemote = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = SettingsRepository(DatabaseHelper.instance);
    _loanDaysCtrl.text = (await repo.getInt(AppConstants.keyLoanDays, defaultValue: 14)).toString();
    _maxLoansCtrl.text =
        (await repo.getInt(AppConstants.keyMaxActiveLoans, defaultValue: 3)).toString();
    _libraryNameCtrl.text = (await repo.get(AppConstants.keyLibraryName)) ??
        AppConstants.defaultSettings[AppConstants.keyLibraryName]!;
    _selfReg = await repo.getBool(AppConstants.keySelfRegistration, defaultValue: true);
    _librarianManageUsers =
        await repo.getBool(AppConstants.keyLibrarianCanManageUsers, defaultValue: false);
    _voiceNav = await repo.getBool(AppConstants.keyTtsEnabled, defaultValue: true);
    _isRemote = (await repo.get(AppConstants.keyDataSourceMode) ?? 'local') == 'remote';
    _backendUrlCtrl.text = (await repo.get(AppConstants.keyBackendUrl)) ?? 'http://10.0.2.2:4000';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = SettingsRepository(DatabaseHelper.instance);
    await repo.set(AppConstants.keyLoanDays, _loanDaysCtrl.text.trim());
    await repo.set(AppConstants.keyMaxActiveLoans, _maxLoansCtrl.text.trim());
    await repo.set(AppConstants.keyLibraryName, _libraryNameCtrl.text.trim());
    await repo.set(AppConstants.keySelfRegistration, _selfReg ? 'true' : 'false');
    await repo.set(AppConstants.keyLibrarianCanManageUsers, _librarianManageUsers ? 'true' : 'false');
    await repo.set(AppConstants.keyTtsEnabled, _voiceNav ? 'true' : 'false');
    await repo.set(AppConstants.keyDataSourceMode, _isRemote ? 'remote' : 'local');
    await repo.set(AppConstants.keyBackendUrl, _backendUrlCtrl.text.trim());
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved.'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  void dispose() {
    _loanDaysCtrl.dispose();
    _maxLoansCtrl.dispose();
    _libraryNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      drawer: const AppDrawer(),
      appBar: const AppHeaderBar(
        title: 'Settings',
        subtitle: 'Library policies and configuration',
        showMenu: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Borrowing policies'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _loanDaysCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Default loan period (days)',
                              prefixIcon: Icon(Icons.event_outlined, size: 20),
                              helperText: 'Used when issuing books without a custom period',
                            ),
                            validator: (v) => Validators.positiveInt(v, label: 'Loan days'),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _maxLoansCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Maximum active loans per student',
                              prefixIcon: Icon(Icons.bookmark_rounded, size: 20),
                              helperText: 'Prevents a student from borrowing too many books',
                            ),
                            validator: (v) => Validators.positiveInt(v, label: 'Max loans'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Branding'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _libraryNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Library name',
                          prefixIcon: Icon(Icons.school_outlined, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Access control'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Allow student self-registration'),
                          subtitle: const Text(
                              'When on, students can sign up from the login screen. '
                              'When off, only administrators can create student accounts.'),
                          value: _selfReg,
                          onChanged: (v) => setState(() => _selfReg = v),
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Allow librarians to manage users'),
                          subtitle: const Text(
                              'When off, only administrators can create or deactivate accounts.'),
                          value: _librarianManageUsers,
                          onChanged: (v) => setState(() => _librarianManageUsers = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Voice navigation'),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Speak destination names on tap'),
                      subtitle: const Text(
                          'When on, the app announces each sidebar/bottom-nav '
                          'destination as the user navigates — making the app '
                          'audible for users with low vision.'),
                      value: _voiceNav,
                      onChanged: (v) => setState(() => _voiceNav = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Backend Connection'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Use remote Node.js backend'),
                          subtitle: const Text(
                              'When ON, all data operations go to the backend '
                              'API via HTTP. When OFF, data is stored locally '
                              'in on-device SQLite.\n\n'
                              '⚠ Switching requires app restart.'),
                          value: _isRemote,
                          onChanged: (v) => setState(() => _isRemote = v),
                          secondary: Icon(
                            _isRemote ? Icons.cloud_outlined : Icons.storage_rounded,
                            color: _isRemote ? AppTheme.primary : AppTheme.success,
                          ),
                        ),
                        if (_isRemote) ...[
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: TextFormField(
                              controller: _backendUrlCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Backend URL',
                                helperText:
                                    'Android emulator: http://10.0.2.2:4000\n'
                                    'Real device (same Wi-Fi): http://192.168.x.x:4000',
                                prefixIcon: Icon(Icons.link_rounded),
                              ),
                            ),
                          ),
                          // Live connection status
                          Consumer<DataSourceProvider>(
                            builder: (ctx, ds, _) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      ds.isConnected
                                          ? Icons.cloud_done_rounded
                                          : Icons.cloud_off_rounded,
                                      color: ds.isConnected
                                          ? AppTheme.success
                                          : AppTheme.danger,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ds.isConnected
                                            ? 'Connected to ${ds.baseUrl}'
                                            : (ds.lastError ??
                                                'Not connected — tap Test'),
                                        style: TextStyle(
                                          color: ds.isConnected
                                              ? AppTheme.success
                                              : AppTheme.danger,
                                          fontFamily: 'PT Serif',
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => ds.testConnection(),
                                      icon: const Icon(Icons.refresh_rounded,
                                          size: 16),
                                      label: const Text('Test'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save Settings'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.accentDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'These settings apply to the local SQLite database only. '
                            'Production deployments would sync these settings through a server.',
                            style: const TextStyle(
                              fontFamily: 'PT Serif',
                              fontSize: 12,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
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
}
