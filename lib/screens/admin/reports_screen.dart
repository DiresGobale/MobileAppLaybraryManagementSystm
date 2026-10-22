import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/loan.dart';
import '../../models/report.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/report_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _range;
  List<LoanDetail> _rangeLoans = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final dash = context.read<DashboardProvider>();
    await dash.loadDashboard();
    final svc = context.read<ReportService>();
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month, now.day, 23, 59);
    _range = DateTimeRange(start: from, end: to);
    _rangeLoans = await svc.loansBetween(from, to);
    setState(() {});
  }

  Future<void> _pickRange() async {
    final initial = _range ??
        DateTimeRange(
          start: DateTime(DateTime.now().year, DateTime.now().month, 1),
          end: DateTime.now(),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initial,
    );
    if (picked == null) return;
    final svc = context.read<ReportService>();
    final loans = await svc.loansBetween(
      picked.start,
      picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
    );
    setState(() {
      _range = picked;
      _rangeLoans = loans;
    });
  }

  Future<void> _exportCsv() async {
    final svc = context.read<ReportService>();
    final csv = await svc.toCsv(_rangeLoans);
    if (!mounted) return;
    try {
      // Save to the app's external documents directory on Android (scoped storage
      // — no extra permission needed on Android 10+ for app-private files).
      // On other platforms, falls back to documents directory.
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      final file = File('${dir.path}/iulms_loans_$stamp.csv');
      await file.writeAsString(csv);
      if (!mounted) return;
      // Offer to share the file via the platform's share sheet.
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'IULMS Loan Report',
        text: 'Loan activity report exported from Injibara University Library.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.status == ShareResultStatus.success
              ? 'Report shared successfully.'
              : 'Report saved to: ${file.path}'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Fallback: show CSV text in a dialog so the user can copy it manually.
      await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Exported CSV',
              style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                csv,
                style: const TextStyle(fontFamily: 'PT Serif', fontSize: 11),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final inventory = dash.inventory;
    final popular = dash.popular;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppHeaderBar(
        title: 'Reports',
        subtitle: 'Library insights and analytics',
        showMenu: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: dash.isLoading && inventory == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionHeader('Inventory Summary'),
                if (inventory != null)
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.15,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StatCard(
                        label: 'Total Titles',
                        value: inventory.totalTitles.toString(),
                        icon: Icons.library_books_rounded,
                        accent: AppTheme.primary,
                      ),
                      StatCard(
                        label: 'Total Copies',
                        value: inventory.totalCopies.toString(),
                        icon: Icons.inventory_2_outlined,
                        accent: AppTheme.burgundy,
                      ),
                      StatCard(
                        label: 'Available',
                        value: inventory.availableCopies.toString(),
                        icon: Icons.check_circle_outline_rounded,
                        accent: AppTheme.success,
                      ),
                      StatCard(
                        label: 'Borrowed',
                        value: inventory.borrowedCopies.toString(),
                        icon: Icons.bookmark_rounded,
                        accent: AppTheme.warning,
                      ),
                      StatCard(
                        label: 'Out of Stock',
                        value: inventory.outOfStockTitles.toString(),
                        icon: Icons.error_outline_rounded,
                        accent: AppTheme.danger,
                      ),
                      StatCard(
                        label: 'Categories',
                        value: inventory.categories.toString(),
                        icon: Icons.category_outlined,
                        accent: AppTheme.accentDark,
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                _sectionHeader('Popular Books'),
                Card(
                  child: popular.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: EmptyState(
                            icon: Icons.trending_up_rounded,
                            title: 'No borrowing data yet',
                            message: 'Popular titles appear after loans are issued.',
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: popular.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = popular[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primary.withOpacity(0.12),
                                child: Text(
                                  '#${i + 1}',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(p.book.title),
                              subtitle: Text(p.book.author),
                              trailing: Text(
                                '${p.loanCount} loan${p.loanCount == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: AppTheme.accentDark,
                                  fontFamily: 'PT Serif',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 18),
                _sectionHeader('Borrowing Activity'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _range == null
                                    ? 'No range selected'
                                    : '${DateUtilsX.formatShort(_range!.start)} → ${DateUtilsX.formatShort(_range!.end)}',
                                style: const TextStyle(
                                  fontFamily: 'PT Serif',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.date_range_outlined, size: 18),
                              label: const Text('Pick range'),
                              onPressed: _pickRange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _miniStat(
                                'Loans in range',
                                _rangeLoans.length.toString(),
                                AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _miniStat(
                                'Returned',
                                _rangeLoans
                                    .where((l) => l.loan.status == AppConstants.statusReturned)
                                    .length
                                    .toString(),
                                AppTheme.success,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _miniStat(
                                'Overdue',
                                _rangeLoans
                                    .where((l) => l.loan.status == AppConstants.statusOverdue)
                                    .length
                                    .toString(),
                                AppTheme.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.download_outlined, size: 18),
                            label: const Text('Export CSV'),
                            onPressed: _exportCsv,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Row(
          children: [
            Container(width: 3, height: 14, color: AppTheme.accent),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
      );

  Widget _miniStat(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontFamily: 'Playfair Display',
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.slate,
                fontFamily: 'PT Serif',
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
}
