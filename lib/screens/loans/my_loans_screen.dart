import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loan_card.dart';

class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({super.key});

  @override
  State<MyLoansScreen> createState() => _MyLoansScreenState();
}

class _MyLoansScreenState extends State<MyLoansScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final loans = context.read<LoanProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser!.id!;
    await loans.loadActiveForUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    final loans = context.watch<LoanProvider>();
    final auth = context.watch<AuthProvider>();
    final isStudent = auth.currentUser!.isStudent;
    final active = loans.activeLoans.where((l) => !l.loan.isReturned).toList();
    final overdue = active.where((l) => DateTime.now().isAfter(l.loan.dueDate)).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppHeaderBar(
          title: 'My Loans',
          subtitle: 'Borrowing activity on your account',
          showMenu: true,
        ),
        body: Column(
          children: [
            Material(
              color: AppTheme.primary,
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: AppTheme.accent,
                indicatorWeight: 3,
                tabs: [
                  Tab(icon: Icon(Icons.bookmark_rounded, size: 16), text: 'Active'),
                  Tab(icon: Icon(Icons.history_rounded, size: 16), text: 'History'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _activeView(context, active, overdue),
                  _historyView(context, loans.historyLoans),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(currentIndex: isStudent ? 2 : 2),
      ),
    );
  }

  Widget _activeView(BuildContext context, List active, List overdue) {
    if (active.isEmpty) {
      return const EmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'No active loans',
        message: 'You have no books currently borrowed. Browse the catalog to find something to read.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      children: [
        if (overdue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have ${overdue.length} overdue loan(s). Please return the book(s) at the circulation desk.',
                      style: const TextStyle(
                        color: AppTheme.danger,
                        fontFamily: 'PT Serif',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        for (final l in active)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LoanCard(
              detail: l,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.bookDetail,
                arguments: l.loan.bookId,
              ),
            ),
          ),
      ],
    );
  }

  Widget _historyView(BuildContext context, List history) {
    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No borrowing history yet',
        message: 'Books you have borrowed and returned will appear here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: history.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: LoanCard(
          detail: history[i],
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.bookDetail,
            arguments: history[i].loan.bookId,
          ),
        ),
      ),
    );
  }
}
