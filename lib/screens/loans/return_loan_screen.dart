import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/loan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../routes/app_routes.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loan_card.dart';
import '../../widgets/loading_overlay.dart' as overlay;

class ReturnLoanScreen extends StatefulWidget {
  const ReturnLoanScreen({super.key});

  @override
  State<ReturnLoanScreen> createState() => _ReturnLoanScreenState();
}

class _ReturnLoanScreenState extends State<ReturnLoanScreen> {
  String _query = '';
  List<LoanDetail> _activeLoans = [];
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loans = context.read<LoanProvider>();
    await loans.reconcileOverdue();
    // Recent loans cover every borrower — we'll filter to active ones.
    final recent = await loans.recentLoans(limit: 500);
    setState(() {
      _activeLoans = recent.where((l) => !l.loan.isReturned).toList();
      _loading = false;
    });
  }

  List<LoanDetail> get _filtered {
    if (_query.trim().isEmpty) return _activeLoans;
    final q = _query.toLowerCase();
    return _activeLoans
        .where((l) =>
            l.bookTitle.toLowerCase().contains(q) ||
            l.bookIsbn.toLowerCase().contains(q) ||
            l.userName.toLowerCase().contains(q) ||
            (l.userStudentId?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<void> _return(LoanDetail l) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Return book',
      message: 'Confirm return of "${l.bookTitle}" borrowed by ${l.userName} '
          '(due ${DateUtilsX.formatDate(l.loan.dueDate)})?',
      confirmLabel: 'Return',
      cancelLabel: 'Cancel',
    );
    if (confirmed != true) return;
    setState(() => _working = true);
    final loans = context.read<LoanProvider>();
    final auth = context.read<AuthProvider>();
    await loans.returnLoan(loanId: l.loan.id!, librarianId: auth.currentUser!.id!);
    setState(() => _working = false);
    if (!mounted) return;
    if (loans.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loans.error!), backgroundColor: AppTheme.danger),
      );
      loans.clearError();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Returned "${l.bookTitle}" successfully.'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: const AppHeaderBar(
        title: 'Return Book',
        subtitle: 'Find active loan and process return',
        showBack: true,
      ),
      body: overlay.LoadingOverlay(
        loading: _working,
        message: 'Processing return…',
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    color: AppTheme.cream,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: TextField(
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Search book, ISBN, student, or student ID',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  Expanded(
                    child: _filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.assignment_return_outlined,
                            title: 'No active loans to return',
                            message: 'All currently-borrowed books have been returned, '
                                'or your search returns no matches.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 60),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) {
                              final l = _filtered[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: LoanCard(
                                  detail: l,
                                  onTap: () =>
                                      Navigator.pushNamed(context, AppRoutes.bookDetail,
                                          arguments: l.loan.bookId),
                                  trailing: ElevatedButton.icon(
                                    onPressed: () => _return(l),
                                    icon: const Icon(Icons.assignment_return_rounded, size: 16),
                                    label: const Text('Return'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
