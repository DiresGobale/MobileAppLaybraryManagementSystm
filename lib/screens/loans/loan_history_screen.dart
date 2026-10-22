import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loan_card.dart';

class LoanHistoryScreen extends StatefulWidget {
  const LoanHistoryScreen({super.key});

  @override
  State<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends State<LoanHistoryScreen> {
  String _filter = AppConstants.statusActive; // active | overdue | returned | all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final loans = context.read<LoanProvider>();
    await loans.reconcileOverdue();
    await loans.loadRecent(limit: 500);
  }

  @override
  Widget build(BuildContext context) {
    final loans = context.watch<LoanProvider>();
    final auth = context.watch<AuthProvider>();

    final now = DateTime.now();
    final filtered = loans.recentLoans.where((l) {
      switch (_filter) {
        case AppConstants.statusActive:
          return !l.loan.isReturned && now.isBefore(l.loan.dueDate);
        case AppConstants.statusOverdue:
          return !l.loan.isReturned && now.isAfter(l.loan.dueDate);
        case AppConstants.statusReturned:
          return l.loan.isReturned;
        case 'all':
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppHeaderBar(
        title: 'Loan History',
        subtitle: '${loans.recentLoans.length} total loan record(s)',
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
          Container(
            color: AppTheme.cream,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Wrap(
              spacing: 8,
              children: [
                _chip('Active', AppConstants.statusActive, AppTheme.primary),
                _chip('Overdue', AppConstants.statusOverdue, AppTheme.danger),
                _chip('Returned', AppConstants.statusReturned, AppTheme.success),
                _chip('All', 'all', AppTheme.slate),
              ],
            ),
          ),
          Expanded(
            child: loans.isLoading && loans.recentLoans.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
                : filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.history_rounded,
                        title: 'No $_filter loans',
                        message: 'Try a different filter or check back after issuing more books.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final l = filtered[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LoanCard(
                              detail: l,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.bookDetail,
                                arguments: l.loan.bookId,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _chip(String label, String key, Color color) {
    final selected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = key),
      selectedColor: color,
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
}
